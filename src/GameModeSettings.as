enum GameMode {
    Unknown = 0,
    Cup = 1,
    Knockout = 2,
    Laps = 3,
    Teams = 4,
    TimeAttack = 5,
    Rounds = 6,
    RoyalTimeAttack = 7,
    // unofficial but included ones?
    TMWTTeams,
    TMWTMatchmaking,
    TeamsMatchmaking,
    TimeAttackDaily,
    KnockoutDaily,
    COTDQualifications,
    CupClassic,
    ChampionSpring2022,
    // unlisted modes
    MultiTeams,
    HeadToHead,
    Final42TMGL,
    // leave last for loops
    XXX_LAST
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
        case GameMode::RoyalTimeAttack: return "TrackMania/TM_RoyalTimeAttack_Online.Script.txt";
        // hidden game modes:
        case GameMode::TMWTTeams: return "TrackMania/TM_TMWTTeams_Online.Script.txt";
        case GameMode::TMWTMatchmaking: return "TrackMania/TM_TMWTMatchmaking_Online.Script.txt";
        case GameMode::TeamsMatchmaking: return "TrackMania/TM_Teams_Matchmaking_Online.Script.txt";
        case GameMode::TimeAttackDaily: return "TrackMania/TM_TimeAttackDaily_Online.Script.txt";
        case GameMode::KnockoutDaily: return "TrackMania/TM_KnockoutDaily_Online.Script.txt";
        case GameMode::COTDQualifications: return "TrackMania/TM_COTDQualifications_Online.Script.txt";
        case GameMode::CupClassic: return "TrackMania/Legacy/TM_CupClassic_Online.Script.txt";
        case GameMode::ChampionSpring2022: return "TrackMania/Legacy/TM_ChampionSpring2022_Online.Script.txt";
        // unlisted
        case GameMode::MultiTeams: return "TrackMania/TM_MultiTeams_Online.Script.txt";
        case GameMode::HeadToHead: return "TrackMania/TM_HeadToHead_Online.Script.txt";
        case GameMode::Final42TMGL: return "TrackMania/TM_Final42TMGL_Online.Script.txt";
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
    if (modeStr == "TrackMania/TM_RoyalTimeAttack_Online.Script.txt") return GameMode::RoyalTimeAttack;
    // hidden game modes:
    if (modeStr == "TrackMania/TM_TMWTTeams_Online.Script.txt") return GameMode::TMWTTeams;
    if (modeStr == "TrackMania/TM_TMWTMatchmaking_Online.Script.txt") return GameMode::TMWTMatchmaking;
    if (modeStr == "TrackMania/TM_Teams_Matchmaking_Online.Script.txt") return GameMode::TeamsMatchmaking;
    if (modeStr == "TrackMania/TM_TimeAttackDaily_Online.Script.txt") return GameMode::TimeAttackDaily;
    if (modeStr == "TrackMania/TM_KnockoutDaily_Online.Script.txt") return GameMode::KnockoutDaily;
    if (modeStr == "TrackMania/TM_COTDQualifications_Online.Script.txt") return GameMode::COTDQualifications;
    if (modeStr == "TrackMania/Legacy/TM_CupClassic_Online.Script.txt") return GameMode::CupClassic;
    if (modeStr == "TrackMania/Legacy/TM_ChampionSpring2022_Online.Script.txt") return GameMode::ChampionSpring2022;
        // unlisted
    if (modeStr == "TrackMania/TM_MultiTeams_Online.Script.txt") return GameMode::MultiTeams;
    if (modeStr == "TrackMania/TM_HeadToHead_Online.Script.txt") return GameMode::HeadToHead;
    if (modeStr == "TrackMania/TM_Final42TMGL_Online.Script.txt") return GameMode::Final42TMGL;
    // default
    return GameMode::Unknown;
}

/*
  These are universal because they're defined in ModeBase.Script.txt
*/
string UniversalModeSettings = """
S_RespawnBehaviour
S_ForceLapsNb
S_InfiniteLaps
S_EnableJoinLeaveNotifications
S_SeasonIds
S_IsSplitScreen
S_DecoImageUrl_WhoAmIUrl
S_DecoImageUrl_Checkpoint
S_DecoImageUrl_DecalSponsor4x1
S_DecoImageUrl_Screen16x9
S_DecoImageUrl_Screen8x1
S_DecoImageUrl_Screen16x1
S_ClubId
S_ClubName
S_LoadingScreenImageUrl
S_TrustClientSimu
S_UseCrudeExtrapolation
S_SynchronizePlayersAtMapStart
S_DisableGoToMap
S_PickAndBan_Enable
S_PickAndBan_Style
""";

const string GameModeCSV = """,Cup,Knockout,Laps,Teams,TimeAttack,Rounds,RoyalTimeAttack,TMWTTeams,TMWTMatchmaking,TeamsMatchmaking,TimeAttackDaily,KnockoutDaily,COTDQualifications,CupClassic,ChampionSpring2022,MultiTeams,HeadToHead,Final42TMGL
S_BalanceScore,,,,,,,,,,1,,,,,,,,
S_BasicAuthHeader,,,,,,,,,,,1,,1,,,,,
S_BestLapBonusPoints,,,,,,,,,,,,,,,,,,
S_Bots_Clan,,,,,,,,,,1,,,,,,,,
S_Bots_EnablePlaying,,,,,,,,,,1,,,,,,,,
S_Bots_EnableRecording,,,,,,,,,,1,,,,,,,,
S_Bots_GhostDBId,,,,,,,,,,1,,,,,,,,
S_Bots_GhostsPerBot,,,,,,,,,,1,,,,,,,,
S_Bots_LevelRange,,,,,,,,,,1,,,,,,,,
S_Bots_LevelShift,,,,,,,,,,1,,,,,,,,
S_Bots_PBMultiplier,,,,,,,,,,1,,,,,,,,
S_ChatTime,1,1,1,1,1,1,1,1,1,1,,1,,1,1,,1,1
S_ClubId,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_ClubName,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_CompetitionName,,,,,,,,,,,,1,,1,1,,,
S_CumulatePoints,,,,1,,,,,,1,,,,,,,,
S_CupPointsLimit,,,,,,,,,,,,,,1,1,,,
S_DecoImageUrl_Checkpoint,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_DecoImageUrl_DecalSponsor4x1,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_DecoImageUrl_Screen16x1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,,1,1
S_DecoImageUrl_Screen16x9,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,,1,1
S_DecoImageUrl_Screen8x1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,,1,1
S_DecoImageUrl_WhoAmIUrl,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_DelayBeforeNextMap,1,1,1,1,1,1,1,,,,,1,,,,,,
S_DisableGiveUp,,,1,,,,,,,,,,,,,,,
S_DisableGoToMap,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_Division,,,,,,,,,,,,1,,,,,,
S_EarlyEndMatchCallback,,1,,,,,,1,1,1,,1,,1,1,,,
S_EliminatedPlayersNbRanks,,1,,,,,,,,,,1,,,,,,
S_EnableAmbientSound,,,,,,,,,,,,,,1,1,,1,1
S_EnableDossardColor,,,,,,,,1,,,,,,,,,,
S_EnableJoinLeaveNotifications,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_EnablePreMatch,,,,,,,,,,,,,,1,1,,,
S_EnableTrophiesGain,,,,,,,,,,,,,,1,1,,,
S_EnableWinScreen,,,,,,,,,,,,,,1,1,,1,1
S_EndRoundPostScoreUpdateDuration,,,,,,,,,,,,,,1,1,,,
S_EndRoundPreScoreUpdateDuration,,,,,,,,,,,,,,1,1,,,
S_FinalistsAccountIds,,,,,,,,,,,,,,,,,1,1
S_FinishTimeout,1,1,1,1,,1,,1,1,1,,1,,1,1,1,1,1
S_FinishTimeoutDivider,,,,,,,,,,1,,,,,,,,
S_ForceLapsNb,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,1,1
S_ForceRoadSpectatorsNb,,,,,,,,1,,,,,,1,1,,1,1
S_HideScoresHeader,,,,,,,,,,,,,,1,1,,,
S_InfiniteLaps,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_IntroMaxDuration,,,,,,,,,,,1,,1,,,,,
S_IsChannelServer,1,1,1,1,1,1,1,,,,,1,,,,,,
S_IsMatchmaking,,,,,,,,1,,,,,,,,,,
S_IsSplitScreen,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_KOCheckpointNb,,,,,,,,,,,,,,1,1,,1,1
S_KOCheckpointTime,,,,,,,,,,,,,,1,1,,1,1
S_KOValidationDelay,,,,,,,,,,,,,,1,1,,1,1
S_LoadMatchState,,,,,,,,,,,,,,1,1,,,
S_LoadingScreenImageUrl,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_LogLevel,,,,,,,,,,,1,,,,,,,
S_MapPointsLimit,,,,,,,,1,1,,,,,,,,1,1
S_MapWorldRecord,,,,,,,,,,,,,,1,1,,,
S_MapsPerMatch,,,,1,,1,,,,1,,,,,,1,,
S_MatchId,,,,,,,,,1,1,,,,,,,,
S_MatchInfo,,,,,,,,1,,,,,,,,,,
S_MatchLevel,,,,,,,,,,,,,,1,1,,,
S_MatchPointsLimit,,,,,,,,1,1,,,,,1,1,,1,1
S_MatchPosition,,1,,,,,,,,,,1,,,,,,
S_MatchStyle,,,,,,,,,,,,,,1,1,,,
S_MatchType,,,,,,,,,,,,,,1,1,,,
S_MatchmakingId,,,,,,,,,1,1,,,,,,,,
S_MaxPointsPerRound,,,,1,,,,,,1,,,,,,,,
S_NbOfWinners,1,,,,,,,,,,,,,1,1,,1,1
S_NeutralEmblemUrl,1,1,1,1,1,1,1,,,,,1,,,,,,
S_NoRoundTie,,,,,,,,,,1,,,,,,,,
S_OverridePlayerProfiles,,,,,,,,,,,,,,1,1,,1,1
S_PickAndBan_Enable,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_PickAndBan_Style,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_PlayerPartition,,,,,,,,,,,1,,1,,,,,
S_PointsGap,,,,1,,,,,,1,,,,,,,,
S_PointsLimit,1,,,1,,1,,,,1,,,,,,1,,
S_PointsRepartition,1,1,,1,,1,,,,1,,1,,1,1,,1,1
S_PointsRepartition1VS,,,,,,,,,,1,,,,,,,,
S_PointsRepartition2VS,,,,,,,,,,1,,,,,,,,
S_QualificationsEndTime_MinMargin,,,,,,,,,,,1,,,,,,,
S_RankedCompetitionType,,,,,,,,,,,1,1,1,,,,,
S_RespawnBehaviour,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_RoundsPerMap,1,1,,1,,1,,,,1,,1,,1,1,1,,
S_RoundsWithoutElimination,,1,,,,,,,,,,1,,,,,,
S_ScriptEnvironment,1,1,1,1,1,1,1,,,1,1,1,,,,,,
S_SeasonIds,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_SponsorsUrl,,,,,,,,1,,,,,,1,1,,,
S_StepNb,,,,,,,,,,,,,,1,1,,,
S_StopMatchIfNotEnoughPlayers,,,,,,,,,,,,,,1,1,,,
S_SynchronizePlayersAtMapStart,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_SynchronizePlayersAtRoundStart,1,1,1,1,1,1,,,,1,,1,,,,,1,1
S_TeamsNb,,,,,,,,,,,,,,,,1,,
S_TeamsUrl,,,,,,,,1,1,,,,,,,,,
S_TimeLimit,,,1,,1,,1,,,,1,,1,,,,,
S_TrackNb,,,,,,,,,,,,,,1,1,,,
S_TracksTotal,,,,,,,,,,,,,,1,1,,,
S_TrustClientSimu,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_UseAlternateRules,,,,1,,,,,,1,,,,,,,,
S_UseClublinks,1,1,1,1,1,1,1,,,,,1,,,,,,
S_UseClublinksSponsors,1,1,1,1,1,1,1,,,,,1,,,,,,
S_UseCrudeExtrapolation,1,1,1,1,1,1,1,1,1,1,1,1,1,,,,,
S_UseCustomPointsRepartition,,,,1,,,,,,1,,,,,,,,
S_UseTieBreak,,,,1,,,,,,1,,,,,,1,,
S_WarmUpDuration,1,1,1,1,1,1,,1,1,1,1,1,,1,1,1,1,1
S_WarmUpNb,1,1,1,1,1,1,,1,1,1,1,1,,1,1,1,1,1
S_WarmUpTimeout,1,1,1,1,1,1,,1,1,1,1,1,,1,1,1,1,1
S_WorldRecords,,,,,,,,,,,,,,,,,1,1
""";

string[][]@ _GetGameModeValidOpts() {
    auto lines = GameModeCSV.Split("\n");
    auto universalModeSettings = UniversalModeSettings.Split("\n");
    string[][] ret;
    ret.Resize(int(GameMode::XXX_LAST));
    for (uint l = 1; l < lines.Length; l++) {
        if (lines[l].Length < 5) continue;
        auto parts = lines[l].Split(',');
        auto settingName = parts[0];
        for (uint gm = 1; gm < int(GameMode::XXX_LAST); gm++) {
            if (parts[gm] == "1" || universalModeSettings.Find(settingName) > -1) {
                ret[gm].InsertLast(settingName);
            }
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
    ret["S_BalanceScore"] = "boolean";
    ret["S_BasicAuthHeader"] = "text";
    ret["S_BestLapBonusPoints"] = "integer";
    ret["S_Bots_EnablePlaying"] = "boolean";
    ret["S_Bots_Clan"] = "integer";
    ret["S_Bots_GhostsPerBot"] = "integer";
    ret["S_Bots_EnableRecording"] = "boolean";
    ret["S_Bots_GhostDBId"] = "integer";
    ret["S_Bots_PBMultiplier"] = "float";
    ret["S_Bots_LevelShift"] = "integer";
    ret["S_Bots_LevelRange"] = "integer";
    ret["S_ChatTime"] = "integer";
    ret["S_ClubId"] = "integer";
    ret["S_ClubName"] = "text";
    ret["S_CompetitionName"] = "text";
    ret["S_CumulatePoints"] = "boolean";
    ret["S_CupPointsLimit"] = "integer";
    ret["S_DecoImageUrl_Checkpoint"] = "text";
    ret["S_DecoImageUrl_DecalSponsor4x1"] = "text";
    ret["S_DecoImageUrl_Screen16x1"] = "text";
    ret["S_DecoImageUrl_Screen16x9"] = "text";
    ret["S_DecoImageUrl_Screen8x1"] = "text";
    ret["S_DecoImageUrl_WhoAmIUrl"] = "text";
    ret["S_DelayBeforeNextMap"] = "text";
    ret["S_DisableGiveUp"] = "boolean";
    ret["S_DisableGoToMap"] = "boolean";
    ret["S_Division"] = "text";
    ret["S_EarlyEndMatchCallback"] = "boolean";
    ret["S_EliminatedPlayersNbRanks"] = "text";
    ret["S_EnableAmbientSound"] = "boolean";
    ret["S_EnableDossardColor"] = "boolean";
    ret["S_EnableJoinLeaveNotifications"] = "boolean";
    ret["S_EnablePreMatch"] = "boolean";
    ret["S_EnableTrophiesGain"] = "boolean";
    ret["S_EnableWinScreen"] = "boolean";
    ret["S_EndRoundPostScoreUpdateDuration"] = "integer";
    ret["S_EndRoundPreScoreUpdateDuration"] = "integer";
    ret["S_ForceRoadSpectatorsNb"] = "integer";
    ret["S_FinalistsAccountIds"] = "text";
    ret["S_FinishTimeout"] = "integer";
    ret["S_FinishTimeoutDivider"] = "integer";
    ret["S_ForceLapsNb"] = "integer";
    ret["S_ForceWinnersNb"] = "integer";
    ret["S_HideScoresHeader"] = "boolean";
    ret["S_InfiniteLaps"] = "boolean";
    ret["S_IntroMaxDuration"] = "integer";
    ret["S_IsChannelServer"] = "boolean";
    ret["S_IsSplitScreen"] = "boolean";
    ret["S_KOCheckpointNb"] = "integer";
    ret["S_KOCheckpointTime"] = "integer";
    ret["S_KOValidationDelay"] = "integer";
    ret["S_LoadMatchState"] = "text";
    ret["S_LoadingScreenImageUrl"] = "text";
    ret["S_LogLevel"] = "integer";
    ret["S_MapPointsLimit"] = "integer";
    ret["S_MapWorldRecord"] = "text";
    ret["S_MapsPerMatch"] = "integer";
    ret["S_MatchId"] = "text";
    ret["S_MatchInfo"] = "text";
    ret["S_MatchLevel"] = "integer";
    ret["S_MatchStyle"] = "integer";
    ret["S_MatchType"] = "integer";
    ret["S_MatchmakingId"] = "text";
    ret["S_MatchPointsLimit"] = "integer";
    ret["S_MatchPosition"] = "integer";
    ret["S_MaxPointsPerRound"] = "integer";
    ret["S_NbOfWinners"] = "integer";
    ret["S_NoRoundTie"] = "boolean";
    ret["S_NeutralEmblemUrl"] = "text";
    ret["S_OverridePlayerProfiles"] = "text";
    ret["S_PauseBeforeRoundNb"] = "integer";
    ret["S_PauseDuration"] = "integer";
    ret["S_PickAndBan_Enable"] = "boolean";
    ret["S_PickAndBan_Style"] = "text";
    ret["S_PlayerPartition"] = "text";
    ret["S_PointsGap"] = "integer";
    ret["S_PointsLimit"] = "integer";
    ret["S_PointsRepartition"] = "text";
    ret["S_PointsRepartition1VS"] = "text";
    ret["S_PointsRepartition2VS"] = "text";
    ret["S_QualificationsEndTime_MinMargin"] = "integer";
    ret["S_RankedCompetitionType"] = "text";
    ret["S_RespawnBehaviour"] = "integer";
    ret["S_RoundsLimit"] = "integer";
    ret["S_RoundsPerMap"] = "integer";
    ret["S_RoundsWithAPhaseChange"] = "text";
    ret["S_RoundsWithoutElimination"] = "integer";
    ret["S_ScriptEnvironment"] = "text";
    ret["S_SeasonIds"] = "text";
    ret["S_SponsorsUrl"] = "text";
    ret["S_StepNb"] = "integer";
    ret["S_StopMatchIfNotEnoughPlayers"] = "boolean";
    ret["S_SynchronizePlayersAtMapStart"] = "boolean";
    ret["S_SynchronizePlayersAtRoundStart"] = "boolean";
    ret["S_TeamsNb"] = "integer";
    ret["S_TeamsUrl"] = "text";
    ret["S_TimeLimit"] = "integer";
    ret["S_TrackNb"] = "integer";
    ret["S_TracksTotal"] = "integer";
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
    ret["S_WinnersRatio"] = "float";
    ret["S_WorldRecords"] = "text";
    return ret;
}


const string GetScriptOptType(const string &in key) {
    string ret;
    settingToType.Get(key, ret);
    return ret;
}




string[][][]@ _GetScriptDefaults() {
    string[][][] scriptDefaults;
    scriptDefaults.Resize(int(GameMode::XXX_LAST));
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
    @tmp = scriptDefaults[GameMode::RoyalTimeAttack];
    tmp.InsertLast({'S_TimeLimit', '150'});
    @tmp = scriptDefaults[GameMode::TMWTTeams];
    tmp.InsertLast({'S_MapPointsLimit', '10'});
    tmp.InsertLast({'S_MatchPointsLimit', '4'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_WarmUpNb', '1'});
    tmp.InsertLast({'S_WarmUpDuration', '20'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_MatchInfo', 'Trackmania Grand League'});
    tmp.InsertLast({'S_TeamsUrl', ''});
    tmp.InsertLast({'S_SponsorsUrl', 'file://Media/Manialinks/Nadeo/TMNext/Modes/TMWT/UI/KAPORAL_512x80.dds'});
    tmp.InsertLast({'S_ForceRoadSpectatorsNb', '-1'});
    tmp.InsertLast({'S_EarlyEndMatchCallback', 'true'});
    tmp.InsertLast({'S_EnableDossardColor', 'true'});
    tmp.InsertLast({'S_IsMatchmaking', 'false'});
    tmp.InsertLast({'S_PickAndBan_Enable', 'true'});
    tmp.InsertLast({'S_PickAndBan_Style', '{"Background": "file://Media/Manialinks/Nadeo/TMNext/Modes/TMWT/UI/TMWT_MatchIntroBackground.dds","TopLeftLogo": "file://Media/Manialinks/Nadeo/TMNext/Modes/TMWT/BrandsLogo/TMWT_Logo.dds","TopRightLogo": "file://Media/Manialinks/Nadeo/TMNext/Modes/TMWT/BrandsLogo/TMWT_TMGL.dds","BottomLogo": "file://Media/Manialinks/Nadeo/TMNext/Modes/TMWT/BrandsLogo/TMWT_Kaporal.dds"}'});
    tmp.InsertLast({'S_ChatTime', '600'});
    @tmp = scriptDefaults[GameMode::TMWTMatchmaking];
    tmp.InsertLast({'S_MapPointsLimit', '10'});
    tmp.InsertLast({'S_MatchPointsLimit', '1'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_TeamsUrl', ''});
    tmp.InsertLast({'S_EarlyEndMatchCallback', 'true'});
    tmp.InsertLast({'S_MatchmakingId', ''});
    tmp.InsertLast({'S_MatchId', ''});
    tmp.InsertLast({'S_ChatTime', '600'});
    tmp.InsertLast({'S_DecoImageUrl_Checkpoint', 'file://Media/Manialinks/Nadeo/TMNext/Modes/Matchmaking/Decal_Matchmaking.dds'});
    @tmp = scriptDefaults[GameMode::TeamsMatchmaking];
    tmp.InsertLast({'S_PointsLimit', '5'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_FinishTimeoutDivider', '3'});
    tmp.InsertLast({'S_MaxPointsPerRound', '6'});
    tmp.InsertLast({'S_PointsGap', '1'});
    tmp.InsertLast({'S_UseCustomPointsRepartition', 'true'});
    tmp.InsertLast({'S_PointsRepartition', '6, 5, 4, 3, 2, 1'});
    tmp.InsertLast({'S_PointsRepartition2VS', '4, 3, 2, 1'});
    tmp.InsertLast({'S_PointsRepartition1VS', '2, 1'});
    tmp.InsertLast({'S_CumulatePoints', 'false'});
    tmp.InsertLast({'S_RoundsPerMap', '-1'});
    tmp.InsertLast({'S_MapsPerMatch', '-1'});
    tmp.InsertLast({'S_UseTieBreak', 'true'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_UseAlternateRules', 'false'});
    tmp.InsertLast({'S_ChatTime', '6'});
    tmp.InsertLast({'S_NoRoundTie', 'true'});
    tmp.InsertLast({'S_BalanceScore', 'true'});
    tmp.InsertLast({'S_MatchmakingId', ''});
    tmp.InsertLast({'S_MatchId', ''});
    tmp.InsertLast({'S_EarlyEndMatchCallback', 'true'});
    tmp.InsertLast({'S_Bots_EnablePlaying', 'false'});
    tmp.InsertLast({'S_Bots_Clan', '2'});
    tmp.InsertLast({'S_Bots_GhostsPerBot', '10'});
    tmp.InsertLast({'S_Bots_EnableRecording', 'false'});
    tmp.InsertLast({'S_Bots_GhostDBId', '0'});
    tmp.InsertLast({'S_Bots_PBMultiplier', '1.1'});
    tmp.InsertLast({'S_Bots_LevelShift', '2'});
    tmp.InsertLast({'S_Bots_LevelRange', '10'});
    tmp.InsertLast({'S_DecoImageUrl_Checkpoint', 'file://Media/Manialinks/Nadeo/TMNext/Modes/Matchmaking/Decal_Matchmaking.dds'});
    tmp.InsertLast({'S_ScriptEnvironment', 'development'});
    tmp.InsertLast({'S_SynchronizePlayersAtRoundStart', 'true'});
    @tmp = scriptDefaults[GameMode::TimeAttackDaily];
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    tmp.InsertLast({'S_ForceLapsNb', '0'});
    tmp.InsertLast({'S_BasicAuthHeader', 'Basic xxx'});
    tmp.InsertLast({'S_ScriptEnvironment', 'production'});
    tmp.InsertLast({'S_LogLevel', '3'});
    tmp.InsertLast({'S_RankedCompetitionType', ''});
    tmp.InsertLast({'S_PlayerPartition', ''});
    tmp.InsertLast({'S_TimeLimit', '900'});
    tmp.InsertLast({'S_IntroMaxDuration', '15'});
    tmp.InsertLast({'S_QualificationsEndTime_MinMargin', '30000'});
    @tmp = scriptDefaults[GameMode::KnockoutDaily];
    @tmp = scriptDefaults[GameMode::COTDQualifications];
    @tmp = scriptDefaults[GameMode::MultiTeams];
    tmp.InsertLast({'S_TeamsNb', '10'});
    tmp.InsertLast({'S_PointsLimit', '50'});
    tmp.InsertLast({'S_FinishTimeout', '-1'});
    tmp.InsertLast({'S_RoundsPerMap', '-1'});
    tmp.InsertLast({'S_MapsPerMatch', '-1'});
    tmp.InsertLast({'S_UseTieBreak', 'true'});
    tmp.InsertLast({'S_WarmUpNb', '0'});
    tmp.InsertLast({'S_WarmUpDuration', '0'});
    tmp.InsertLast({'S_WarmUpTimeout', '-1'});
    @tmp = scriptDefaults[GameMode::HeadToHead];
    tmp.InsertLast({'S_ChatTime', '60'});
    tmp.InsertLast({'S_ForceLapsNb', '2'});
    tmp.InsertLast({'S_MatchPointsLimit', '3'});
    tmp.InsertLast({'S_MapPointsLimit', '3'});
    tmp.InsertLast({'S_NbOfWinners', '1'});
    tmp.InsertLast({'S_FinishTimeout', '10'});
    tmp.InsertLast({'S_WarmUpNb', '1'});
    tmp.InsertLast({'S_WarmUpDuration', '10'});
    tmp.InsertLast({'S_EnableWinScreen', 'false'});
    @tmp = scriptDefaults[GameMode::Final42TMGL];
    AddChampionSpring2022Defaults(scriptDefaults[GameMode::ChampionSpring2022]);
    AddChampionSpring2022Defaults(scriptDefaults[GameMode::CupClassic]);
    @tmp = scriptDefaults[GameMode::CupClassic];
    trace('tmp len: ' + tmp.Length);
    SetGameModeOptionInList(tmp, 'S_CupPointsLimit', '120');
    SetGameModeOptionInList(tmp, 'S_RoundsPerMap', '4');
    SetGameModeOptionInList(tmp, 'S_PointsRepartition', '10,6,4,3,2,1');
    SetGameModeOptionInList(tmp, 'S_NbOfWinners', '2');
    SetGameModeOptionInList(tmp, 'S_FinishTimeout', '15');
    return scriptDefaults;
}


void SetGameModeOptionInList(string[][]@ &in opts, const string &in name, const string &in value) {
    for (uint i = 0; i < opts.Length; i++) {
        if (opts[i][0] == name) {
            opts[i][1] = value;
        }
    }
}


void AddChampionSpring2022Defaults(string[][]@ &in opts) {
    opts.InsertLast({'S_MatchPointsLimit', '1'});
    opts.InsertLast({'S_CupPointsLimit', '1'});
    opts.InsertLast({'S_RoundsPerMap', '-1'});
    opts.InsertLast({'S_NbOfWinners', '1'});
    opts.InsertLast({'S_StopMatchIfNotEnoughPlayers', 'true'});
    opts.InsertLast({'S_FinishTimeout', '-1'});
    opts.InsertLast({'S_PointsRepartition', '"1'});
    opts.InsertLast({'S_MatchStyle', '0'});
    opts.InsertLast({'S_MatchType', '0'});
    opts.InsertLast({'S_MatchLevel', '0'});
    opts.InsertLast({'S_TrackNb', '0'});
    opts.InsertLast({'S_TracksTotal', '0'});
    opts.InsertLast({'S_KOCheckpointNb', '3'});
    opts.InsertLast({'S_KOCheckpointTime', '1000'});
    opts.InsertLast({'S_KOValidationDelay', '1000'});
    opts.InsertLast({'S_ChatTime', '600'});
    opts.InsertLast({'S_WarmUpNb', '0'});
    opts.InsertLast({'S_WarmUpDuration', '0'});
    opts.InsertLast({'S_WarmUpTimeout', '-1'});
    opts.InsertLast({'S_EnableAmbientSound', 'true'});
    opts.InsertLast({'S_HideScoresHeader', 'false'});
    opts.InsertLast({'S_EnableWinScreen', 'false'});
    opts.InsertLast({'S_EnablePreMatch', 'false'});
    opts.InsertLast({'S_ForceRoadSpectatorsNb', '-1'});
    opts.InsertLast({'S_EarlyEndMatchCallback', 'true'});
    opts.InsertLast({'S_EndRoundPreScoreUpdateDuration', '3'});
    opts.InsertLast({'S_EndRoundPostScoreUpdateDuration', '3'});
    opts.InsertLast({'S_DecoImageUrl_Screen16x9', 'file://Media/Manialinks/Nadeo/TMNext/Modes/Champion/Sponsors/Default.dds'});
    opts.InsertLast({'S_DecoImageUrl_Screen8x1', 'file://Media/Manialinks/Nadeo/TMNext/Modes/Champion/Stadium/Screen8x1.dds'});
    opts.InsertLast({'S_DecoImageUrl_Screen16x1', 'file://Media/Manialinks/Nadeo/TMNext/Modes/Champion/Stadium/Screen16x1.dds'});
    opts.InsertLast({'S_OverridePlayerProfiles', ''});
    opts.InsertLast({'S_LoadMatchState', ''});
    opts.InsertLast({'S_EnableTrophiesGain', 'false'});
    opts.InsertLast({'S_CompetitionName', ''});
    opts.InsertLast({'S_StepNb', '0'});
    opts.InsertLast({'S_MapWorldRecord', ''});
    opts.InsertLast({'S_SponsorsUrl', ''});
}



class GameOpt {
    string key, value, type;
    bool boolVal;
    int intVal;
    float floatVal;
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
        else if (type == "float") DrawFloatOpt(withLabel);
        else if (type == "text") DrawTextOpt(withLabel);
        else UI::Text("Unknown type: " + type + " for setting: " + key);
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

    protected void DrawFloatOpt(bool withLabel = true) {
        auto orig = floatVal;
        floatVal = UI::InputFloat(withLabel ? key : "##"+key, floatVal, 0.1);
        if (orig != floatVal) value = tostring(floatVal);
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
