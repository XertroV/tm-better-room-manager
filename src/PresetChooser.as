funcdef void PresetChosenCallback(Json::Value@ preset);


namespace PresetChooser {
    bool active = false;
    PresetChosenCallback@ cb = null;

    void Open(PresetChosenCallback@ callback) {
        active = true;
        @cb = callback;
        @presetFiles = array<string>();
        chosenPreset = "";
        RefreshPresets();
    }

    string[]@ presetFiles = null;

    void RefreshPresets() {
        @presetFiles = IO::IndexFolder(IO::FromStorageFolder("presets"), true);
    }

    bool WindowOpen {
        get { return active; }
        set {
            if (!value) {
                chosenPreset = "";
                OnChoosePreset();
            }
        }
    }

    void Render() {
        if (!active) return;
        UI::SetNextWindowSize(500, 300, UI::Cond::Appearing);
        if (UI::Begin("Preset Chooser", WindowOpen)) {
            DrawInner();
        }
        UI::End();
    }

    string chosenPreset;
    float btnWidth = 100;

    void DrawInner() {
        SubHeading("Choose a preset:");
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        UI::BeginDisabled(chosenPreset.Length == 0);
        if (UI::Button("Choose Preset")) OnChoosePreset();
        btnWidth = UI::GetItemRect().z;
        UI::EndDisabled();

        if (presetFiles.Length == 0) {
            UI::Text("No presets found.");
            return;
        }

        if (UI::BeginChild('preset selectable scrollable')) {
            for (uint i = 0; i < presetFiles.Length; i++) {
                DrawPresetSelectable(presetFiles[i]);
            }
        }
        UI::EndChild();
    }

    void DrawPresetSelectable(const string &in filename) {
        if (UI::Selectable(filename, chosenPreset == filename)) {
            chosenPreset = filename;
        }
    }

    void OnChoosePreset() {
        // todo load preset
        startnew(LoadPresetAndCB);
        active = false;
    }

    void LoadPresetAndCB() {
        if (chosenPreset.Length == 0) {
            cb(null);
            return;
        }
        Json::Value@ preset = Json::FromFile(IO::FromStorageFolder("presets/" + chosenPreset));
        cb(preset);
    }
}
