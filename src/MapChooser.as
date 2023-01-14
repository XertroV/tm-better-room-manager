funcdef void MapChosenCallback(LazyMap@ map);


namespace MapChooser {
    bool active = false;
    MapChosenCallback@ cb = null;

    CGameCtnChallengeInfo@[]@ knownMaps = null;
    CGameCtnChallengeInfo@[]@ filteredMaps = null;
    CGameCtnChallengeInfo@ chosenMap = null;

    string filterString;

    void Open(MapChosenCallback@ callback) {
        active = true;
        @cb = callback;
        @knownMaps = array<CGameCtnChallengeInfo@>();
        @filteredMaps = array<CGameCtnChallengeInfo@>();
        filterString = "";
        @chosenMap = null;
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
                if (!mapNameClean.Contains(searchParts[0])) {
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
        UI::SetNextWindowSize(500, 300, UI::Cond::Appearing);
        if (UI::Begin("Map Chooser", WindowOpen)) {
            DrawInner();
        }
        UI::End();
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
        cb(LazyMap(chosenMap.MapUid));
    }
}
