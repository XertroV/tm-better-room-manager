enum GameMode {
    Unknown = 0,
    Cup = 1,
    Knockout = 2,
    Laps = 3,
    Teams = 4,
    TimeAttack = 5,
    Rounds = 6
}

// NOTE: Array and Dict at end.

// todo: confirm mode strings. Rounds should be
const string GameModeToFullModeString(GameMode m) {
    switch (m) {
        case GameMode::Cup: return "TrackMania/TM_Cup_Online.Script.txt";
        case GameMode::Knockout: return "TrackMania/TM_Knockout_Online.Script.txt";
        case GameMode::Laps: return "TrackMania/TM_Laps_Online.Script.txt";
        case GameMode::Teams: return "TrackMania/TM_Teams_Online.Script.txt";
        case GameMode::TimeAttack: return "TrackMania/TM_TimeAttack_Online.Script.txt";
        case GameMode::Rounds: return "TrackMania/TM_Rounds_Online.Script.txt";
    }
    throw("Unknown mode");
    return "";
}

GameMode GameModeFromStr(const string &in modeStr) {
    if (modeStr == "TrackMania/TM_Cup_Online.Script.txt") return GameMode::Cup;
    if (modeStr == "TrackMania/TM_Knockout_Online.Script.txt") return GameMode::Knockout;
    if (modeStr == "TrackMania/TM_Laps_Online.Script.txt") return GameMode::Laps;
    if (modeStr == "TrackMania/TM_Teams_Online.Script.txt") return GameMode::Teams;
    if (modeStr == "TrackMania/TM_TimeAttack_Online.Script.txt") return GameMode::TimeAttack;
    if (modeStr == "TrackMania/TM_Rounds_Online.Script.txt") return GameMode::Rounds;
    return GameMode::Unknown;
}

const string GameModeCSV = """,Cup,Knockout,Laps,Teams,TimeAttack,Rounds
S_ChatTime,1,1,1,1,1,1
S_CumulatePoints,,,,1,,
S_DecoImageUrl_Checkpoint,1,1,1,1,1,1
S_DecoImageUrl_DecalSponsor4x1,1,1,1,1,1,1
S_DecoImageUrl_Screen16x1,1,1,1,1,1,1
S_DecoImageUrl_Screen16x9,1,1,1,1,1,1
S_DecoImageUrl_Screen8x1,1,1,1,1,1,1
S_DecoImageUrl_WhoAmIUrl,1,1,1,1,1,1
S_DelayBeforeNextMap,1,1,1,1,1,1
S_DisableGiveUp,,,1,,,
S_EarlyEndMatchCallback,,1,,,,
S_EliminatedPlayersNbRanks,,1,,,,
S_FinishTimeout,1,1,1,1,,1
S_ForceLapsNb,1,1,1,1,1,1
S_InfiniteLaps,1,1,1,1,1,1
S_IsChannelServer,1,1,1,1,1,1
S_IsSplitScreen,1,1,1,1,1,1
S_MapsPerMatch,,,,1,,1
S_MatchPosition,,1,,,,
S_MaxPointsPerRound,,,,1,,
S_NbOfWinners,1,,,,,
S_NeutralEmblemUrl,1,1,1,1,1,1
S_PointsGap,,,,1,,
S_PointsLimit,1,,,1,,1
S_PointsRepartition,1,1,,1,,1
S_RespawnBehaviour,1,1,1,1,1,1
S_RoundsPerMap,1,1,,1,,1
S_RoundsWithoutElimination,,1,,,,
S_ScriptEnvironment,1,1,1,1,1,1
S_SeasonIds,1,1,1,1,1,1
S_SynchronizePlayersAtMapStart,1,1,1,1,1,1
S_SynchronizePlayersAtRoundStart,1,1,1,1,1,1
S_TimeLimit,,,1,,1,
S_TrustClientSimu,1,1,1,1,1,1
S_UseAlternateRules,,,,1,,
S_UseClublinks,1,1,1,1,1,1
S_UseClublinksSponsors,1,1,1,1,1,1
S_UseCrudeExtrapolation,1,1,1,1,1,1
S_UseCustomPointsRepartition,,,,1,,
S_UseTieBreak,,,,1,,
S_WarmUpDuration,1,1,1,1,1,1
S_WarmUpNb,1,1,1,1,1,1
S_WarmUpTimeout,1,1,1,1,1,1""";

string[][]@ _GetGameModeValidOpts() {
    auto lines = GameModeCSV.Split("\n");
    string[][] ret;
    ret.Resize(7);
    for (uint l = 1; l < lines.Length; l++) {
        auto parts = lines[l].Split(',');
        auto settingName = parts[0];
        for (uint gm = 1; gm <= 6; gm++) {
            if (parts[gm] == "1") ret[gm].InsertLast(settingName);
        }
    }
    return ret;
}


void PrintGameModeOpts() {
    for (uint gm = 1; gm < GameModeOpts.Length; gm++) {
        auto item = GameModeOpts[gm];
        print(tostring(GameMode(gm)));
        for (uint i = 0; i < item.Length; i++) {
            print("  " + item[i]);
        }
    }
}

dictionary@ _GetSettingsToType() {
    dictionary ret;
    ret["S_BestLapBonusPoints"] = "integer";
    ret["S_ChatTime"] = "integer";
    ret["S_CumulatePoints"] = "boolean";
    ret["S_DecoImageUrl_Checkpoint"] = "text";
    ret["S_DecoImageUrl_DecalSponsor4x1"] = "text";
    ret["S_DecoImageUrl_Screen16x1"] = "text";
    ret["S_DecoImageUrl_Screen16x9"] = "text";
    ret["S_DecoImageUrl_Screen8x1"] = "text";
    ret["S_DecoImageUrl_WhoAmIUrl"] = "text";
    ret["S_DelayBeforeNextMap"] = "text";
    ret["S_DisableGiveUp"] = "boolean";
    ret["S_EarlyEndMatchCallback"] = "boolean";
    ret["S_EliminatedPlayersNbRanks"] = "text";
    ret["S_EndRoundPostScoreUpdateDuration"] = "integer";
    ret["S_EndRoundPreScoreUpdateDuration"] = "integer";
    ret["S_FinishTimeout"] = "integer";
    ret["S_ForceLapsNb"] = "integer";
    ret["S_ForceWinnersNb"] = "integer";
    ret["S_InfiniteLaps"] = "boolean";
    ret["S_IsChannelServer"] = "boolean";
    ret["S_IsSplitScreen"] = "boolean";
    ret["S_MapsPerMatch"] = "integer";
    ret["S_MatchPosition"] = "integer";
    ret["S_MaxPointsPerRound"] = "integer";
    ret["S_NbOfWinners"] = "integer";
    ret["S_NeutralEmblemUrl"] = "text";
    ret["S_PauseBeforeRoundNb"] = "integer";
    ret["S_PauseDuration"] = "integer";
    ret["S_PointsGap"] = "integer";
    ret["S_PointsLimit"] = "integer";
    ret["S_PointsRepartition"] = "text";
    ret["S_RespawnBehaviour"] = "integer";
    ret["S_RoundsLimit"] = "integer";
    ret["S_RoundsPerMap"] = "integer";
    ret["S_RoundsWithAPhaseChange"] = "text";
    ret["S_RoundsWithoutElimination"] = "integer";
    ret["S_ScriptEnvironment"] = "text";
    ret["S_SeasonIds"] = "text";
    ret["S_SynchronizePlayersAtMapStart"] = "boolean";
    ret["S_SynchronizePlayersAtRoundStart"] = "boolean";
    ret["S_TimeLimit"] = "integer";
    ret["S_TimeOutPlayersNumber"] = "integer";
    ret["S_TrustClientSimu"] = "boolean";
    ret["S_UseAlternateRules"] = "boolean";
    ret["S_UseClublinks"] = "boolean";
    ret["S_UseClublinksSponsors"] = "boolean";
    ret["S_UseCrudeExtrapolation"] = "boolean";
    ret["S_UseCustomPointsRepartition"] = "boolean";
    ret["S_UseTieBreak"] = "boolean";
    ret["S_WarmUpDuration"] = "integer";
    ret["S_WarmUpNb"] = "integer";
    ret["S_WarmUpTimeout"] = "integer";
    ret["S_WinnersRatio"] = "Float";
    return ret;
}


const string GetScriptOptType(const string &in key) {
    string ret;
    settingToType.Get(key, ret);
    return ret;
}




string[][][]@ _GetScriptDefaults() {
    string[][][] scriptDefaults;
    scriptDefaults.Resize(7);
    string[][] @tmp;

    @tmp = scriptDefaults[GameMode::TimeAttack];
    tmp.InsertLast({'S_TimeLimit', '300'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_ForceLapsNb', '-1'});
    @tmp = scriptDefaults[GameMode::Rounds];
    tmp.InsertLast({'S_PointsRepartition', ''});
    tmp.InsertLast({'S_PointsLimit', '50'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_RoundsPerMap', '-1'});
    tmp.InsertLast({'S_MapsPerMatch', '-1'});
    tmp.InsertLast({'S_UseTieBreak', 'true'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    @tmp = scriptDefaults[GameMode::Laps];
    tmp.InsertLast({'S_TimeLimit', '0'});
    tmp.InsertLast({'S_ForceLapsNb', '-1'});
    tmp.InsertLast({'S_InfiniteLaps', 'false'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_DisableGiveUp', 'false'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    @tmp = scriptDefaults[GameMode::Knockout];
    tmp.InsertLast({'S_PointsRepartition', ''});
    tmp.InsertLast({'S_FinishTimeout', '5'});
    tmp.InsertLast({'S_RoundsPerMap', '-1'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_ChatTime', '6'});
    tmp.InsertLast({'S_EliminatedPlayersNbRanks', '4,16,16'});
    tmp.InsertLast({'S_RoundsWithoutElimination', '1'});
    @tmp = scriptDefaults[GameMode::Cup];
    tmp.InsertLast({'S_PointsRepartition', ''});
    tmp.InsertLast({'S_PointsLimit', '100'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_RoundsPerMap', '5'});
    tmp.InsertLast({'S_NbOfWinners', '3'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    @tmp = scriptDefaults[GameMode::Teams];
    tmp.InsertLast({'S_PointsLimit', '100'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_MaxPointsPerRound', '6'});
    tmp.InsertLast({'S_PointsGap', '1'});
    tmp.InsertLast({'S_UseCustomPointsRepartition', 'false'});
    tmp.InsertLast({'S_PointsRepartition', ''});
    tmp.InsertLast({'S_CumulatePoints', 'false'});
    tmp.InsertLast({'S_RoundsPerMap', '-1'});
    tmp.InsertLast({'S_MapsPerMatch', '-1'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_UseAlternateRules', 'true'});
    // @tmp = scriptDefaults[GameMode::RoyalTimeAttack];
    // tmp.InsertLast({'S_TimeLimit', '150'});
    return scriptDefaults;
}


class GameOpt {
    string key, value, type;
    bool boolVal;
    int intVal;
    string strVal;

    GameOpt(const string &in key, const string &in value, const string &in type) {
        if (!settingToType.Exists(key)) throw('GameOpt unknown key: ' + key);
        this.key = key;
        this.value = value;
        settingToType.Get(key, this.type);

        if (this.type != type) throw("Mismatching types for " + key + ": " + type + " and " + this.type + " (latter from dict)");

        if (type == "boolean") boolVal = value == "true";
        else if (type == "integer") intVal = Text::ParseInt(value);
        else strVal = value;
    }

    void DrawOption(bool withLabel = true) {
        if (type == "boolean") DrawBoolOpt(withLabel);
        else if (type == "integer") DrawIntOpt(withLabel);
        else DrawTextOpt(withLabel);
    }

    protected void DrawBoolOpt(bool withLabel = true) {
        auto orig = boolVal;
        boolVal = UI::Checkbox(withLabel ? key : "##"+key, boolVal);
        if (orig != boolVal) value = tostring(boolVal);
    }

    protected void DrawIntOpt(bool withLabel = true) {
        auto orig = intVal;
        intVal = UI::InputInt(withLabel ? key : "##"+key, intVal);
        if (orig != intVal) value = tostring(intVal);
    }

    protected void DrawTextOpt(bool withLabel = true) {
        bool changed;
        strVal = UI::InputText(withLabel ? key : "##"+key, strVal, changed);
        if (changed) value = strVal;
    }

    const string DocsUrl() {
        return "https://wiki.trackmania.io/en/dedicated-server/Usage/OfficialGameModesSettings#" + key.ToLower();
    }

    Json::Value@ ToJson() {
        auto j = Json::Object();
        j['key'] = key;
        j['value'] = value;
        j['type'] = type;
        return j;
    }
}



string GetScriptDefaultFor(GameMode mode, const string &in optName) {
    string[][]@ tmp = scriptDefaults[mode];
    for (uint i = 0; i < tmp.Length; i++) {
        auto item = tmp[i];
        if (item[0] == optName) return item[1];
    }
    return "";
}




// Zeroth array is empty, otherwise corresponds to int(GameMode)
string[][]@ GameModeOpts = _GetGameModeValidOpts();

dictionary@ settingToType = _GetSettingsToType();

string[][][]@ scriptDefaults = _GetScriptDefaults();
