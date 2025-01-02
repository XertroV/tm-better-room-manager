namespace BRM {
    // Create an IRoomSettingsBuilder object for a given club and room
    import IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId) from "BRM";

    // Get the setting type (integer, bool, text) for a given setting, e.g., S_TimeLimit
    import string GetModeSettingType(const string &in settingName) from "BRM";

    // Join a server by getting the joinlink for a given club and room
    import void JoinServer(uint clubId, uint roomId, const string &in password = "") from "BRM";

    // Returns true if the client is connected to a server
    import bool IsInAServer(CGameCtnApp@ app) from "BRM";

    // Returns some basic info for the current server, including Club and Room IDs. Yields if waitForClubId=true otherwise might return null if club/room ID detection is still loading.
    import ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true) from "BRM";

    /** May yield. Returns a JSON Array of JSON Objects.
     *  The format is equivalent to under .clubList in the payload returned by <https://webservices.openplanet.dev/live/clubs/clubs-mine>
     *  There are some additional fields, like nameSafe, tagSafe, and isAdmin (dump the json object for everything)
    */
    import const Json::Value@ GetMyClubs() from "BRM";

    // Get a room info from the API. <https://webservices.openplanet.dev/live/clubs/room-by-id>
    import Json::Value@ GetRoomInfoFromAPI(uint clubId, uint roomId) from "BRM";

    // Create an INewsScoreBoardManager for creating news-based scoreboards
    import INewsScoreBoardManager@ CreateNewsScoreBoardManager(int clubId, const string &in serverName = "", bool autoCreateNews = false) from "BRM";

    // Get the game to download a map and put it in the cache.
	import void PreCacheMap(const string &in url) from "BRM";
}
