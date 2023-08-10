import csv
from pathlib import Path

modes_csv_path = Path("./GameModes.csv")
contents = modes_csv_path.read_text()

reader = csv.reader(contents.splitlines())
header_row = []
rows = []
for i, line in enumerate(reader):
    if i == 0:
        header_row = line
    else:
        rows.append(line)

def set_opts_for_mode(mode_name: str, opts: list[str]):
    ix = header_row.index(mode_name)
    if ix < 1:
        raise Exception(f"Unknown mode: {mode_name}")
    added = set()
    for row in rows:
        if row[0] in opts:
            row[ix] = '1'
            added.add(row[0])
    missing = set(opts) - added
    for opt in missing:
        new_row = [opt] + ['']*(len(header_row) - 1)
        new_row[ix] = '1'
        rows.append(new_row)

champ_spring_2022_opts = [
    "S_MatchPointsLimit",
    "S_CupPointsLimit",
    "S_RoundsPerMap",
    "S_NbOfWinners",
    "S_StopMatchIfNotEnoughPlayers",
    "S_FinishTimeout",
    "S_PointsRepartition",
    "S_MatchStyle",
    "S_MatchType",
    "S_MatchLevel",
    "S_TrackNb",
    "S_TracksTotal",
    "S_KOCheckpointNb",
    "S_KOCheckpointTime",
    "S_KOValidationDelay",
    "S_ChatTime",
    "S_WarmUpNb",
    "S_WarmUpDuration",
    "S_WarmUpTimeout",
    "S_EnableAmbientSound",
    "S_HideScoresHeader",
    "S_EnableWinScreen",
    "S_EnablePreMatch",
    "S_ForceRoadSpectatorsNb",
    "S_EarlyEndMatchCallback",
    "S_EndRoundPreScoreUpdateDuration",
    "S_EndRoundPostScoreUpdateDuration",
    "S_DecoImageUrl_Screen16x9",
    "S_DecoImageUrl_Screen8x1",
    "S_DecoImageUrl_Screen16x1",
    "S_OverridePlayerProfiles",
    "S_LoadMatchState",
    "S_EnableTrophiesGain",
    "S_CompetitionName",
    "S_StepNb",
    "S_MapWorldRecord",
    "S_SponsorsUrl",
]

set_opts_for_mode("ChampionSpring2022", champ_spring_2022_opts)
set_opts_for_mode("CupClassic", champ_spring_2022_opts)

def gen_csv():
    all_rows = [header_row] + rows
    all_rows.sort()
    return '\n'.join([','.join(row) for row in all_rows])

print(gen_csv())
modes_csv_path.write_text(gen_csv())
