namespace BRM {
    shared enum GameMode {
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

    // Returns a scirpt path, e.g., "TrackMania/TM_Cup_Online.Script.txt", for a given `BRM::GameMode`
    shared const string GameModeToFullModeString(GameMode m) {
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

    // Returns a `BRM::GameMode` based on the script path, e.g., "TrackMania/TM_Cup_Online.Script.txt"
    shared GameMode GameModeFromStr(const string &in modeStr) {
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


    shared interface IRoomSettingsBuilder {
        // Populate based on current room settings. This function may yield.
        IRoomSettingsBuilder@ GetCurrentSettingsAsync();

        // Set the room game mode
        IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false);

        // Whether a game mode setting exists (note: you probably want to call GetCurrentSettingsAsync first)
        bool HasModeSetting(const string &in key);

        // Gets a game mode setting's current value
        string GetModeSetting(const string &in key);

        // Set a game mode setting (e.g., S_TimeLimit)
        IRoomSettingsBuilder@ SetModeSetting(const string &in key, const string &in value);

        // Set the time limit (seconds)
        IRoomSettingsBuilder@ SetTimeLimit(int limit);

        // Set the chat time (seconds)
        IRoomSettingsBuilder@ SetChatTime(int ct);

        // Set the loading screen image URL
        IRoomSettingsBuilder@ SetLoadingScreenUrl(const string &in url);

        // This will yield! An easy 'go to next map' command for club rooms in TimeAttack mode. Duration is 5s + 2 http requests to nadeo.
        IRoomSettingsBuilder@ GoToNextMapAndThenSetTimeLimit(const string &in mapUid, int limit = -1, int ct = 1);

        // Set the rooms map list
        IRoomSettingsBuilder@ SetMaps(const array<string> &in maps);

        // Add a map to the rooms map list
        IRoomSettingsBuilder@ AddMaps(const array<string> &in maps);

        // Set the room player limit (1 - 100)
        IRoomSettingsBuilder@ SetPlayerLimit(uint limit);

        // Set the room name
        IRoomSettingsBuilder@ SetName(const string &in name);

        // Save the room; returns immediately
        IRoomSettingsBuilder@ SaveRoomInCoro();

        // saves the room and returns the result; will yield internally
        Json::Value@ SaveRoom();
    }

    shared class ServerInfo {
        string login;
        string name;
        int clubId = -1;
        int roomId = -1;
        bool isAdmin;

        ServerInfo(const string &in login, const string &in name, int clubId, int roomId, bool isAdmin) {
            this.login = login;
            this.name = name;
            this.clubId = clubId;
            this.roomId = roomId;
            this.isAdmin = isAdmin;
        }
    }
}
