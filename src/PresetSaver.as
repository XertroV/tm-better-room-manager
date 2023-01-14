namespace PresetSaver {
    bool active = false;
    CoroutineFunc@ cb = null;
    RoomTab@ currTab = null;

    void Open(CoroutineFunc@ callback, RoomTab@ tab) {
        active = true;
        @currTab = tab;
        @cb = callback;
        @presetFiles = array<string>();
        presetName = "";
        presetJson = Json::Object();
        RefreshPresets();
    }

    string[]@ presetFiles = null;

    void RefreshPresets() {
        string folder = IO::FromStorageFolder("presets/").Replace("\\", "/");
        @presetFiles = IO::IndexFolder(folder, true);
        for (uint i = 0; i < presetFiles.Length; i++) {
            presetFiles[i] = presetFiles[i].Replace("\\", "/").Replace(folder, "").Replace(".json", "");
        }
    }

    bool WindowOpen {
        get { return active; }
        set {
            if (!value) {
                presetName = "";
                OnChoosePreset();
            }
        }
    }

    void Render() {
        if (!active) return;
        UI::SetNextWindowSize(500, 300, UI::Cond::Appearing);
        if (UI::Begin("Save Preset", WindowOpen)) {
            DrawInner();
        }
        UI::End();
    }

    string presetName;
    float btnWidth = 100;

    void DrawInner() {
        bool presetExists = presetFiles.Find(presetName) >= 0;
        bool nameHasDot = presetName.Contains(".");
        SubHeading("Save current settings as:");
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        UI::BeginDisabled(presetName.Length == 0 || presetExists || nameHasDot);
        if (UI::Button("Save Preset")) OnChoosePreset();
        UI::EndDisabled();
        UI::Separator();
        bool changed = false;
        presetName = UI::InputText("Preset Name", presetName, changed);
        if (presetName.Length == 0) {
            UI::Text("\\$999Please enter a name");
        }
        if (presetExists) {
            UI::Text("\\$999Error: preset exists");
        }
        if (nameHasDot) {
            UI::Text("\\$999Error: name contains `.` (a period)");
        }
    }

    void DrawPresetSelectable(const string &in filename) {
        if (UI::Selectable(filename, presetName == filename)) {
            presetName = filename;
        }
    }

    Json::Value@ presetJson = Json::Object();

    void OnChoosePreset() {
        // todo: build presetJson
        if (presetName.Length > 0) {
            @presetJson = currTab.GenRoomConfigJson();
        } else {
            @presetJson = Json::Object();
        }
        startnew(LoadPresetAndCB);
        active = false;
        @currTab = null;
    }

    void LoadPresetAndCB() {
        if (presetName != "") {
            Json::ToFile(IO::FromStorageFolder("presets/" + presetName + ".json"), presetJson);
        }
        cb();
    }
}
