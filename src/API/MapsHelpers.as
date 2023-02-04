void EnsureMapsHelper(int[] &in tids, string[] &in uids) {
    // string[] uids;
    MwFastBuffer<wstring> mapUidList = MwFastBuffer<wstring>();
    // int[] tids;
    for (uint i = 0; i < uids.Length; i++) {
        mapUidList.Add(string(uids[i]));
    }
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto cma = app.MenuManager.MenuCustom_CurrentManiaApp;
    auto dfm = cma.DataFileMgr;
    auto getMaps = dfm.Map_NadeoServices_GetListFromUid(cma.UserMgr.Users[0].Id, mapUidList);
    WaitAndClearTaskLater(getMaps, dfm);
    if (getMaps.HasFailed) {
        NotifyError("Failed to get map info from nadeo: " + getMaps.ErrorCode + ", " + getMaps.ErrorType + ", " + getMaps.ErrorDescription);
        return;
    }
    if (getMaps.IsCanceled) {
        NotifyError("Get maps info from nadeo was canceled. :(");
        return;
    }
    if (!getMaps.HasSucceeded) {
        throw("EnsureMapsHelper unknown state! not processing, not failed, not success. ");
    }

    for (uint i = 0; i < getMaps.MapList.Length; i++) {
        auto item = getMaps.MapList[i];
        auto ix = uids.Find(item.Uid);
        if (ix >= 0) {
            uids.RemoveAt(ix);
            tids.RemoveAt(ix);
        }
    }
    // uids and tids are now only unknown maps
    if (uids.IsEmpty()) return;

    if (!Permissions::CreateAndUploadMap()) {
        NotifyError("Refusing to upload maps because you are missing the CreateAndUploadMap permissions.");
        return;
    }

    ReturnToMenu();

    warn("Getting maps that aren't uploaded to nadeo services: " + string::Join(uids, ", "));
    // request all the maps
    Meta::PluginCoroutine@[] coros;
    for (uint i = 0; i < uids.Length; i++) {
        auto uid = uids[i];
        auto tid = tids[i];
        auto coro = startnew(DownloadMapAndUpload, MapUidTidData(uid, tid));
        coros.InsertLast(coro);
    }
    await(coros);
    warn("Finished uploading maps.");
}

void DownloadMapAndUpload(ref@ data) {
    MapUidTidData@ pl = cast<MapUidTidData>(data);
    if (pl is null) {
        warn("DownloadMapAndUpload got a null payload!");
        return;
    }
    if (!IsMapUploadedToNadeo(pl.uid)) {
        DownloadTmxMapToLocal(pl.tid);
        UploadMapFromLocal(pl.uid);
    }
}

class MapUidTidData {
    int tid;
    string uid;
    MapUidTidData(const string &in uid, int tid) {
        this.tid = tid;
        this.uid = uid;
    }
}

// Ends in a slash
const string GetLocalTmxMapFolder() {
    return IO::FromUserGameFolder('Maps/BetterRoomMgr-TMX/');
}

const string GetLocalTmxMapPath(int TrackID) {
    auto tmxFolder = GetLocalTmxMapFolder();
    if (!IO::FolderExists(tmxFolder))
        IO::CreateFolder(tmxFolder, true);
    return tmxFolder + TrackID + '.Map.Gbx';
}

void DownloadTmxMapToLocal(int TrackID) {
    auto outFile = GetLocalTmxMapPath(TrackID);
    if (IO::FileExists(outFile)) return;
    string url = MapUrlTmx(TrackID);
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("Error downloading TMX map to local: " + req.Error());
        @req = PluginGetRequest(MapUrlCgf(TrackID));
        req.Start();
        while (!req.Finished()) yield();
        if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
            warn("Error downloading TMX map from mirror to local: " + req.Error());
            NotifyWarning("Failed to download map with TrackID: " + TrackID);
            return;
        }
    }
    req.SaveToFile(outFile);
    trace('Saved tmx map ' + TrackID + ' to ' + outFile);
}

void UploadMapFromLocal(const string &in uid) {
    if (!Permissions::CreateAndUploadMap()) {
        NotifyError("Refusing to upload maps because you are missing the CreateAndUploadMap permissions.");
        return;
    }
    trace('UploadMapFromLocal: ' + uid);
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto cma = app.MenuManager.MenuCustom_CurrentManiaApp;
    auto dfm = cma.DataFileMgr;
    auto userId = cma.UserMgr.Users[0].Id;
    // back to menu so we can refresh maps
    ReturnToMenu();
    AwaitManialinkTitleReady();
    yield();
    // Do not run from within a map; will cause a script error (Map.MapInfo.MapUid is undefined, and lots of angelscript exceptions, too)
    dfm.Map_RefreshFromDisk();
    trace('UploadMapFromLocal: refreshed maps, attempting upload');
    yield();
    auto regScript = dfm.Map_NadeoServices_Register(userId, uid);
    WaitAndClearTaskLater(regScript, dfm);
    if (regScript.HasFailed) {
        warn("UploadMapFromLocal: Uploading map failed: " + regScript.ErrorType + ", " + regScript.ErrorCode + ", " + regScript.ErrorDescription);
        return;
    }
    if (regScript.HasSucceeded) {
        trace("UploadMapFromLocal: Map uploaded: " + uid);
    }
}


void ReturnToMenu() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    if (app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed) {
        app.Network.PlaygroundInterfaceScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Quit);
    } else {
        app.BackToMainMenu();
    }
    WaitForMainMenuToHaveFocus();
    AwaitManialinkTitleReady();
}

void WaitForMainMenuToHaveFocus() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    while (app.Switcher.ModuleStack.Length == 0 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) is null) yield();
}

void AwaitManialinkTitleReady() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    while (!app.ManiaTitleControlScriptAPI.IsReady) yield();
}

void CheckMapIsUploadedAndUploadIfNot_Coro(ref@ r) {
    auto uid = cast<array<string>>(r)[0];
    if (!IsMapUploadedToNadeo(uid)) {
        UploadMapFromLocal(uid);
    }
}
