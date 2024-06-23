import csv
from pathlib import Path
import sys

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



def insert_col_if_missing(name, index):
    if len(header_row) >= index or name != header_row[index]:
        header_row.insert(index, name)
        for row in rows:
            row.insert(index, "")

insert_col_if_missing("CupLong", 22)
insert_col_if_missing("CupShort", 23)
insert_col_if_missing("RoundsBoulet", 24)


def get_opts_from(mode_name):
    ix = header_row.index(mode_name)
    if ix < 1:
        raise Exception(f"Unknown mode: {mode_name}")
    opts = []
    for row in rows:
        if row[ix] == '1':
            opts.append(row[0])
    return opts


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
    "S_ChatTime",
    "S_CompetitionName",
    "S_CupPointsLimit",
    "S_DecoImageUrl_Screen16x1",
    "S_DecoImageUrl_Screen16x9",
    "S_DecoImageUrl_Screen8x1",
    "S_EarlyEndMatchCallback",
    "S_EnableAmbientSound",
    "S_EnablePreMatch",
    "S_EnableTrophiesGain",
    "S_EnableWinScreen",
    "S_EndRoundPostScoreUpdateDuration",
    "S_EndRoundPreScoreUpdateDuration",
    "S_FinishTimeout",
    "S_ForceRoadSpectatorsNb",
    "S_HideScoresHeader",
    "S_KOCheckpointNb",
    "S_KOCheckpointTime",
    "S_KOValidationDelay",
    "S_LoadMatchState",
    "S_MapWorldRecord",
    "S_MatchLevel",
    "S_MatchPointsLimit",
    "S_MatchStyle",
    "S_MatchType",
    "S_NbOfWinners",
    "S_OverridePlayerProfiles",
    "S_PointsRepartition",
    "S_RoundsPerMap",
    "S_SponsorsUrl",
    "S_StepNb",
    "S_StopMatchIfNotEnoughPlayers",
    "S_TrackNb",
    "S_TracksTotal",
    "S_WarmUpDuration",
    "S_WarmUpNb",
    "S_WarmUpTimeout",
]

rounds_mode_opts = get_opts_from("Rounds")

print(f"Rounds mode options: {rounds_mode_opts}")

set_opts_for_mode("CupLong", champ_spring_2022_opts)
set_opts_for_mode("CupShort", champ_spring_2022_opts)
set_opts_for_mode("RoundsBoulet", rounds_mode_opts)

def gen_csv():
    all_rows = [header_row] + rows
    all_rows.sort()
    return '\n'.join([','.join(row) for row in all_rows])

print(gen_csv())
modes_csv_path.write_text(gen_csv())
