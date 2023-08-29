funcdef void ScriptOptChosenCallback(GameOpt@ go);


namespace ScriptOptChooser {
    bool active = false;
    ScriptOptChosenCallback@ cb = null;
    GameOpt@[]@ filterOut;
    BRM::GameMode mode = BRM::GameMode::Unknown;

    bool Open(ScriptOptChosenCallback@ callback, GameOpt@[]@ existing, BRM::GameMode _mode) {
        if (active) return false;
        active = true;
        mode = _mode;
        @filterOut = existing;
        @cb = callback;
        chosenKey = "";
        RefreshAvailableGameOpts();
        return true;
    }

    string[] chooseFrom;

    void RefreshAvailableGameOpts() {
        dictionary known;
        chooseFrom.RemoveRange(0, chooseFrom.Length);
        for (uint i = 0; i < filterOut.Length; i++) {
            known[filterOut[i].key] = true;
        }
        auto @opts = GameModeOpts[int(mode)];
        for (uint i = 0; i < opts.Length; i++) {
            if (known.Exists(opts[i])) continue;
            chooseFrom.InsertLast(opts[i]);
        }
    }

    bool WindowOpen {
        get { return active; }
        set {
            if (!value) {
                chosenKey = "";
                OnChooseScriptOpt();
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

    string chosenKey;
    float btnWidth = 100;

    void DrawInner() {
        SubHeading("Add Game Option:");
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        auto pos = UI::GetCursorPos();

        if (UI::Button("Open Docs##game opts")) OpenBrowserURL("https://wiki.trackmania.io/en/dedicated-server/Usage/OfficialGameModesSettings");
        UI::SameLine();

        UI::BeginDisabled(chosenKey.Length == 0);
        if (UI::Button("Add##add game opt")) OnChooseScriptOpt();
        UI::SameLine();

        UI::EndDisabled();
        btnWidth = UI::GetCursorPos().x - pos.x;
        UI::Dummy(vec2());

        if (chooseFrom.Length == 0) {
            UI::Text("No script options found!?");
            return;
        }

        if (UI::BeginChild('script opt selectable scrollable')) {
            for (uint i = 0; i < chooseFrom.Length; i++) {
                DrawOptSelectable(chooseFrom[i]);
            }
        }
        UI::EndChild();
    }

    void DrawOptSelectable(const string &in key) {
        if (UI::Selectable(key, chosenKey == key)) {
            chosenKey = key;
        }
    }

    void OnChooseScriptOpt() {
        // todo load preset
        startnew(RunCallback);
        active = false;
    }

    void RunCallback() {
        if (chosenKey.Length == 0) {
            cb(null);
            return;
        }
        auto type = GetScriptOptType(chosenKey);
        cb(GameOpt(chosenKey, GetScriptDefaultFor(mode, chosenKey), type));
    }
}
