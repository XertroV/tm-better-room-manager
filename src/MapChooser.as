funcdef void MapChosenCallback(LazyMap@[]@ maps);


namespace MapChooser {
    bool active = false;
    MapChosenCallback@ cb = null;

    CGameCtnChallengeInfo@[]@ knownMaps = null;
    CGameCtnChallengeInfo@[]@ filteredMaps = null;
    CGameCtnChallengeInfo@ chosenMap = null;

    string filterString;
    bool loading = false;

    Folder@ CurrentFolder = null;
    Folder@[] FolderStack;

    void Open(MapChosenCallback@ callback) {
        active = true;
        loading = true;
        @cb = callback;
        @knownMaps = array<CGameCtnChallengeInfo@>();
        @filteredMaps = array<CGameCtnChallengeInfo@>();
        filterString = "";
        @chosenMap = null;
        tmxIds = "";
        auto app = cast<CGameManiaPlanet>(GetApp());
        // only refresh maps if we do not have a map loaded
        if (app !is null && app.CurrentPlayground is null && app.Editor is null && app.RootMap is null) {
            cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr.Map_RefreshFromDisk();
        }
        @CurrentFolder = null;
        FolderStack.RemoveRange(0, FolderStack.Length);
        startnew(RefreshMaps);
        startnew(LoadCurrentFolder);
    }

    void LoadCurrentFolder() {
        @CurrentFolder = Folder("Maps", Map_GetFilteredGameList(4, "", false, false, false));
    }

    void RefreshMaps() {
        auto app = GetApp();
        for (uint i = 0; i < app.ChallengeInfos.Length; i++) {
            auto map = app.ChallengeInfos[i];
            if (map.MapUid == "") continue;
            if (!map.IsPlayable) continue;
            knownMaps.InsertLast(map);
        }
        OnClickResetFilter();
        loading = false;
    }

    uint nbFiltered = 0;
    string[]@ searchParts;
    string mapNameClean;

    auto inputFilterFlags =
        UI::InputTextFlags::AutoSelectAll |
        UI::InputTextFlags::CallbackAlways |
        UI::InputTextFlags::CallbackCharFilter |
        UI::InputTextFlags::CallbackCompletion |
        UI::InputTextFlags::CallbackHistory;

    void FilterMaps(UI::InputTextCallbackData@ data) {
        if (data.Text == "") {
            OnClickResetFilter();
            return;
        }
        auto @searchParts = data.Text.ToLower().Split("*");
        filteredMaps.RemoveRange(0, filteredMaps.Length);
        for (uint i = 0; i < knownMaps.Length; i++) {
            auto map = knownMaps[i];
            mapNameClean = Text::StripFormatCodes(map.Name).ToLower();
            bool match = true;
            for (uint p = 0; p < searchParts.Length; p++) {
                if (!mapNameClean.Contains(searchParts[p])) {
                    match = false;
                    break;
                }
            }
            if (!match) continue;
            filteredMaps.InsertLast(map);
        }
        nbFiltered = filteredMaps.Length;
    }

    void OnClickResetFilter() {
        filterString = "";
        filteredMaps.Resize(knownMaps.Length);
        for (uint i = 0; i < knownMaps.Length; i++) {
            @filteredMaps[i] = knownMaps[i];
        }
        nbFiltered = filteredMaps.Length;
    }

    bool WindowOpen {
        get { return active; }
        set {
            if (!value) {
                @chosenMap = null;
                OnChooseMap();
            }
        }
    }

    vec2 framePadding;
    void Render() {
        if (!active) return;
        framePadding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);
        UI::SetNextWindowSize(550, 350, UI::Cond::Appearing);
        if (UI::Begin("Map Chooser", WindowOpen)) {
            UI::BeginDisabled(loading);
            UI::BeginTabBar("map-chooser-tabs", UI::TabBarFlags::None);
            if (UI::BeginTabItem(Icons::FolderOpenO + " From Folder")) {
                DrawChooseFolderInner();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("From TMX")) {
                DrawTmxInner();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Local Maps Search")) {
                DrawInner();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("By UID")) {
                DrawByUIDInner();
                UI::EndTabItem();
            }
            UI::EndTabBar();
            UI::EndDisabled();
        }
        UI::End();
    }

    float chooseFolderBtnWidth = 200;
    void DrawChooseFolderInner() {
        SubHeading("Choose a Folder");
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - chooseFolderBtnWidth, UI::GetCursorPos().y));
        auto pos = UI::GetCursorPos();
        ControlButton(Icons::CheckSquareO + " All", OnClickSelectAll);
        ControlButton(Icons::CheckSquareO + " None", OnClickSelectNone);
        ControlButton(Icons::Refresh + "##refresh folders", OnClickRefreshMapsFromDisk_Async);
        ControlButton("Add Maps (" + (CurrentFolder is null ? -1 : CurrentFolder.nbSelected) + ")", OnClickAddMapsFromFolder);
        chooseFolderBtnWidth = UI::GetCursorPos().x - pos.x - framePadding.x * 2.;
        UI::Dummy(vec2());
        UI::Separator();
        if (UI::BeginChild("choose folder scollable")) {
            DrawFolderSelector();
        }
        UI::EndChild();
    }

    void OnClickSelectAll() {
        CurrentFolder.SelectAll();
    }

    void OnClickSelectNone() {
        CurrentFolder.SelectNone();
    }

    void DrawFolderSelector() {
        if (CurrentFolder is null) {
            UI::Text("Loading...");
            return;
        }

        if (GetApp().ChallengeInfos.Length == 0) return;
        // auto root = GetApp().ChallengeInfos[0].Fids.ParentFolder;

        UI::SetNextItemOpen(true, UI::Cond::Always);
        CurrentFolder.DrawTree();
    }

    void OnClickAddMapsFromFolder() {
        loading = true;
        auto maps = CurrentFolder.OnClickAddSelectedMaps();
        Meta::PluginCoroutine@[] coros;
        for (uint i = 0; i < maps.Length; i++) {
            coros.InsertLast(startnew(CheckMapIsUploadedAndUploadIfNot_Coro, array<string> = {maps[i]}));
        }
        await(coros);
        LazyMap@[] ret;
        for (uint i = 0; i < maps.Length; i++) {
            ret.InsertLast(LazyMap(maps[i]));
        }
        startnew(CoroutineFuncUserdata(RunCallbackMulti), ret);
        loading = false;
        active = false;
    }

    void OnClickRefreshMapsFromDisk_Async() {
        @CurrentFolder = null;
        Map_RefreshFromDisk();
        yield();
        LoadCurrentFolder();
    }

    string tmxIds;
    string tmxMapPackId;
    void DrawTmxInner() {
        if (!loading) {
            SubHeading("\\$fa7Note:\\$z If a map upload is required, you'll be returned to the main menu.");
        } else {
            UI::ProgressBar(tmxDone / tmxTotal, vec2(-1, 0), "Loading Maps...");
        }
        UI::Separator();
        SubHeading("TMX Track IDs (comma separated)");
        bool changed = false;
        tmxIds = UI::InputTextMultiline("##tmx-ids", tmxIds, changed, vec2(UI::GetContentRegionMax().x - UI::GetStyleVarVec2(UI::StyleVar::WindowPadding).x, UI::GetTextLineHeightWithSpacing() * 3));
        if (UI::Button("Add maps from TMX via TrackIDs")) OnClickAddMapsTmxTrackIds();
        UI::Separator();
        SubHeading("TMX Map Pack ID (only first 100 maps will be added)");
        tmxMapPackId = UI::InputText("##tmx-map-pack-id", tmxMapPackId);
        if (UI::Button("Add maps from Map Pack via ID")) startnew(OnClickAddMapsTmxMapPack);
    }

    string m_uid;
    void DrawByUIDInner() {
        SubHeading("Map UID");
        UI::AlignTextToFramePadding();
        UI::TextWrapped("Warning: This will not check if the map is uploaded to Nadeo. Non-uploaded maps can cause softlocks.");
        bool changed = false;
        m_uid = UI::InputText("Map UID##map-uid", m_uid, changed, UI::InputTextFlags::EnterReturnsTrue);
        if (UI::Button("Add map by UID") || changed) {
            m_uid = m_uid.Trim();
            if (m_uid.Length < 25 || m_uid.Length > 27) {
                NotifyWarning("Invalid UID: " + m_uid + ", length: " + m_uid.Length);
            } else {
                cb({LazyMap(m_uid)});
                active = false;
                // can't yield
                // if (!IsMapUploadedToNadeo(m_uid)) {
                //     NotifyWarning("Map with UID " + m_uid + " is not uploaded to Nadeo.");
                // } else {
                // }
            }
        }
    }

    void OnClickAddMapsTmxTrackIds() {
        loading = true;
        auto parts = tmxIds.Split(",");
        string[] trackIds;
        for (uint i = 0; i < parts.Length; i++) {
            auto s = parts[i].Trim();
            if (s.Length > 0)
                trackIds.InsertLast(s);
        }
        startnew(CoroutineFuncUserdata(AddMapsFromTmxIds), trackIds);
    }

    // Json::Value@[] tmpMapsTmx;

    // total (max) number of operations
    float tmxTotal = 1;
    // increment when we do one of the operations
    float tmxDone = 0;

    void AddMapsFromTmxIds(ref@ r) {
        auto trackIds = cast<string[]>(r);
        // tmpMapsTmx.RemoveRange(0, tmpMapsTmx.Length);
        tmxTotal = trackIds.Length * 2.;
        tmxDone = 0;
        // get maps from tmx
        uint chunkSize = 25;
        string[] uids;
        int[] tids;
        for (uint i = 0; i < trackIds.Length; i += chunkSize) {
            auto @chunk = Slice(trackIds, i, i + chunkSize);
            Json::Value@ tracks = GetMapsByTrackIDs(chunk);
            for (uint t = 0; t < tracks.Length; t++) {
                auto track = tracks[t];
                uids.InsertLast(track['TrackUID']);
                tids.InsertLast(track['TrackID']);
            }
            tmxDone += chunk.Length;
        }

        EnsureMapsHelper(tids, uids);
        tmxDone += tids.Length;
        // add lazy map
        LazyMap@[] ret;
        for (uint i = 0; i < uids.Length; i++) {
            ret.InsertLast(LazyMap(uids[i]));
        }
        startnew(CoroutineFuncUserdata(RunCallbackMulti), ret);
        loading = false;
        active = false;
    }

    void OnClickAddMapsTmxMapPack() {
        loading = true;
        tmxTotal = 1;
        tmxDone = 0;
        auto mpMaps = GetMapsFromMapPackId(tmxMapPackId);
        while (mpMaps.Length > 100) {
            mpMaps.Remove(mpMaps.Length - 1);
        }
        tmxTotal = mpMaps.Length * 2.;
        tmxDone = mpMaps.Length;

        string[] uids;
        int[] tids;
        for (uint i = 0; i < mpMaps.Length; i++) {
            auto track = mpMaps[i];
            uids.InsertLast(track['TrackUID']);
            tids.InsertLast(track['TrackID']);
        }

        EnsureMapsHelper(tids, uids);
        tmxDone = tmxTotal;
        // add lazy map
        LazyMap@[] ret;
        for (uint i = 0; i < uids.Length; i++) {
            ret.InsertLast(LazyMap(uids[i]));
        }
        startnew(CoroutineFuncUserdata(RunCallbackMulti), ret);
        loading = false;
        active = false;

        loading = false;
    }

    float btnWidth = 100;

    void DrawInner() {
        SubHeading("Filter Maps:");
        UI::SameLine();

        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        auto pos = UI::GetCursorPos();
        UI::BeginDisabled(chosenMap is null);
        ControlButton("Choose Map", OnChooseMap);
        UI::EndDisabled();
        btnWidth = UI::GetCursorPos().x - pos.x;
        UI::Dummy(vec2());

        bool changed = false;
        filterString = UI::InputText("##filter maps", filterString, changed, inputFilterFlags, FilterMaps);
        UI::SameLine();
        ControlButton(Icons::Times + "##reset map filter", OnClickResetFilter);
        UI::Dummy(vec2());

        if (filteredMaps.Length == 0) {
            UI::Text("No maps found.");
            return;
        }

        if (UI::BeginChild('map selectable scrollable')) {
            UI::ListClipper clipMaps(filteredMaps.Length);
            while (clipMaps.Step()) {
                for (int i = clipMaps.DisplayStart; i < clipMaps.DisplayEnd; i++) {
                    DrawMapSelectable(filteredMaps[i]);
                }
            }
        }
        UI::EndChild();
    }

    void DrawMapSelectable(CGameCtnChallengeInfo@ map) {
        if (UI::Selectable(Text::OpenplanetFormatCodes(map.Name), chosenMap !is null && chosenMap.Id.Value == map.Id.Value)) {
            @chosenMap = map;
        }
    }

    void OnChooseMap() {
        startnew(RunCallback);
        active = false;
    }

    void RunCallback() {
        if (cb is null) throw('RunCallback: null callback');
        if (chosenMap is null) {
            cb(null);
            return;
        }
        if (!IsMapUploadedToNadeo(chosenMap.MapUid)) {
            UploadMapToNadeo(chosenMap.MapUid);
        }
        cb({LazyMap(chosenMap.MapUid)});
    }

    void RunCallbackMulti(ref@ maps) {
        if (cb is null) throw('RunCallbackMulti: null callback');
        cb(cast<LazyMap@[]>(maps));
    }


    class Folder {
        string[] SubFolders;
        CGameCtnChallengeInfo@[] MapInfos;
        Folder@ Parent = null;
        string Name;
        bool[] selected;
        string[] MapNames;
        int nbSelected = 0;

        Folder(const string &in name, CWebServicesTaskResult_MapListScript@ resp, Folder@ parent = null) {
            Name = name;
            @Parent = parent;
            for (uint i = 0; i < resp.SubFolders.Length; i++) {
                SubFolders.InsertLast(resp.SubFolders[i]);
            }
            for (uint i = 0; i < resp.MapInfos.Length; i++) {
                if (!resp.MapInfos[i].IsPlayable) continue;
                auto @mapInfo = resp.MapInfos[i];
                MapInfos.InsertLast(mapInfo);
                selected.InsertLast(true);
                MapNames.InsertLast(Text::OpenplanetFormatCodes(mapInfo.NameForUi));
            }
            nbSelected = selected.Length;
        }

        void SelectAll() {
            for (uint i = 0; i < selected.Length; i++) {
                selected[i] = true;
            }
            nbSelected = selected.Length;
        }

        void SelectNone() {
            for (uint i = 0; i < selected.Length; i++) {
                selected[i] = false;
            }
            nbSelected = 0;
        }

        void DrawTree() {
            DrawOpenTreeNode(DrawTreeInnerF(DrawTreeInner));
        }

        void DrawTreeInner() {
            for (uint i = 0; i < SubFolders.Length; i++) {
                UI::SetNextItemOpen(false, UI::Cond::Always);
                UI::AlignTextToFramePadding();
                auto clicked = UI::TreeNode(SubFolders[i]);
                if (clicked) {
                    UI::TreePop();
                    startnew(CoroutineFuncUserdata(OnChooseSubfolder), array<string> = {SubFolders[i]});
                }
            }
            for (uint i = 0; i < MapInfos.Length; i++) {
                DrawMapInfo(i);
            }
        }

        void OnChooseSubfolder(ref@ r) {
            auto sf = cast<string[]>(r)[0];
            @CurrentFolder = null;
            @CurrentFolder = Folder(sf, Map_GetFilteredGameList(4, sf, false, false, false), this);
        }

        void DrawMapInfo(int i) {
            UI::AlignTextToFramePadding();
            UI::SetCursorPos(UI::GetCursorPos() + vec2(framePadding.x, 0));
            DrawMapSelector(i);
        }

        // for use in folders
        void DrawMapSelector(int i) {
            bool _curr = selected[i];
            if (_curr != UI::Checkbox(MapNames[i], _curr)) {
                selected[i] = !_curr;
                nbSelected += _curr ? -1 : 1;
            }
        }

        DrawTreeInnerF@ treeCb;
        void DrawOpenTreeNode(DrawTreeInnerF@ inner) {
            @treeCb = inner;
            if (Parent is null) DrawOpenTreeNodeInner();
            else Parent.DrawOpenTreeNode(DrawTreeInnerF(DrawOpenTreeNodeInner));
        }

        void DrawOpenTreeNodeInner() {
            bool cannotBeClosed = Parent is null;
            UI::AlignTextToFramePadding();
            if (cannotBeClosed || UI::TreeNode(Name, UI::TreeNodeFlags::DefaultOpen)) {
                treeCb();
                if (!cannotBeClosed) UI::TreePop();
            } else if (!cannotBeClosed) {
                // if we were closed, open the parent folder.
                @CurrentFolder = Parent;
            } else {
            }
        }

        string[]@ OnClickAddSelectedMaps() {
            string[] ret;
            for (uint i = 0; i < MapInfos.Length; i++) {
                if (selected[i]) ret.InsertLast(MapInfos[i].MapUid);
            }
            return ret;
        }
    }

    funcdef void DrawTreeInnerF();
    funcdef void DrawOpenTreeNodeInnerF();
}
