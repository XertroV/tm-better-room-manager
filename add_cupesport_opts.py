import csv
from pathlib import Path

GM_COLUMN_NUMBER = 26
GM_NAME = "CupEsport"

modes_csv_path = Path("./GameModes.csv")
contents = modes_csv_path.read_text()

reader = csv.reader(contents.splitlines())
header_row = []
rows: list[list[str]] = []
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

insert_col_if_missing(GM_NAME, GM_COLUMN_NUMBER)


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
    if len(missing) > 0:
        m2 = list(missing)
        m2.sort()
        print(f"\n !! Missing Settings: {m2}\m")
    for opt in missing:
        new_row = [opt] + ['']*(len(header_row) - 1)
        new_row[ix] = '1'
        rows.append(new_row)

mode_opts = [
    "S_ClubId",
    "S_ClubName",
    "S_CrashDetectionThreshold",
    "S_DecoImageUrl_Checkpoint",
    "S_DecoImageUrl_DecalSponsor4x1",
    "S_DecoImageUrl_Screen16x1",
    "S_DecoImageUrl_Screen16x9",
    "S_DecoImageUrl_Screen8x1",
    "S_DecoImageUrl_WhoAmIUrl",
    "S_DisableGoToMap",
    "S_DisableManiapubsOnScreens",
    "S_DisableScoresHeaderInterface",
    "S_EnableJoinLeaveNotifications",
    "S_EnablePreMatch",
    "S_FinishTimeout",
    "S_ForceLapsNb",
    "S_ForceLapsNb",
    "S_InfiniteLaps",
    "S_InfiniteLaps",
    "S_IsSplitScreen",
    "S_LoadingScreenImageUrl",
    "S_NbOfWinners",
    "S_PickAndBan_Enable",
    "S_PickAndBan_Style",
    "S_PlayerProfilesUrl",
    "S_PointsLimit",
    "S_PointsRepartition",
    "S_RespawnBehaviour",
    "S_RoundsPerMap",
    "S_SeasonIds",
    "S_SponsorsUrl",
    "S_SynchronizePlayersAtMapStart",
    "S_TournamentStatsApiAuthorizationHeader",
    "S_TournamentStatsApiCompetitionUid",
    "S_TournamentStatsApiUrl",
    "S_TrustClientSimu",
    "S_UseCrudeExtrapolation",
    "S_UsePublicRecords",
    "S_WarmUpDuration",
    "S_WarmUpNb",
    "S_WarmUpTimeout",
]


set_opts_for_mode(GM_NAME, mode_opts)

def gen_csv():
    all_rows = [header_row] + rows
    all_rows.sort()
    return '\n'.join([','.join(row) for row in all_rows])

print(gen_csv())
modes_csv_path.write_text(gen_csv())
