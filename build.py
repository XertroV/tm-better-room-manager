#!/usr/bin/env python3
"""Build an Openplanet plugin: static check, stage + hot-reload, or package a release .op.

usage: ./build.py [dev|release|check] [options]        (or: just build | just release | just check)

  dev      (default) openplanet-lsp check with DEV defined, stage src/ + info.toml into
           <plugins-dir>/<slug>/ (name gets " (Dev)", #__DEFINES__ -> defines = ["DEV"]), then
           hot-reload it in the running game: tm-control-mcp first, tm-remote-build as fallback.
  release  assemble the release tree in a temp dir (src/ minus *_Dev.as and *_Test.as, plus
           LICENSE*, README*, info.toml with defines = ["RELEASE"]), openplanet-lsp check that
           tree, then write <slug>-<version>.op in the repo root. Never writes into src/.
  check    openplanet-lsp only, for both the dev and the release shape.

Repo-agnostic: copy this file into any plugin repo with info.toml and src/ at its root. Without a
#__DEFINES__ line in info.toml, the define is merged into [script] defines (created if missing).
Optional per-repo settings live in build.toml next to it:
  [plugin]  slug = "name"           pin the slug; refuse to build if info.toml's name would move it
  [release] exclude = ["glob", ...] more file-name globs to leave out of releases

The slug (staged folder name == in-game plugin ID) comes from the info.toml name exactly as the
old build.sh derived it: drop ( ) , : ; ' " then lowercase and spaces -> dashes ("My Plugin" ->
"my-plugin"). The dev folder has never carried a "(Dev)" suffix; only the staged display name does.

exit codes: 0 ok | 1 build failed (check errors, staging, packaging) | 2 usage |
            3 staged OK, but the game did not load the plugin (or no reload backend answered)

environment:
  PLUGINS_DIR / OPENPLANET_DIR   staging target (default ~/OpenplanetNext/Plugins)
  OPENPLANET_MY_PLUGINS          extra openplanet-lsp dependency dir (default ~/src/openplanet/my-plugins)
  TM_CONTROL_MCP_CALL            tm-control-mcp tools/call.py (default <my-plugins>/tm-control-mcp/tools/call.py)
  TM_CONTROL_MCP_HOST / _PORT    tm-control-mcp socket (default 127.0.0.1:30006)
  TM_REMOTE_BUILD_HOST           RemoteBuild host (default: auto-detected from `ss -ltnH` on :30000)
  TM_OPENPLANET_LOG              Openplanet.log (default <plugins-dir>/../Openplanet.log)
  NO_COLOR                       disable colour (colour is also off when stdout is not a TTY)
"""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile
from dataclasses import dataclass, field
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11: fall back to a regex read of [meta]
    tomllib = None  # type: ignore[assignment]


ROOT = Path(__file__).resolve().parent
SRC = ROOT / "src"
MANIFEST = ROOT / "info.toml"
CONFIG = ROOT / "build.toml"  # optional per-repo settings, applied by load_config()
SLUG_PIN: str | None = None  # build.toml [plugin] slug
RELEASE_EXCLUDE = ("*_Dev.as", "*_Test.as")  # + build.toml [release] exclude; matched against file names under src/
RELEASE_EXTRAS = ("LICENSE*", "README*")  # repo-root files shipped in releases, matched case-insensitively
PROFILE_DEFINE = {"dev": "DEV", "release": "RELEASE"}

HOME = Path.home()
OPENPLANET_DIR = Path(os.environ.get("OPENPLANET_DIR") or HOME / "OpenplanetNext").expanduser()
DEFAULT_PLUGINS_DIR = Path(os.environ.get("PLUGINS_DIR") or OPENPLANET_DIR / "Plugins").expanduser()
MY_PLUGINS = Path(os.environ.get("OPENPLANET_MY_PLUGINS") or HOME / "src/openplanet/my-plugins").expanduser()
MCP_HOST = os.environ.get("TM_CONTROL_MCP_HOST", "127.0.0.1")
MCP_PORT = int(os.environ.get("TM_CONTROL_MCP_PORT", "30006"))
REMOTE_BUILD_PORT = 30000
LSP_TIMEOUT_S = 300
# Openplanet.log; main() points it next to --plugins-dir unless TM_OPENPLANET_LOG is set.
LOG_PATH = Path(os.environ.get("TM_OPENPLANET_LOG") or OPENPLANET_DIR / "Openplanet.log").expanduser()

EXIT_OK, EXIT_FAIL, EXIT_USAGE, EXIT_RELOAD = 0, 1, 2, 3


# --------------------------------------------------------------------------------------- output

class BuildError(Exception):
    """A failure with an actionable hint. `code` becomes the process exit status."""

    def __init__(self, message: str, hint: str | None = None, code: int = EXIT_FAIL) -> None:
        super().__init__(message)
        self.message = message
        self.hint = hint
        self.code = code
        self.reported = False
        self.phase = ""


class UI:
    STYLES = {"bold": "1", "dim": "2", "red": "31", "green": "32", "yellow": "33", "cyan": "36"}

    def __init__(self, verbose: bool = False) -> None:
        self.verbose = verbose
        self.color = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
        try:
            "✓✗⚠→·│".encode(sys.stdout.encoding or "ascii")
            self.sym = {"ok": "✓", "fail": "✗", "warn": "⚠", "arrow": "→", "dot": "·", "bar": "│", "skip": "–"}
        except (UnicodeEncodeError, LookupError):
            self.sym = {"ok": "+", "fail": "x", "warn": "!", "arrow": "->", "dot": "-", "bar": "|", "skip": "-"}
        self.step = 0
        self.steps = 0

    def c(self, text: object, *styles: str) -> str:
        if not self.color or not styles:
            return str(text)
        return f"\033[{';'.join(self.STYLES[s] for s in styles)}m{text}\033[0m"

    def out(self, text: str = "") -> None:
        print(text, flush=True)

    def kv(self, key: str, value: str) -> None:
        self.out(f"  {self.c(f'{key:<8}', 'dim')} {value}")

    def detail(self, text: str) -> None:
        self.out(f"  {self.c(self.sym['dot'], 'dim')} {text}")

    def warn(self, text: str) -> None:
        self.out(f"  {self.c(self.sym['warn'], 'yellow')} {self.c(text, 'yellow')}")

    def error(self, text: str) -> None:
        self.out(f"  {self.c(self.sym['fail'], 'red')} {self.c(text, 'red')}")

    def quote(self, text: str, *styles: str) -> None:
        self.out(f"    {self.c(self.sym['bar'], 'dim')} {self.c(text, *styles)}")

    def phase(self, title: str, subtitle: str = "") -> "Phase":
        return Phase(self, title, subtitle)


class Phase:
    """One numbered step: prints a header, then a result line with its duration."""

    def __init__(self, ui: UI, title: str, subtitle: str) -> None:
        self.ui, self.title, self.subtitle = ui, title, subtitle
        self.status, self.result = "ok", "done"

    def __enter__(self) -> "Phase":
        ui = self.ui
        ui.step += 1
        counter = ui.c(f"[{ui.step}/{ui.steps}]", "bold", "cyan")
        sub = f"  {ui.c(self.subtitle, 'dim')}" if self.subtitle else ""
        ui.out(f"\n{counter} {ui.c(self.title, 'bold')}{sub}")
        self.t0 = time.monotonic()
        return self

    def ok(self, text: str) -> None:
        self.status, self.result = "ok", text

    def warned(self, text: str) -> None:
        self.status, self.result = "warn", text

    def skipped(self, text: str) -> None:
        self.status, self.result = "skip", text

    def __exit__(self, exc_type, exc, tb) -> bool:
        ui = self.ui
        took = ui.c(f"{ui.sym['dot']} {fmt_secs(time.monotonic() - self.t0)}", "dim")
        if exc_type is None:
            sym, style = {"ok": ("ok", "green"), "warn": ("warn", "yellow"), "skip": ("skip", "yellow")}[self.status]
            ui.out(f"  {ui.c(ui.sym[sym] + ' ' + self.result, style)} {took}")
        elif isinstance(exc, BuildError):
            ui.out(f"  {ui.c(ui.sym['fail'] + ' ' + exc.message, 'red', 'bold')} {took}")
            exc.reported = True
            exc.phase = exc.phase or self.title
        return False


def fmt_secs(seconds: float) -> str:
    if seconds < 60:
        return f"{seconds:.2f}s" if seconds < 10 else f"{seconds:.1f}s"
    return f"{int(seconds // 60)}m{int(seconds % 60):02d}s"


def fmt_size(n: int) -> str:
    size = float(n)
    for unit in ("B", "KiB", "MiB", "GiB"):
        if size < 1024 or unit == "GiB":
            return f"{int(size)} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{n} B"


def short(path: Path | str) -> str:
    """Repo-relative when inside the repo, else ~-relative."""
    p = Path(path)
    try:
        return str(p.relative_to(ROOT)) or "."
    except ValueError:
        pass
    try:
        return "~/" + str(p.relative_to(HOME))
    except ValueError:
        return str(p)


def plural(n: int, word: str) -> str:
    return f"{n} {word}" if n == 1 else f"{n} {word}s"


def find_tool(name: str, *fallbacks: Path) -> str | None:
    found = shutil.which(name)
    if found:
        return found
    for candidate in fallbacks:
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


# ------------------------------------------------------------------------------------- manifest

@dataclass
class Manifest:
    name: str
    version: str
    text: str


def read_manifest() -> Manifest:
    try:
        text = MANIFEST.read_bytes().decode("utf-8-sig")
    except (OSError, UnicodeDecodeError) as exc:
        raise BuildError(f"cannot read {short(MANIFEST)}: {exc}")
    if tomllib is not None:
        try:
            meta = tomllib.loads(text)["meta"]
            name, version = str(meta["name"]), str(meta["version"])
        except (tomllib.TOMLDecodeError, KeyError, TypeError) as exc:
            raise BuildError(f"info.toml has no valid [meta] name/version: {exc}")
    else:
        name_m = re.search(r'(?m)^name\s*=\s*"([^"]*)"', text)
        ver_m = re.search(r'(?m)^version\s*=\s*"([^"]*)"', text)
        if not name_m or not ver_m:
            raise BuildError("info.toml must define [meta] name and version")
        name, version = name_m.group(1), ver_m.group(1)
    if not name.strip() or not version.strip():
        raise BuildError("info.toml has an empty name or version")
    return Manifest(name, version, text)


def slugify(name: str) -> str:
    """The old build.sh rule: tr -d "(),:;'\\"" | tr 'A-Z ' 'a-z-'."""
    return name.translate(str.maketrans("", "", "(),:;'\"")).lower().replace(" ", "-")


def checked_slug(manifest: Manifest) -> str:
    slug = slugify(manifest.name)
    if not re.fullmatch(r"[a-z0-9][a-z0-9._+!&-]*", slug):
        raise BuildError(f"info.toml name {manifest.name!r} gives an unsafe folder name {slug!r}")
    if SLUG_PIN is not None and slug != SLUG_PIN:
        raise BuildError(
            f"info.toml name {manifest.name!r} gives slug {slug!r}, expected {SLUG_PIN!r}",
            hint="the slug is the staged folder and the in-game plugin ID; if the rename is intended, "
            f"update [plugin] slug in {CONFIG.name}",
        )
    return slug


def load_config() -> None:
    """Apply the optional build.toml: [plugin] slug pins the slug, [release] exclude adds globs."""
    global SLUG_PIN, RELEASE_EXCLUDE
    if not CONFIG.is_file():
        return
    if tomllib is None:
        raise BuildError(f"{short(CONFIG)} needs Python 3.11+ (tomllib) to read")
    try:
        data = tomllib.loads(CONFIG.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
        raise BuildError(f"cannot read {short(CONFIG)}: {exc}")
    plugin, release = data.get("plugin", {}), data.get("release", {})
    known = set(data) <= {"plugin", "release"} and isinstance(plugin, dict) and isinstance(release, dict)
    if not known or set(plugin) - {"slug"} or set(release) - {"exclude"}:
        raise BuildError(f"{short(CONFIG)} has unknown settings",
                         hint='supported: [plugin] slug = "..." and [release] exclude = ["glob", ...]')
    slug, exclude = plugin.get("slug"), release.get("exclude", [])
    if slug is not None and not isinstance(slug, str):
        raise BuildError(f"{short(CONFIG)}: [plugin] slug must be a string")
    if not isinstance(exclude, list) or not all(isinstance(p, str) and p for p in exclude):
        raise BuildError(f"{short(CONFIG)}: [release] exclude must be a list of file-name globs")
    SLUG_PIN = slug
    RELEASE_EXCLUDE = (*RELEASE_EXCLUDE, *exclude)


def add_define(text: str, define: str) -> str:
    """For an info.toml without #__DEFINES__: merge the define into [script] defines, creating either."""
    nl = "\r\n" if "\r\n" in text else "\n"
    section = re.search(r"(?ms)^\[script\][ \t]*(?:#[^\r\n]*)?(?=\r?$)(.*?)(?=^\[|\Z)", text)
    if section is None:
        return text.rstrip() + f'{nl}{nl}[script]{nl}defines = ["{define}"]{nl}'
    start, end = section.span(1)
    body = text[start:end]
    m = re.search(r"(?m)^([ \t]*defines[ \t]*=[ \t]*\[)([^\]\r\n#]*)\]", body)
    if m:
        items = m.group(2).strip().rstrip(",").strip()
        body = body[:m.start()] + f'{m.group(1)}{items + ", " if items else ""}"{define}"]' + body[m.end():]
    elif re.search(r"(?m)^[ \t]*defines[ \t]*=", body):
        raise BuildError("info.toml [script] defines must be a one-line array for build.py to extend",
                         hint="or put a `#__DEFINES__` line under [script] instead")
    else:
        body = f'{nl}defines = ["{define}"]' + body
    return text[:start] + body + text[end:]


def render_manifest(text: str, profile: str) -> str:
    """info.toml for a profile: #__DEFINES__ (or [script] defines) gets the profile define; dev also
    appends " (Dev)" to the name."""
    define = PROFILE_DEFINE[profile]
    out, count = re.subn(r"(?m)^#__DEFINES__[ \t]*(?=\r?$)", f'defines = ["{define}"]', text)
    if count > 1:
        raise BuildError(f"info.toml has {count} `#__DEFINES__` lines; expected at most one")
    if count == 0:
        out = add_define(text, define)
    if profile == "dev":
        out, count = re.subn(r'(?m)^(name\s*=\s*")([^"]*)(")', r"\1\2 (Dev)\3", out, count=1)
        if count != 1:
            raise BuildError('could not add " (Dev)" to the info.toml name')
    if tomllib is not None:  # the rendered manifest must still parse and say what we meant
        try:
            data = tomllib.loads(out)
        except tomllib.TOMLDecodeError as exc:
            raise BuildError(f"rendered {profile} info.toml does not parse: {exc}")
        defines = data.get("script", {}).get("defines")
        if not isinstance(defines, list) or define not in defines:
            raise BuildError(f'rendered {profile} info.toml lacks "{define}" in [script] defines')
    return out


# ---------------------------------------------------------------------------------- source tree

@dataclass
class SourceSet:
    files: list[str]  # posix paths relative to src/
    excluded: list[str] = field(default_factory=list)
    size: int = 0


def collect_sources(exclude: tuple[str, ...] = ()) -> SourceSet:
    if not SRC.is_dir():
        raise BuildError(f"source dir missing: {short(SRC)}")
    if (SRC / "info.toml").exists():
        raise BuildError(
            "src/info.toml exists (probably left behind by an interrupted old build.sh release)",
            hint="delete src/info.toml; the manifest lives in the repo root",
        )
    result = SourceSet(files=[])
    for dirpath, dirnames, filenames in os.walk(SRC, followlinks=True):  # cp -L semantics, like build.sh
        dirnames.sort()
        for name in sorted(filenames):
            path = Path(dirpath) / name
            rel = path.relative_to(SRC).as_posix()
            if any(fnmatch.fnmatchcase(name, pattern) for pattern in exclude):
                result.excluded.append(rel)
                continue
            result.files.append(rel)
            result.size += path.stat().st_size
    if not any(f.endswith(".as") for f in result.files):
        raise BuildError("no .as files found under src/")
    return result


def copy_sources(sources: SourceSet, dest: Path, ui: UI) -> None:
    for rel in sources.files:
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SRC / rel, target)
        if ui.verbose:
            ui.quote(f"src/{rel}", "dim")


def tree_files(root: Path) -> list[str]:
    return sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())


def git(*args: str) -> str | None:
    try:
        proc = subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True, text=True,
                              stdin=subprocess.DEVNULL, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return proc.stdout if proc.returncode == 0 else None


# ------------------------------------------------------------------------------------------ lsp

@dataclass
class LspResult:
    errors: int = 0
    warnings: int = 0
    hidden: int = 0
    skipped: str | None = None

    def summary(self) -> str:
        if self.skipped:
            return f"skipped ({self.skipped})"
        text = f"{plural(self.errors, 'error')}, {plural(self.warnings, 'warning')}"
        return text + (f" ({self.hidden} info hidden)" if self.hidden else "")


def run_lsp(ui: UI, tree: Path, plugins_dir: Path, *, defines: tuple[str, ...] = (),
            release_tree: bool = False, required: bool = False) -> LspResult:
    lsp = find_tool("openplanet-lsp", HOME / ".local/bin/openplanet-lsp", HOME / ".cargo/bin/openplanet-lsp")
    if not lsp:
        if required:
            raise BuildError("openplanet-lsp is not installed", hint="install it (see ~/src/lsp-openplanet) or put it on PATH")
        ui.warn("openplanet-lsp not found on PATH; static check skipped")
        return LspResult(skipped="openplanet-lsp not installed")

    cmd = [lsp, "check", "--format", "json"]
    for dep_dir in (plugins_dir, MY_PLUGINS):
        if dep_dir.is_dir():
            cmd += ["--plugins-dir", str(dep_dir)]
    for define in defines:
        cmd += ["--define", define]
    cmd.append(str(tree))
    if ui.verbose:
        ui.detail("$ " + shlex.join(cmd))
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=LSP_TIMEOUT_S)
    except subprocess.TimeoutExpired:
        raise BuildError(f"openplanet-lsp timed out after {LSP_TIMEOUT_S}s")
    except OSError as exc:
        raise BuildError(f"cannot run openplanet-lsp: {exc}")
    try:
        report = json.loads(proc.stdout)
        diagnostics = list(report.get("diagnostics") or [])
    except (json.JSONDecodeError, AttributeError):
        for line in (proc.stderr or proc.stdout).strip().splitlines()[-20:]:
            ui.quote(line)
        raise BuildError(f"openplanet-lsp exited {proc.returncode} without a JSON report",
                         hint="run `openplanet-lsp check .` by hand to see what went wrong")

    def display(path: str) -> str:
        if release_tree and not Path(path).is_absolute() and path != "info.toml":
            return f"src/{path}"  # map the temp release tree back to the repo layout
        return short(path) if Path(path).is_absolute() else path

    result = LspResult()
    shown = []
    for d in diagnostics:
        severity = str(d.get("severity", "")).lower()
        if severity == "error":
            result.errors += 1
            shown.append(d)
        elif severity == "warning":
            result.warnings += 1
            shown.append(d)
        else:
            result.hidden += 1
    # Like openplanet-lsp's own default: warnings first, errors last (closest to the prompt).
    shown.sort(key=lambda d: (d.get("severity") == "error", str(d.get("path")), int(d.get("line") or 0)))
    for d in shown:
        where = f"{display(str(d.get('path')))}:{d.get('line')}:{d.get('col')}"
        if d.get("severity") == "error":
            ui.out(f"  {ui.c(ui.sym['fail'], 'red')} {ui.c(where, 'bold')}  {ui.c(d.get('message'), 'red')}")
            print_excerpt(ui, tree, str(d.get("path")), int(d.get("line") or 0), int(d.get("col") or 0))
        else:
            ui.out(f"  {ui.c(ui.sym['warn'], 'yellow')} {where}  {ui.c(d.get('message'), 'yellow')}")
    typedb = report.get("typedb") or {}
    if typedb.get("op"):
        ui.detail(ui.c(f"typedb: Openplanet {typedb.get('op')}", "dim"))
    if not report.get("type_database_loaded", True):
        ui.warn("openplanet-lsp ran without the Openplanet type database; game API calls were not checked")

    if result.errors:
        raise BuildError(
            f"openplanet-lsp: {plural(result.errors, 'error')}",
            hint="fix the errors above, or use --skip-lsp if openplanet-lsp is wrong "
            "(and log the false positive at https://github.com/clankercode/lsp-openplanet/issues)",
        )
    if proc.returncode != 0:
        for line in proc.stderr.strip().splitlines()[-10:]:
            ui.quote(line)
        raise BuildError(f"openplanet-lsp exited {proc.returncode} without reporting errors")
    return result


def print_excerpt(ui: UI, tree: Path, rel: str, line: int, col: int) -> None:
    try:
        source = (tree / rel).read_text(encoding="utf-8", errors="replace").splitlines()[line - 1]
    except (OSError, IndexError):
        return
    # Keep tabs so the caret lines up with tab-indented source.
    pad = "".join(ch if ch == "\t" else " " for ch in source[: max(col - 1, 0)])
    ui.quote(source.rstrip())
    ui.quote(pad + ui.c("^", "red", "bold"))


# ------------------------------------------------------------------------------------- staging

def guard_stage_dest(dest: Path, plugins_dir: Path, slug: str) -> Path:
    """Return the resolved staging folder, or refuse if it is anything but <plugins-dir>/<slug>."""
    root = plugins_dir.resolve()
    home = HOME.resolve()
    if root in (Path("/"), home, home.parent) or len(root.parts) < 4:
        raise BuildError(f"refusing to stage into {root}: not a plausible Openplanet Plugins dir",
                         hint="set --plugins-dir / PLUGINS_DIR to your OpenplanetNext/Plugins folder")
    if dest.is_symlink():
        raise BuildError(f"refusing to replace {short(dest)}: it is a symlink", hint="remove the symlink yourself if it is stale")
    target = dest.resolve()
    if target.parent != root or target.name != slug or target in (root, home, Path("/")) or len(target.parts) < 5:
        raise BuildError(f"refusing to clear {target}: it is not exactly <plugins-dir>/{slug}")
    if target.exists() and not target.is_dir():
        raise BuildError(f"{short(target)} exists and is not a directory", hint="move it aside, then re-run")
    if target.is_dir() and any(target.iterdir()):
        if (target / ".git").exists():
            raise BuildError(f"{short(target)} contains .git, so it looks like a source checkout, not a staged build",
                             hint="move it aside; this script only replaces folders it staged itself")
        if not (target / "info.toml").is_file():
            raise BuildError(f"{short(target)} has no info.toml, so it does not look like a staged build",
                             hint="move it aside or delete it yourself, then re-run")
        # Our stages are always named "<name> (Dev)"; anything else may be another plugin or an installed copy.
        staged = re.search(r'(?m)^name\s*=\s*"([^"]*) \(Dev\)"', (target / "info.toml").read_text("utf-8", "replace"))
        if not staged or slugify(staged.group(1)) != slug:
            raise BuildError(f'{short(target)} is not a dev stage of this plugin (its info.toml name is not "<name> (Dev)")',
                             hint="it may be another plugin or an installed copy; move it aside, then re-run")
    return target


def stage_dev(ui: UI, phase: Phase, manifest: Manifest, slug: str, plugins_dir: Path) -> Path:
    if not plugins_dir.is_dir():
        raise BuildError(f"plugins dir not found: {plugins_dir}",
                         hint="pass --plugins-dir or set PLUGINS_DIR to your OpenplanetNext/Plugins folder")
    dest = guard_stage_dest(plugins_dir / slug, plugins_dir, slug)
    rendered = render_manifest(manifest.text, "dev")
    sources = collect_sources()

    if dest.exists():
        old = sum(1 for p in dest.rglob("*") if p.is_file())
        shutil.rmtree(dest)
        ui.detail(f"cleared previous stage ({plural(old, 'file')})")
    dest.mkdir()
    # info.toml first: an interrupted stage still looks like ours to guard_stage_dest next time.
    (dest / "info.toml").write_bytes(rendered.encode("utf-8"))
    copy_sources(sources, dest, ui)

    expected = sorted([*sources.files, "info.toml"])
    staged = tree_files(dest)
    if staged != expected:
        missing, extra = sorted(set(expected) - set(staged)), sorted(set(staged) - set(expected))
        raise BuildError(f"staged file set mismatch (missing {missing[:5]}, unexpected {extra[:5]})")
    ui.detail(f"copied {plural(len(sources.files), 'file')} from src/ ({fmt_size(sources.size)})")
    ui.detail(f'info.toml: name "{manifest.name} (Dev)", DEV defined')
    phase.ok(f"staged {plural(len(staged), 'file')} into {short(plugins_dir / slug)}")
    return dest


# ------------------------------------------------------------------------------------- reload

LOG_LINE_RE = re.compile(
    r"^\[\s*(?P<source>[^\]]*?)\s*\]\s*\[\s*(?P<level>[^\]]*?)\s*\]\s*\[(?P<time>[^\]]*)\]"
    r"(?:\s\[(?P<ctx>[^\]]*)\])?\s\s(?P<msg>.*)$"
)
COMPILE_MSG_RE = re.compile(r"^(?P<path>.+?\.as) \((?P<line>\d+), (?P<col>\d+)\) : (?P<kind>[A-Z]+) : (?P<text>.*)$")


@dataclass
class LogEntry:
    source: str
    level: str
    ctx: str
    msg: str


@dataclass
class LoadReport:
    entries: list[LogEntry] = field(default_factory=list)
    errors: int = 0
    warnings: int = 0
    loaded: bool = False
    missing_deps: list[str] = field(default_factory=list)


def analyse_log(lines: list[str], slug: str) -> LoadReport:
    """Pick this plugin's load/compile lines out of an Openplanet.log slice and classify them."""
    report = LoadReport()
    mention = re.compile(rf"""["']{re.escape(slug)}["']|/Plugins/{re.escape(slug)}/""", re.I)
    start = re.compile(rf"""Starting build for ["']{re.escape(slug)}["']""", re.I)
    in_build = False
    for raw in lines:
        m = LOG_LINE_RE.match(raw.rstrip("\r"))
        if not m:
            continue
        e = LogEntry(m["source"], m["level"].upper(), m["ctx"] or "", m["msg"])
        if e.source == "ScriptEngine":
            if start.search(e.msg):
                in_build = True
            elif "Starting build for " in e.msg:
                in_build = False
            if not (in_build or mention.search(e.msg)):
                continue
            if e.level == "TRAC" and e.msg.lstrip().startswith("--"):
                continue  # "-- Add source: ..." noise
        elif not (e.source == "ScriptRuntime" and e.ctx.lower() == slug and e.level in ("ERROR", "WARN")):
            continue
        report.entries.append(e)
        if e.level == "ERROR" or ": ERR :" in e.msg:
            report.errors += 1
            if "dependency" in e.msg.lower() and "optional" not in e.msg.lower():
                report.missing_deps += re.findall(r'"([^"]+)"', e.msg)[:1]
        elif e.level == "WARN" or ": WARN :" in e.msg:
            report.warnings += 1
        if re.search(rf"""Loaded (?:zipped |legacy )?plugin ['"]{re.escape(slug)}['"]""", e.msg, re.I):
            report.loaded = True
            in_build = False
    return report


def print_load_report(ui: UI, report: LoadReport, slug: str) -> None:
    staged_path = re.compile(rf"[A-Za-z]:[/\\][^\s\"']*?[/\\]Plugins[/\\]{re.escape(slug)}[/\\]", re.I)
    for e in report.entries:
        msg = staged_path.sub("src/", e.msg)
        cm = COMPILE_MSG_RE.match(msg)
        if cm:  # "src/X.as (12, 5) : ERR : text" -> clickable "src/X.as:12:5  text"
            msg = f"{cm['path']}:{cm['line']}:{cm['col']}  {cm['text']}"
            is_err, is_warn = cm["kind"] == "ERR", cm["kind"] == "WARN"
        else:
            is_err, is_warn = e.level == "ERROR", e.level == "WARN"
        tag = f"[{e.source} {e.level}]"
        if is_err:
            ui.quote(f"{tag} {msg}", "red")
        elif is_warn:
            ui.quote(f"{tag} {msg}", "yellow")
        else:
            ui.quote(f"{tag} {msg}", "dim")
    if not report.entries:
        ui.quote("(no load/compile lines for this plugin in Openplanet.log)", "dim")


class OpenplanetLog:
    def __init__(self, path: Path) -> None:
        self.path = path

    def mark(self) -> int | None:
        try:
            return self.path.stat().st_size
        except OSError:
            return None

    def read_since(self, offset: int | None) -> list[str] | None:
        if offset is None:
            return None
        try:
            with self.path.open("rb") as f:
                if os.fstat(f.fileno()).st_size < offset:
                    offset = 0  # log was recreated (game restart)
                f.seek(offset)
                data = f.read()
        except OSError:
            return None
        return data.decode("utf-8", errors="replace").splitlines()

    def wait_for_load(self, offset: int | None, slug: str, timeout: float = 4.0, settle: float = 0.4) -> list[str] | None:
        """Poll until this plugin's load finished (loaded or errored), then let the log settle briefly."""
        deadline = time.monotonic() + timeout
        while True:
            lines = self.read_since(offset)
            if lines is None:
                return None
            report = analyse_log(lines, slug)
            if report.loaded or report.errors or time.monotonic() >= deadline:
                time.sleep(settle)
                return self.read_since(offset)
            time.sleep(0.15)


def trackmania_running() -> bool | None:
    proc = Path("/proc")
    if not proc.is_dir():
        return None  # not Linux: cannot tell, try the backends anyway
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            argv0 = (entry / "cmdline").read_bytes().split(b"\0", 1)[0].decode(errors="ignore")
        except OSError:
            continue
        exe = argv0.replace("\\", "/").lower()
        if exe == "trackmania.exe" or exe.endswith("/trackmania.exe"):
            return True
    return False


@dataclass
class ReloadOutcome:
    backend: str
    ok: bool
    message: str
    hint: str | None = None
    skipped: bool = False


def outcome_from_report(backend: str, report: LoadReport, slug: str, *, backend_ok: bool,
                        backend_error: str = "", log_available: bool = True) -> ReloadOutcome:
    if backend_ok and not report.errors and (report.loaded or not log_available):
        note = "" if report.loaded else " (not confirmed: Openplanet.log unreadable)"
        warn = f", {plural(report.warnings, 'warning')}" if report.warnings else ""
        return ReloadOutcome(backend, True, f"loaded {slug} via {backend}{warn}{note}")
    if report.missing_deps:
        deps = ", ".join(dict.fromkeys(report.missing_deps))
        # Openplanet aborts the build (no sources compiled) yet may still log "Loaded plugin".
        return ReloadOutcome(backend, False, f"Openplanet could not build {slug}: required dependency {deps} is missing",
                             hint=f"install {deps} in the game (Openplanet Plugin Manager), then re-run `just build`")
    if report.errors:
        return ReloadOutcome(backend, False, f"game failed to compile/load {slug}: {plural(report.errors, 'error')}",
                             hint="fix the errors above (paths are repo-relative). If openplanet-lsp should have caught "
                             "them, add a case to ~/src/lsp-openplanet/todo-cover-cases-next.txt")
    why = backend_error or "no 'Loaded plugin' line appeared in Openplanet.log"
    return ReloadOutcome(backend, False, f"{backend} did not confirm a load of {slug}: {why}",
                         hint=f"check {short(LOG_PATH)}, or load it by hand: Openplanet > Developer > Load plugin")


def find_mcp_call() -> Path | None:
    candidates = [os.environ.get("TM_CONTROL_MCP_CALL"), MY_PLUGINS / "tm-control-mcp/tools/call.py",
                  ROOT.parent / "tm-control-mcp/tools/call.py"]
    for candidate in candidates:
        if candidate and Path(candidate).expanduser().is_file():
            return Path(candidate).expanduser()
    return None


def mcp_call(ui: UI, call_py: Path, tool: str, payload: dict | None = None,
             timeout: float = 5.0) -> tuple[int, dict | None, str]:
    cmd = [sys.executable, str(call_py), "--host", MCP_HOST, "--port", str(MCP_PORT), "--timeout", str(timeout), tool]
    if payload is not None:
        cmd.append(json.dumps(payload, separators=(",", ":")))
    if ui.verbose:
        ui.detail("$ " + shlex.join(cmd))
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=timeout + 30)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, None, str(exc)
    try:
        data = json.loads(proc.stdout.strip() or "null")
    except json.JSONDecodeError:
        data = None
    if ui.verbose and proc.stdout.strip():
        ui.quote(proc.stdout.strip()[:2000], "dim")
    return proc.returncode, data if isinstance(data, dict) else None, proc.stderr.strip()


def reload_via_mcp(ui: UI, slug: str, log: OpenplanetLog) -> ReloadOutcome | None:
    """None means tm-control-mcp is unavailable (caller may fall back)."""
    call_py = find_mcp_call()
    if not call_py:
        ui.detail("tm-control-mcp: tools/call.py not found (set TM_CONTROL_MCP_CALL)")
        return None
    rc, status, err = mcp_call(ui, call_py, "status", timeout=3.0)
    if rc != 0 or not status or not status.get("ok"):
        why = (status or {}).get("error") or err or f"exit {rc}"
        ui.detail(f"tm-control-mcp unavailable: {why}")
        return None
    version = (status.get("data") or {}).get("version", "?")
    ui.detail(f'tm-control-mcp v{version} at {MCP_HOST}:{MCP_PORT} {ui.sym["arrow"]} ControlPlugin load "{slug}"')

    mark = log.mark()
    rc, resp, err = mcp_call(ui, call_py, "ControlPlugin", {"action": "load", "id": slug}, timeout=60.0)
    if resp is None or (rc != 0 and not resp.get("ok", False)):
        why = (resp or {}).get("error") or err or f"exit {rc}"
        ui.warn(f"tm-control-mcp load call failed: {why}")
        return None
    result = ((resp.get("data") or {}).get("result")) or {}
    success = bool(resp.get("ok")) and bool(result.get("success"))
    backend_error = ""
    if not success:
        backend_error = str(result.get("error") or resp.get("error") or "unknown error")
        code = result.get("code")
        ui.detail(f"tm-control-mcp: {backend_error}" + (f" [{code}]" if code else ""))

    lines = log.wait_for_load(mark, slug)
    log_available = lines is not None
    if lines is None:  # fall back to the compile lines tm-control-mcp collected
        compile_blob = ((result.get("output") or {}).get("compile")) or {}
        lines = [str(x) for x in compile_blob.get("lines") or []]
    report = analyse_log(lines, slug)
    print_load_report(ui, report, slug)
    return outcome_from_report("tm-control-mcp", report, slug, backend_ok=success,
                               backend_error=backend_error, log_available=log_available)


def remote_build_listener() -> tuple[bool | None, str | None]:
    """(is anything listening on :30000, host to pass). Same detection as tm-control-mcp's build.sh."""
    configured = os.environ.get("TM_REMOTE_BUILD_HOST")
    if configured:
        return True, configured
    try:
        out = subprocess.run(["ss", "-ltnH"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None, None
    for line in out.splitlines():
        fields = line.split()
        if len(fields) >= 4 and fields[3].endswith(f":{REMOTE_BUILD_PORT}"):
            host = fields[3].rsplit(":", 1)[0]
            return True, (None if host in ("0.0.0.0", "*", "[::]") else host.strip("[]"))
    return False, None


def reload_via_remote_build(ui: UI, slug: str, plugins_dir: Path, log: OpenplanetLog) -> ReloadOutcome | None:
    exe = find_tool("tm-remote-build", HOME / ".local/bin/tm-remote-build")
    if not exe:
        ui.detail("tm-remote-build not installed")
        return None
    listening, host = remote_build_listener()
    if listening is False:
        ui.detail(f"RemoteBuild is not listening on :{REMOTE_BUILD_PORT} (is the RemoteBuild plugin loaded?)")
        return None
    cmd = [exe, "load", "folder", slug, "-op", "OpenplanetNext", "-d", str(plugins_dir.parent), "-l", "3", "-i", "0.5"]
    if host:
        cmd += ["--host", host]
    if ui.verbose:
        cmd.append("-v")
    ui.detail(f"tm-remote-build {ui.sym['arrow']} load folder \"{slug}\" ({host or '127.0.0.1'}:{REMOTE_BUILD_PORT})")
    if ui.verbose:
        ui.detail("$ " + shlex.join(cmd))
    mark = log.mark()
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=120)
    except (OSError, subprocess.TimeoutExpired) as exc:
        ui.warn(f"tm-remote-build failed to run: {exc}")
        return None
    if ui.verbose:
        for line in (proc.stdout + proc.stderr).strip().splitlines():
            ui.quote(line, "dim")
    # tm-remote-build always exits 0; failures are logged as ERROR lines on stderr.
    problems = [ln.split(":", 2)[-1].strip() for ln in proc.stderr.splitlines() if ln.startswith("ERROR:")]
    lines = log.wait_for_load(mark, slug, timeout=2.0)
    report = analyse_log(lines or [], slug)
    if not report.entries and len(problems) == 1 and "Problem commanding load" in problems[0]:
        ui.detail("RemoteBuild did not answer")  # tm-remote-build could not reach the game at all
        return None
    print_load_report(ui, report, slug)
    for p in problems:
        if "Problem commanding load" not in p:
            ui.quote(f"[tm-remote-build] {p}", "red")
    return outcome_from_report("tm-remote-build", report, slug, backend_ok=not problems,
                               backend_error="; ".join(problems), log_available=lines is not None)


def reload_plugin(ui: UI, slug: str, plugins_dir: Path, backend: str) -> ReloadOutcome:
    running = trackmania_running()
    if running is False:
        return ReloadOutcome("none", True, "Trackmania is not running; reload skipped (it loads on next game start)",
                             skipped=True)
    log = OpenplanetLog(LOG_PATH)
    if backend in ("auto", "mcp"):
        outcome = reload_via_mcp(ui, slug, log)
        if outcome:
            return outcome
        if backend == "mcp":
            return ReloadOutcome("tm-control-mcp", False, "tm-control-mcp is unavailable",
                                 hint="load the tm-control-mcp plugin in Openplanet, or use --reload auto/remote")
        ui.detail("falling back to tm-remote-build")
    outcome = reload_via_remote_build(ui, slug, plugins_dir, log)
    if outcome:
        return outcome
    tried = "tm-control-mcp, then RemoteBuild" if backend == "auto" else "RemoteBuild"
    return ReloadOutcome("none", False, f"no reload backend answered (tried {tried})",
                         hint=f"load tm-control-mcp or RemoteBuild in Openplanet, or load {slug} by hand: "
                         "Openplanet > Developer > Load plugin")


# -------------------------------------------------------------------------------------- release

@dataclass
class ReleaseTree:
    sources: SourceSet
    extras: list[str]
    files: int
    size: int


def assemble_release_tree(ui: UI, manifest: Manifest, dest: Path) -> ReleaseTree:
    rendered = render_manifest(manifest.text, "release")
    sources = collect_sources(RELEASE_EXCLUDE)
    copy_sources(sources, dest, ui)
    extras = []
    for pattern in RELEASE_EXTRAS:
        found = sorted(p.name for p in ROOT.iterdir() if p.is_file() and fnmatch.fnmatch(p.name.lower(), pattern.lower()))
        if not found:
            ui.warn(f"no {pattern} file in the repo root; not included")
        for name in found:
            if (SRC / name).exists():
                raise BuildError(f"src/{name} would collide with the repo-root {name} in the archive")
            shutil.copy2(ROOT / name, dest / name)
            extras.append(name)
    (dest / "info.toml").write_bytes(rendered.encode("utf-8"))
    size = sum((dest / f).stat().st_size for f in tree_files(dest))
    return ReleaseTree(sources, extras, len(tree_files(dest)), size)


def report_release_tree(ui: UI, tree: ReleaseTree) -> None:
    ui.detail(f"{plural(len(tree.sources.files), 'file')} from src/ ({fmt_size(tree.sources.size)}) "
              f"+ {', '.join([*tree.extras, 'info.toml'])}")
    ui.detail("info.toml: RELEASE defined")
    if tree.sources.excluded:
        ui.detail(f"excluded {plural(len(tree.sources.excluded), 'file')} ({' / '.join(RELEASE_EXCLUDE)}):")
        for rel in tree.sources.excluded:
            ui.quote(f"src/{rel}", "dim")
    else:
        ui.detail(f"excluded nothing (no {' / '.join(RELEASE_EXCLUDE)} files)")
    shipped = {f"src/{rel}" for rel in tree.sources.files}
    names = [n for n in (git("ls-files", "--others", "--", "src") or "").splitlines() if n in shipped]
    if names:
        ui.warn(f"{plural(len(names), 'file')} under src/ not tracked by git will ship:")
        for name in names[:10]:
            ui.quote(name, "yellow")


def write_op(tree_dir: Path, out: Path) -> tuple[int, str]:
    """Zip tree_dir (directory entries + files, sorted) to out atomically; return (entries, sha256)."""
    part = out.with_name(out.name + ".part")
    try:
        with zipfile.ZipFile(part, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for dirpath, dirnames, filenames in os.walk(tree_dir):
                dirnames.sort()
                base = Path(dirpath)
                if base != tree_dir:
                    zf.write(base, base.relative_to(tree_dir).as_posix())  # dir entry, like 7z/zip make
                for name in sorted(filenames):
                    zf.write(base / name, (base / name).relative_to(tree_dir).as_posix())
        with zipfile.ZipFile(part) as zf:  # read back: CRCs and the manifest we meant to ship
            bad = zf.testzip()
            if bad:
                raise BuildError(f"archive self-check failed: corrupt member {bad}")
            if not re.search(r'(?m)^[ \t]*defines[ \t]*=[ \t]*\[[^\]\r\n]*"RELEASE"', zf.read("info.toml").decode("utf-8")):
                raise BuildError('archive self-check failed: info.toml lacks "RELEASE" in defines')
            entries = len(zf.namelist())
        os.replace(part, out)
    except OSError as exc:
        raise BuildError(f"could not write {short(out)}: {exc}")
    finally:
        part.unlink(missing_ok=True)
    return entries, hashlib.sha256(out.read_bytes()).hexdigest()


# ------------------------------------------------------------------------------------- commands

def header(ui: UI, manifest: Manifest, slug: str, title: str) -> None:
    ui.out(f"{ui.c(manifest.name, 'bold')} {ui.c('v' + manifest.version, 'cyan')} {ui.c(ui.sym['dot'], 'dim')} {title}")
    ui.kv("repo", "~/" + str(ROOT.relative_to(HOME)) if ROOT.is_relative_to(HOME) else str(ROOT))
    ui.kv("slug", slug)


def cmd_dev(ui: UI, args: argparse.Namespace, manifest: Manifest, slug: str, plugins_dir: Path) -> list[str]:
    ui.steps = 3
    header(ui, manifest, slug, "dev build")
    ui.kv("target", short(plugins_dir / slug))
    with ui.phase("Static check", "openplanet-lsp, -D DEV") as ph:
        if args.skip_lsp:
            lsp = LspResult(skipped="--skip-lsp")
        else:
            lsp = run_lsp(ui, ROOT, plugins_dir, defines=("DEV",))
        (ph.skipped if lsp.skipped else ph.ok)(lsp.summary())
    with ui.phase("Stage", short(plugins_dir / slug)) as ph:
        stage_dev(ui, ph, manifest, slug, plugins_dir)
    with ui.phase("Hot reload", {"auto": "tm-control-mcp, fallback tm-remote-build", "mcp": "tm-control-mcp",
                                 "remote": "tm-remote-build", "none": "disabled"}[args.reload]) as ph:
        if args.reload == "none":
            ph.skipped("skipped (--reload none)")
            reload = ReloadOutcome("none", True, "skipped", skipped=True)
        else:
            reload = reload_plugin(ui, slug, plugins_dir, args.reload)
            if not reload.ok:
                raise BuildError(reload.message, hint=reload.hint, code=EXIT_RELOAD)
            (ph.skipped if reload.skipped else ph.ok)(reload.message)
    parts = [f"staged {short(plugins_dir / slug)}"]
    if reload.skipped:
        parts.append("not reloaded")
    else:
        parts.append(f"reloaded via {reload.backend}")
    parts.append(lsp.summary() if not lsp.skipped else "lsp skipped")
    return parts


def cmd_release(ui: UI, args: argparse.Namespace, manifest: Manifest, slug: str, plugins_dir: Path) -> list[str]:
    ui.steps = 3
    header(ui, manifest, slug, "release build")
    head = (git("rev-parse", "--short", "HEAD") or "").strip()
    if head:
        dirty = [ln for ln in (git("status", "--porcelain") or "").splitlines() if ln.strip()]
        ui.kv("git", head + (f" + {plural(len(dirty), 'uncommitted change')}" if dirty else " (clean)"))
    out = ROOT / f"{slug}-{manifest.version}.op"
    ui.kv("output", short(out))
    with tempfile.TemporaryDirectory(prefix=f"{slug}-release-") as tmp:
        tree_dir = Path(tmp)
        with ui.phase("Assemble release tree", "temp dir; src/ is not modified") as ph:
            tree = assemble_release_tree(ui, manifest, tree_dir)
            report_release_tree(ui, tree)
            ph.ok(f"{plural(tree.files, 'file')}, {fmt_size(tree.size)}")
        with ui.phase("Static check", "openplanet-lsp on the release tree") as ph:
            if args.skip_lsp:
                lsp = LspResult(skipped="--skip-lsp")
            else:
                lsp = run_lsp(ui, tree_dir, plugins_dir, release_tree=True)
            (ph.skipped if lsp.skipped else ph.ok)(lsp.summary())
        with ui.phase("Package", short(out)) as ph:
            entries, digest = write_op(tree_dir, out)
            size = out.stat().st_size
            ui.detail(f"{entries} zip entries, {fmt_size(tree.size)} {ui.sym['arrow']} {fmt_size(size)} deflated")
            ui.detail(f"sha256 {digest}")
            ph.ok(f"wrote {short(out)} ({fmt_size(size)})")
    return [short(out), plural(tree.files, "file"), fmt_size(size), f"sha256 {digest[:12]}",
            lsp.summary() if not lsp.skipped else "lsp skipped"]


def cmd_check(ui: UI, args: argparse.Namespace, manifest: Manifest, slug: str, plugins_dir: Path) -> list[str]:
    ui.steps = 2
    header(ui, manifest, slug, "static check")
    with ui.phase("Dev shape", "source tree, -D DEV") as ph:
        dev = run_lsp(ui, ROOT, plugins_dir, defines=("DEV",), required=True)
        ph.ok(dev.summary())
    with tempfile.TemporaryDirectory(prefix=f"{slug}-check-") as tmp:
        with ui.phase("Release shape", f"temp tree without {' / '.join(RELEASE_EXCLUDE)}, RELEASE") as ph:
            tree = assemble_release_tree(ui, manifest, Path(tmp))
            if tree.sources.excluded:
                ui.detail(f"excluded: {', '.join('src/' + r for r in tree.sources.excluded)}")
            rel = run_lsp(ui, Path(tmp), plugins_dir, release_tree=True, required=True)
            ph.ok(rel.summary())
    return [f"dev: {dev.summary()}", f"release: {rel.summary()}"]


def parse_args(argv: list[str] | None) -> argparse.Namespace:
    title, _usage, body = __doc__.split("\n\n", 2)
    description, epilog = body.split("\nexit codes:", 1)
    parser = argparse.ArgumentParser(
        prog="build.py", description=f"{title}\n\n{description}", epilog="exit codes:" + epilog,
        formatter_class=argparse.RawDescriptionHelpFormatter,
        usage="%(prog)s [dev|release|check] [options]",
    )
    parser.add_argument("command", nargs="?", default="dev", choices=("dev", "release", "check"),
                        help="what to build (default: dev)")
    parser.add_argument("--plugins-dir", type=Path, default=DEFAULT_PLUGINS_DIR, metavar="DIR",
                        help=f"Openplanet user Plugins dir (default: {short(DEFAULT_PLUGINS_DIR)}; env PLUGINS_DIR)")
    parser.add_argument("--skip-lsp", action="store_true", help="skip the openplanet-lsp static check")
    parser.add_argument("--reload", choices=("auto", "mcp", "remote", "none"), default="auto",
                        help="dev hot-reload backend: auto = tm-control-mcp, then tm-remote-build (default: auto)")
    parser.add_argument("--no-reload", dest="reload", action="store_const", const="none",
                        help="dev: stage only (same as --reload none)")
    parser.add_argument("-v", "--verbose", action="store_true",
                        help="list copied files and show the raw tool commands and output")
    args = parser.parse_args(argv)
    if args.command == "check" and args.skip_lsp:
        parser.error("check with --skip-lsp has nothing to do")
    return args


def main(argv: list[str] | None = None) -> int:
    global LOG_PATH
    args = parse_args(argv)
    ui = UI(verbose=args.verbose)
    t0 = time.monotonic()
    label = {"dev": "dev build", "release": "release build", "check": "check"}[args.command]
    try:
        load_config()
        manifest = read_manifest()
        slug = checked_slug(manifest)
        plugins_dir = args.plugins_dir.expanduser()
        if not os.environ.get("TM_OPENPLANET_LOG"):
            LOG_PATH = plugins_dir.parent / "Openplanet.log"
        command = {"dev": cmd_dev, "release": cmd_release, "check": cmd_check}[args.command]
        parts = command(ui, args, manifest, slug, plugins_dir)
    except BuildError as exc:
        ui.out()
        if not exc.reported:
            ui.error(exc.message)
        took = fmt_secs(time.monotonic() - t0)
        where = f" at {exc.phase}" if exc.phase else ""
        note = "; staged files are in place" if exc.code == EXIT_RELOAD else ""
        ui.out(ui.c(f"{ui.sym['fail']} {label} FAILED{where}", "red", "bold")
               + f"  {exc.message}{note} {ui.c(ui.sym['dot'] + ' ' + took, 'dim')}")
        if exc.hint:
            ui.out(f"  {ui.c(ui.sym['arrow'], 'yellow')} {exc.hint}")
        return exc.code
    except KeyboardInterrupt:
        ui.out()
        ui.out(ui.c(f"{ui.sym['fail']} {label} interrupted", "red", "bold"))
        return 130
    took = fmt_secs(time.monotonic() - t0)
    sep = f" {ui.c(ui.sym['dot'], 'dim')} "
    ui.out()
    ui.out(ui.c(f"{ui.sym['ok']} {label} OK", "green", "bold") + "  " + sep.join([*parts, took]))
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
