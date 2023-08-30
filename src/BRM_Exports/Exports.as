namespace BRM {
    import IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId) from "BRM";
    import string GetModeSettingType(const string &in settingName) from "BRM";

    import void JoinServer(uint clubId, uint roomId, const string &in password = "") from "BRM";

    import bool IsInAServer(CGameCtnApp@ app) from "BRM";
    import ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true) from "BRM";

    /** May yield. Returns a JSON Array of JSON Objects.
     *  The format is equivalent to under .clubList in the payload returned by <https://webservices.openplanet.dev/live/clubs/clubs-mine>
     *  There are some additional fields, like nameSafe, tagSafe, and isAdmin (dump the json object for everything)
    */
    import const Json::Value@ GetMyClubs() from "BRM";
}
