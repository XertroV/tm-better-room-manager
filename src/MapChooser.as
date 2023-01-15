funcdef void MapChosenCallback(LazyMap@[]@ maps);


namespace MapChooser {
    bool active = false;
    MapChosenCallback@ cb = null;

    CGameCtnChallengeInfo@[]@ knownMaps = null;
    CGameCtnChallengeInfo@[]@ filteredMaps = null;
    CGameCtnChallengeInfo@ chosenMap = null;

    string filterString;
    bool loading = false;

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
        startnew(RefreshMaps);
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
            mapNameClean = StripFormatCodes(map.Name).ToLower();
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

    void Render() {
        if (!active) return;
        UI::SetNextWindowSize(550, 350, UI::Cond::Appearing);
        if (UI::Begin("Map Chooser", WindowOpen)) {
            UI::BeginDisabled(loading);
            UI::BeginTabBar("map-chooser-tabs", UI::TabBarFlags::None);
            if (UI::BeginTabItem("Local Maps")) {
                DrawInner();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("From TMX")) {
                DrawTmxInner();
                UI::EndTabItem();
            }
            UI::EndTabBar();
            UI::EndDisabled();
        }
        UI::End();
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
        SubHeading("TMX Map Pack (only first 100 maps)");
        tmxMapPackId = UI::InputText("##tmx-map-pack-id", tmxMapPackId);
        if (UI::Button("Add maps from Map Pack")) startnew(OnClickAddMapsTmxMapPack);
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
                for (uint i = clipMaps.DisplayStart; i < clipMaps.DisplayEnd; i++) {
                    DrawMapSelectable(filteredMaps[i]);
                }
            }
        }
        UI::EndChild();
    }

    void DrawMapSelectable(CGameCtnChallengeInfo@ map) {
        if (UI::Selectable(ColoredString(map.Name), chosenMap !is null && chosenMap.Id.Value == map.Id.Value)) {
            @chosenMap = map;
        }
    }

    void OnChooseMap() {
        startnew(RunCallback);
        active = false;
    }

    void RunCallback() {
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
        cb(cast<LazyMap@[]>(maps));
    }
}
