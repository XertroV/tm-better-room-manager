def get_the_string(line: str):
    return line.split('"')[1]

def run(lines: list[str]):
    i = 0
    currMode = ""
    res = dict()
    currItems = []
    while i < len(lines):
        line = lines[i]
        if 'C_ModeIndex_' in line:
            currMode = line.split('C_ModeIndex_')[1].split('}')[0]
            currItems = res.get(currMode, list())
            res[currMode] = currItems
            i += 1
            continue
        elif 'K_ScriptSetting' in line:
            # next 3 lines are what we want
            currItems.append((get_the_string(lines[i+1]), get_the_string(lines[i+2]), get_the_string(lines[i+3])))
            i += 4
            continue
        else:
            i += 1
            continue
    print(res)
    return res

ml_defaults = """
#Const {{{P}}}C_DefaultScriptSettings	[
	{{{Const::C_ModeIndex_TimeAttack}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_TimeLimit",
			Value = "300",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_ForceLapsNb",
			Value = "-1",
			Type = "integer"
		}
	],
	{{{Const::C_ModeIndex_Rounds}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsRepartition",
			Value = "",
			Type = "text"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsLimit",
			Value = "50",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_FinishTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_RoundsPerMap",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_MapsPerMatch",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_UseTieBreak",
			Value = "true",
			Type = "boolean"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		}
	],
	{{{Const::C_ModeIndex_Laps}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_TimeLimit",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_ForceLapsNb",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_InfiniteLaps",
			Value = "false",
			Type = "boolean"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_FinishTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_DisableGiveUp",
			Value = "false",
			Type = "boolean"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		}
	],
	{{{Const::C_ModeIndex_Knockout}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsRepartition",
			Value = "",
			Type = "text"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_FinishTimeout",
			Value = "5",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_RoundsPerMap",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_ChatTime",
			Value = "6",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_EliminatedPlayersNbRanks",
			Value = "4,16,16",
			Type = "text"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_RoundsWithoutElimination",
			Value = "1",
			Type = "integer"
		}
	],
	{{{Const::C_ModeIndex_Cup}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsRepartition",
			Value = "",
			Type = "text"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsLimit",
			Value = "100",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_FinishTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_RoundsPerMap",
			Value = "5",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_NbOfWinners",
			Value = "3",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		}
	],
	{{{Const::C_ModeIndex_Teams}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsLimit",
			Value = "100",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_FinishTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_MaxPointsPerRound",
			Value = "6",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsGap",
			Value = "1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_UseCustomPointsRepartition",
			Value = "false",
			Type = "boolean"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_PointsRepartition",
			Value = "",
			Type = "text"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_CumulatePoints",
			Value = "false",
			Type = "boolean"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_RoundsPerMap",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_MapsPerMatch",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpNb",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpDuration",
			Value = "0",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_WarmUpTimeout",
			Value = "-1",
			Type = "integer"
		},
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_UseAlternateRules",
			Value = "true",
			Type = "boolean"
		}
	],
	{{{Const::C_ModeIndex_RoyalTimeAttack}}} => [
		{{{ClubStruct::P}}}K_ScriptSetting {
			Key = "S_TimeLimit",
			Value = "150",
			Type = "integer"
		}
	]
]
"""

for k,vs in run(ml_defaults.split("\n")).items():
    print(f"@tmp = scriptDefaults[GameMode::{k}];")
    for v in vs:
        print(f"tmp.InsertLast({{'{v[0]}', '{v[1]}'}});")
