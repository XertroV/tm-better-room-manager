string[]@ GetClubTags(string[]@ wsids) {

    MwFastBuffer<wstring> _wsidList = MwFastBuffer<wstring>();
    for (uint i = 0; i < wsids.Length; i++) {
        _wsidList.Add(wstring(wsids[i]));
    }
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Tag_GetClubTagList(userId, _wsidList);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr);
    if (resp.HasFailed || !resp.HasSucceeded) {
        throw('getting club tags failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
    }
    string[] tags;
    for (uint i = 0; i < wsids.Length; i++) {
        tags.InsertLast(resp.GetClubTag(wsids[i]));
    }
    return tags;
}

string[]@ GetDisplayNames(string[]@ wsids) {
    MwFastBuffer<wstring> _wsidList = MwFastBuffer<wstring>();
    for (uint i = 0; i < wsids.Length; i++) {
        _wsidList.Add(wstring(wsids[i]));
    }
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.GetDisplayName(userId, _wsidList);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr);
    if (resp.HasFailed || !resp.HasSucceeded) {
        throw('getting club tags failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
    }
    string[] names;
    for (uint i = 0; i < wsids.Length; i++) {
        names.InsertLast(resp.GetDisplayName(wsids[i]));
    }
    return names;
}


const string LocalAccountId {
    get {
        return cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.LocalUser.WebServicesUserId;
    }
}


const string CurrentMapUid {
    get {
        auto m = GetApp().RootMap;
        if (m is null) return "";
        return m.EdChallengeId;
    }
}


// Do not keep handles to this object around
CMapRecord@ GetMyPbOnMap(const string &in mapUid) {
    return GetPlayersRecordOnMap(mapUid, LocalAccountId);
}

// Do not keep handles to this object around
CMapRecord@ GetPlayersRecordOnMap(const string &in mapUid, const string &in wsid) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto wsids = MwFastBuffer<wstring>();
    wsids.Add(wsid);
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.ScoreMgr.Map_GetPlayerListRecordList(userId, wsids, mapUid, "PersonalBest", "", "TimeAttack", "");
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.ScoreMgr);
    if (resp.HasFailed || !resp.HasSucceeded) {
        throw('GetMyPbOnMap failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
    }
    if (resp.MapRecordList.Length == 0) return null;
    return resp.MapRecordList[0];
}


// Do not keep handles to these objects around
CNadeoServicesMap@ GetMapFromUid(const string &in mapUid) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_NadeoServices_GetFromUid(userId, mapUid);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr);
    if (resp.HasFailed || !resp.HasSucceeded) {
        throw('GetMapFromUid failed: ' + resp.ErrorCode + ", " + resp.ErrorType + ", " + resp.ErrorDescription);
    }
    return resp.Map;
}



void UploadMapToNadeo(const string &in mapUid) {
    if (!Permissions::CreateAndUploadMap()) return;
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto userId = app.MenuManager.MenuCustom_CurrentManiaApp.UserMgr.Users[0].Id;
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_NadeoServices_Register(userId, mapUid);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr);
    return;
}



// uint Get_MapLeaderBoard_PlayerCount(const string &in uid) {
//     auto app = cast<CGameManiaPlanet>(GetApp());
//     return app.MenuManager.MenuCustom_CurrentManiaApp.ScoreMgr.MapLeaderBoard_GetPlayerCount(uid, "", "Global");
// }

// uint Get_GlobalLeaderBoard_PlayerCount() {
//     auto app = cast<CGameManiaPlanet>(GetApp());
//     return app.MenuManager.MenuCustom_CurrentManiaApp.ScoreMgr.GlobalLeaderBoard_GetPlayerCount("Global");
// }


/***
 *
 * Do not keep handles to this object around! use immediately.
 *
 * Scopes:
 *  #Const C_BrowserFilter_GameData 1
    #Const C_BrowserFilter_TitleData 2
    #Const C_BrowserFilter_GameAndTitleData 3
    #Const C_BrowserFilter_UserData 4
    #Const C_BrowserFilter_AllData 7
 */
CWebServicesTaskResult_MapListScript@ Map_GetFilteredGameList(uint scope, const string &in path, bool flatten, bool sortByNameElseDate, bool sortOrderAsc) {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto resp = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_GetFilteredGameList(scope, path, flatten, sortByNameElseDate, sortOrderAsc);
    WaitAndClearTaskLater(resp, app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr);
    return resp;
}

void Map_RefreshFromDisk() {
    // crashes in a server
    ReturnToMenu();
    auto app = cast<CGameManiaPlanet>(GetApp());
    app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_RefreshFromDisk();
}
