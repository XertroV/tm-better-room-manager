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
        // unofficial but included ones -- note: do not change order!
        TMWTTeams = 8,
        TMWTMatchmaking = 9,
        TeamsMatchmaking = 10,
        TimeAttackDaily = 11,
        KnockoutDaily = 12,
        COTDQualifications = 13,
        CupClassic = 14,
        ChampionSpring2022 = 15,
        Royal = 16,
        TMWC2023 = 17,
        // Nov 20
        RoyalStars = 18,
        // unlisted modes
        MultiTeams = 19,
        HeadToHead = 20,
        Final42TMGL = 21,
        // more legacy
        CupLong = 22,
        CupShort = 23,
        RoundsBoulet = 24,
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
            // more legacy added june 2024
            case GameMode::CupLong: return "TrackMania/Legacy/TM_CupLong_Online.Script.txt";
            case GameMode::CupShort: return "TrackMania/Legacy/TM_CupShort_Online.Script.txt";
            case GameMode::RoundsBoulet: return "TrackMania/Legacy/TM_RoundsBoulet_Online.Script.txt";

            case GameMode::Royal: return "TrackMania/TM_Royal_Online.Script.txt";
            case GameMode::TMWC2023: return "TrackMania/TM_TMWC2023_Online.Script.txt";
            case GameMode::RoyalStars: return "TrackMania/TM_RoyalStars_Online.Script.txt";
            case GameMode::MultiTeams: return "TrackMania/Deprecated/TM_MultiTeams_Online.Script.txt";
            case GameMode::HeadToHead: return "TrackMania/Deprecated/TM_HeadToHead_Online.Script.txt";
            case GameMode::Final42TMGL: return "TrackMania/Deprecated/TM_Final42TMGL_Online.Script.txt";
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
        // more legacy added june 2024
        if (modeStr == "TrackMania/Legacy/TM_CupLong_Online.Script.txt") return GameMode::CupLong;
        if (modeStr == "TrackMania/Legacy/TM_CupShort_Online.Script.txt") return GameMode::CupShort;
        if (modeStr == "TrackMania/Legacy/TM_RoundsBoulet_Online.Script.txt") return GameMode::RoundsBoulet;

        if (modeStr == "TrackMania/TM_Royal_Online.Script.txt") return GameMode::Royal;
        if (modeStr == "TrackMania/TM_TMWC2023_Online.Script.txt") return GameMode::TMWC2023;
        if (modeStr == "TrackMania/TM_RoyalStars_Online.Script.txt") return GameMode::RoyalStars;
        // unlisted
        if (modeStr == "TrackMania/Deprecated/TM_MultiTeams_Online.Script.txt") return GameMode::MultiTeams;
        if (modeStr == "TrackMania/Deprecated/TM_HeadToHead_Online.Script.txt") return GameMode::HeadToHead;
        if (modeStr == "TrackMania/Deprecated/TM_Final42TMGL_Online.Script.txt") return GameMode::Final42TMGL;
        // default
        return GameMode::Unknown;
    }


    shared interface IRoomSettingsBuilder {
        // Populate based on current room settings. This function may yield.
        IRoomSettingsBuilder@ LoadCurrentSettingsAsync();

        // Get the current raw settings json object (which is mutable). Call LoadCurrentSettingsAsync first to load current settings.
        Json::Value@ GetCurrentSettingsJson();

        // Gets the room's current game mode
        GameMode GetMode( );

        // Set the room game mode
        IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false);

        // Whether a game mode setting exists (note: you probably want to call LoadCurrentSettingsAsync first)
        bool HasModeSetting(const string &in key);

        // Gets a game mode setting's current value. Throws if it does not exist.
        string GetModeSetting(const string &in key);

        // Set a game mode setting (e.g., S_TimeLimit)
        IRoomSettingsBuilder@ SetModeSetting(const string &in key, const string &in value);

        // Get the time limit (or -1 if it's absent)
        int GetTimeLimit( );

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

    shared interface INewsScoreBoardManager {
        // Get the news activity id
        int get_NewsActivityId( );

        // Get the associated room/server name
        string get_ServerName( );

        // Get the news name
        string get_NewsName( );

        // Get a section of the scoreboard (heading + 12 entries typical for each column)
        INewsScoreBoardSection@ GetOrCreateSection(const string &in sectionName);

        // Get a section of the scoreboard (heading + 12 entries typical for each column)
        INewsScoreBoardSection@ GetSection(const string &in sectionName);

        // Remove all sections
        void DeleteAllSections( );

        // Clear each section of all entries
        void ClearAllEntries( );

        // Find or create the news activity -- required to call this before update if autocreate was false; will block. can be called more than once and will immediately return in that case.
        void EnsureNewsActivityCreatedAsync( );

        // Save the scoreboard; will block
        void UpdateNewsAsync( );

        // Save the scoreboard; launch a coroutine
        void UpdateNewsInBg( );
    }

    shared interface INewsScoreBoardSection {
        // Get the section name
        string get_SectionName( );

        // Get the section entries
        array<INewsScoreBoardEntry@>@ get_Entries();

        // Add an entry to the section
        void AddEntry(int rank, const string &in name, int wrs = -1, int ats = -1, int golds = -1, int mapsPlayed = -1);

        // Clear all entries from the section
        void ClearEntries( );

        // Get the section as a string suitable for news
        string ToNewsString( );
    }

    shared interface INewsScoreBoardEntry {
        // Get the rank
        int get_Rank( );

        // Get the name
        string get_Name( );

        // Get # world records
        int get_WRs( );

        // Get # author times
        int get_ATs( );

        // Get # golds
        int get_Golds( );

        // Get # maps played
        int get_MapsPlayed( );

        // Get the entry as a string suitable for news
        string ToNewsString( );
    }
}
