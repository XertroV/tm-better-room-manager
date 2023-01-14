
class RoomTab : Tab {
    int roomId;
    RoomsTab@ parent;
    string roomName;
    Json::Value@ thisRoom = Json::Object();
    bool loading = false;
    bool saving = false;
    LazyMap@[] lazyMaps;
    GameOpt@[] gameOpts;
    bool isEditing = true;

    // roomId = -1 to create a new room
    RoomTab(RoomsTab@ parent, int _roomId, const string &in roomName, bool public) {
        isEditing = _roomId > 0;
        this.roomName = isEditing ? roomName : "New Room";
        super(Icons::Server + " " + this.roomName + "\\$z (" + _roomId + ")", false);
        // have to set isEditing again for some reason -- weird.
        isEditing = _roomId > 0;
        this.roomId = _roomId;
        @this.parent = parent;
        this.public = public;
        if (isEditing)
            startnew(CoroutineFunc(LoadRoom));
        canCloseTab = true;
    }

    uint clubCount = 0;
    uint maxPage = 0;

    void LoadRoom() {
        loading = true;
        saving = false;
        lazyMaps.RemoveRange(0, lazyMaps.Length);
        gameOpts.RemoveRange(0, gameOpts.Length);
        try {
            @thisRoom = GetClubRoom(parent.clubId, roomId);
            thisRoom['clubName'] = ColoredString(thisRoom['clubName']);
            thisRoom['name'] = ColoredString(thisRoom['name']);
            thisRoom['room']['name'] = ColoredString(thisRoom['room']['name']);
            ResetFormFromRoomInfo();
            PopulateMapsList();
            PopulateGameOpts();
        } catch {
            NotifyWarning('Failed to update room info: ' + getExceptionInfo());
        }
        loading = false;
    }

    void PopulateMapsList() {
        auto @_maps = thisRoom['room']['maps'];
        for (uint i = 0; i < _maps.Length; i++) {
            lazyMaps.InsertLast(LazyMap(_maps[i]));
        }
    }

    void PopulateGameOpts() {
        auto opts = thisRoom['room']['scriptSettings'];
        auto keys = opts.GetKeys();
        for (uint i = 0; i < keys.Length; i++) {
            auto opt = opts[keys[i]];
            gameOpts.InsertLast(GameOpt(opt['key'], opt['value'], opt['type']));
        }
    }

    void DrawInner() override {
        DrawControlBar();
        UI::Separator();
        DrawMainBody();
        // DrawRoomsTable();
    }

    float mapsCtrlBarRHSWidth = 100;

    void DrawMainBody() {
        UI::BeginDisabled(loading || saving);
        if (UI::BeginTable('edit-room-table##' + roomId, 2, UI::TableFlags::SizingStretchSame)) {
            UI::TableNextRow();

            UI::TableNextColumn();
            SubHeading("Room Options:");
            DrawRoomEditForm();

            UI::TableNextColumn();
            SubHeading("Maps:");
            UI::SameLine();
            float width = UI::GetContentRegionMax().x;
            UI::SetCursorPos(vec2(width - mapsCtrlBarRHSWidth + UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x, UI::GetCursorPos().y));
            auto pos = UI::GetCursorPos();
            ControlButton(Icons::Plus + "##add-map" + roomId, CoroutineFunc(OnClickAddMap));
            ControlButton(Icons::Plus + " Random##"+roomId, CoroutineFunc(OnClickAddRandom));
            ControlButton(Icons::TrashO + " All##"+roomId, CoroutineFunc(OnClickRmAll));
            mapsCtrlBarRHSWidth = UI::GetCursorPos().x - pos.x;
            AddSimpleTooltip("Refresh to undo.");
            UI::Dummy(vec2());

            DrawRoomMapsForm();

            UI::EndTable();
        }
        UI::EndDisabled();
    }

    void OnClickRmAll() {
        lazyMaps.RemoveRange(0, lazyMaps.Length);
    }

    void OnClickAddRandom() {
        loading = true;
        RandomMapsChooser::Open(RandomMapsCallback(OnGotRandomMaps));
    }

    void OnGotRandomMaps(LazyMap@[]@ maps) {
        loading = false;
        if (maps is null) return;
        for (uint i = 0; i < maps.Length; i++) {
            this.lazyMaps.InsertLast(maps[i]);
        }
    }

    void OnClickAddMap() {
        loading = true;
        MapChooser::Open(MapChosenCallback(OnMapChosen));
    }

    void OnMapChosen(LazyMap@ map) {
        loading = false;
        if (map is null) return;
        this.lazyMaps.InsertLast(map);
    }

    void ResetFormFromRoomInfo() {
        name = thisRoom['name'];
        passworded = thisRoom['password'];
        auto room = thisRoom['room'];
        region = SvrLocFromString(room['region']);
        maxPlayers = room['maxPlayers'];
        @maps = room['maps'];
        mode = GameModeFromStr(room['script']);
        scalable = room['scalable'];
        @scriptSettings = room['scriptSettings'];
    }

    string name;
    bool public = true;
    SvrLoc region = SvrLoc::EuWest;
    uint maxPlayers = 64; // 2 to 100
    bool scalable = false;
    bool passworded = false;
    Json::Value@ maps = Json::Array();
    Json::Value@ scriptSettings = Json::Object();
    GameMode mode = GameMode::TimeAttack;
    bool _creatingRoom = false;

    void DrawRoomEditForm() {
        bool changed = false;
        name = ColoredString(UI::InputText("Room Name", name.Replace('\\', ''), changed));
        UI::Text("Name Preview: " + name);
        public = UI::Checkbox("Public?", public);
        DrawLocationCombo();
        maxPlayers = UI::SliderInt("Max. Players", maxPlayers, 2, 100);
        scalable = UI::Checkbox("Scalable?", scalable);
        UI::BeginDisabled(isEditing);
        passworded = UI::Checkbox("Password?", passworded);
        if (isEditing) {
            UI::SameLine();
            UI::Text("Cannot be changed after the room has been created.");
        }
        UI::EndDisabled();
        DrawGameModeSettings();
        // DrawSaveButton();
    }

    void DrawLocationCombo() {
        if (UI::BeginCombo("Server Loc.", SvrLocStr(region))) {
            if (UI::Selectable(SvrLocStr(SvrLoc::EuWest), region == SvrLoc::EuWest)) region = SvrLoc::EuWest;
            if (UI::Selectable(SvrLocStr(SvrLoc::CaCentral), region == SvrLoc::CaCentral)) region = SvrLoc::CaCentral;
            UI::EndCombo();
        }
    }

    float addModeOptWidth = 100;
    void DrawGameModeSettings() {
        auto origMode = mode;
        if (UI::BeginCombo("Mode", tostring(mode))) {
            for (uint i = 1; i <= int(GameMode::Rounds); i++) {
                if (UI::Selectable(tostring(GameMode(i)), i == int(mode))) mode = GameMode(i);
            }
            UI::EndCombo();
        }
        if (origMode != mode) startnew(CoroutineFunc(OnModeChanged));
        if (UI::CollapsingHeader("Script Options")) {
            float width = UI::GetContentRegionMax().x;
            auto pos = UI::GetCursorPos();
            SubHeading("Script Options:");
            UI::SetCursorPos(vec2(width - addModeOptWidth + UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x, pos.y));
            pos = UI::GetCursorPos();
            ControlButton(Icons::Plus + " Standard##add-script-std-opts" + roomId, CoroutineFunc(OnClickAddScriptStdOpts));
            ControlButton(Icons::Plus + "##add-script-opt" + roomId, CoroutineFunc(OnClickAddScriptOpt));
            addModeOptWidth = UI::GetCursorPos().x - pos.x;
            UI::Dummy(vec2());
            UI::Separator();
            if (gameOpts.Length > 0) {
                if (UI::BeginTable("room script opts" + roomId, 3)) {
                    UI::TableSetupColumn("key", UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("valset", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("delete", UI::TableColumnFlags::WidthFixed);
                    UI::ListClipper modeOptClipper(gameOpts.Length);
                    while (modeOptClipper.Step()) {
                        for (uint i = modeOptClipper.DisplayStart; i < modeOptClipper.DisplayEnd && i < gameOpts.Length; i++) {
                            auto go = gameOpts[i];
                            UI::TableNextColumn();
                            UI::AlignTextToFramePadding();
                            UI::Text(go.key);
                            UI::TableNextColumn();
                            go.DrawOption(false);
                            UI::TableNextColumn();
                            if (UI::Button(Icons::QuestionCircleO + "##url-" + go.key)) OpenBrowserURL(go.DocsUrl());
                            UI::SameLine();
                            if (UI::Button(Icons::TrashO + "##rm-" + go.key)) {
                                gameOpts.RemoveAt(gameOpts.FindByRef(go));
                            }
                        }
                    }
                    UI::EndTable();
                }
            } else {
                UI::Text("No game options set.");
            }
        }
    }

    void OnModeChanged() {
        auto @validOpts = GameModeOpts[int(mode)];
        for (uint i = 0; i < gameOpts.Length; i++) {
            auto go = gameOpts[i];
            if (validOpts.Find(go.key) < 0) {
                gameOpts.RemoveAt(i);
                i--;
            }
        }
    }

    void OnClickAddScriptStdOpts() {
        string[][]@ defaults = scriptDefaults[mode];
        for (uint i = 0; i < defaults.Length; i++) {
            AddScriptOptIfNotExists(defaults[i][0], defaults[i][1]);
        }
    }

    void AddScriptOptIfNotExists(const string &in key, const string &in value) {
        bool found = false;
        for (uint i = 0; i < gameOpts.Length; i++) {
            auto go = gameOpts[i];
            if (go.key == key) {
                found = true;
                break;
            }
        }
        if (!found) {
            gameOpts.InsertLast(GameOpt(key, value, GetScriptOptType(key)));
        }
    }

    void OnClickAddScriptOpt() {
        loading = true;
        ScriptOptChooser::Open(ScriptOptChosenCallback(AddScriptOpt), gameOpts, mode);
    }

    void AddScriptOpt(GameOpt@ go) {
        loading = false;
        if (go is null) return;
        gameOpts.InsertLast(go);
    }

    // void DrawSaveButton() {
    //     UI::BeginDisabled(IsInvalidSettings);
    //     if (UI::Button(_creatingRoom ? "Create Room" : "Update Room")) OnClickSaveRoom();
    //     UI::EndDisabled();
    // }

    bool IsInvalidSettings {
        get {
            return false;
        }
    }

    void OnClickSaveRoom() {
        saving = true;
        if (isEditing) {
            ConstructAndSaveRoomConfig();
        } else {
            ConstructAndSaveNewRoom();
        }
        SetRoomPublicStatus();
        LoadRoom();
    }

    Json::Value@ GenRoomConfigJson() {
        auto data = Json::Object();
        data['name'] = name.Replace('\\', '');
        data['region'] = SvrLocStr(region);
        data['maxPlayersPerServer'] = maxPlayers;
        data['script'] = GameModeToFullModeString(mode);
        data['settings'] = Json::Array();
        data['maps'] = Json::Array();
        data['scalable'] = scalable ? 1 : 0;
        // todo: can't change pw later
        data['password'] = passworded ? 1 : 0;
        for (uint i = 0; i < gameOpts.Length; i++) {
            auto go = gameOpts[i];
            data['settings'].Add(go.ToJson());
        }
        for (uint i = 0; i < lazyMaps.Length; i++) {
            data['maps'].Add(lazyMaps[i].uid);
        }
        return data;
    }

    void ConstructAndSaveRoomConfig() {
        SaveEditedRoomConfig(parent.clubId, roomId, GenRoomConfigJson());
    }

    void ConstructAndSaveNewRoom() {
        auto resp = CreateClubRoom(parent.clubId, GenRoomConfigJson());
        roomId = resp['activityId'];
        tabName = Icons::Server + " " + name + "\\$z (" + roomId + ")";
        startnew(CoroutineFunc(LoadRoom));
    }

    void SetRoomPublicStatus() {
        auto data = Json::Object();
        data['public'] = public ? 1 : 0;
        SaveActivityPublicStatus(parent.clubId, roomId, data);
    }



    void DrawRoomMapsForm() {
        if (UI::BeginTable("room edit maps table" + roomId, 5, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Author");
            UI::TableSetupColumn("AT");
            UI::TableSetupColumn("Img", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("##btns", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();
            UI::ListClipper lmClipper(lazyMaps.Length);
            while (lmClipper.Step()) {
                for (uint i = lmClipper.DisplayStart; i < lmClipper.DisplayEnd && i < lazyMaps.Length; i++) {
                    auto lm = lazyMaps[i];
                    DrawLazyMapRow(i, lm);
                }
            }
            UI::EndTable();
        }
    }

    void DrawLazyMapRow(uint i, LazyMap@ lm) {
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(lm.name);
        //

        UI::TableNextColumn();
        UI::Text(lm.author);
        //

        UI::TableNextColumn();
        UI::Text(lm.authorTime);
        //

        UI::TableNextColumn();
        UI::Text(Icons::FileImageO);
        bool clicked = UI::IsItemClicked();
        if (UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
            UI::BeginTooltip();
            lm.DrawThumbnail(vec2(512, 512));
            UI::EndTooltip();
        }
        if (clicked) CopyToClipboardAndNotify(lm.uid);

        UI::TableNextColumn();
        if (UI::Button(Icons::TrashO + "##remove-map-" + i)) {
            lazyMaps.RemoveAt(lazyMaps.FindByRef(lm));
        }
    }



    vec2 get_ButtonIconSize() {
        float s = UI::GetFrameHeight();
        return vec2(s, s);
    }


    float ctrlRhsWidth;
    vec4 ctrlBtnRect;

    void DrawControlBar() {
        UI::BeginDisabled(loading || saving);

        float width = UI::GetContentRegionMax().x;
        // ControlButton(Icons::Plus + "##room-add", CoroutineFunc(this.OnClickAddRoom));
        ControlButton(Icons::Refresh + "##room-refresh" + roomId, CoroutineFunc(this.LoadRoom));
        ctrlBtnRect = UI::GetItemRect();
        // UI::BeginDisabled(true);
        ControlButton(Icons::FloppyO + "##room-save-preset" + roomId, CoroutineFunc(OnClickSavePreset));
        AddSimpleTooltip("Save Preset");
        ControlButton(Icons::FolderOpen + "##room-from-preset" + roomId, CoroutineFunc(OnClickChoosePreset));
        AddSimpleTooltip("Load Preset");
        // UI::EndDisabled();

        UI::AlignTextToFramePadding();

        if (loading) {
            UI::Text("Loading...");
            UI::SameLine();
        } else if (saving) {
            UI::Text("Saving...");
            UI::SameLine();
        } else {
            // UI::Dummy(vec2());
        }

        // rhs buttons
        UI::SetCursorPos(vec2(width - ctrlRhsWidth, UI::GetCursorPos().y));
        auto curr = UI::GetCursorPos();

        // NotificationsCtrlButton(vec2(ctrlBtnRect.z, ctrlBtnRect.w));

        ControlButton(Icons::Upload + " Save Room##save-room" + roomId, CoroutineFunc(this.OnClickSaveRoom));

        ctrlRhsWidth = (UI::GetCursorPos() - curr - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing)).x;
        // control buttons always end with SameLine so put a dummy here to go to next line.
        UI::Dummy(vec2());

        UI::EndDisabled();
    }




    void OnClickChoosePreset() {
        loading = true;
        PresetChooser::Open(PresetChosenCallback(OnChosenPreset));
    }

    void OnChosenPreset(Json::Value@ preset) {
        loading = false;
        if (preset is null) return;
        print('on chosen preset cb: ' + Json::Write(preset));
        region = SvrLocFromString(preset['region']);
        maxPlayers = preset['maxPlayersPerServer'];
        mode = GameModeFromStr(preset['script']);
        scalable = int(preset['scalable']) == 1;
        gameOpts.RemoveRange(0, gameOpts.Length);
        auto presetScriptOpts = preset['settings'];
        for (uint i = 0; i < presetScriptOpts.Length; i++) {
            auto opts = presetScriptOpts[i];
            gameOpts.InsertLast(GameOpt(opts['key'], opts['value'], opts['type']));
        }
    }

    void OnClickSavePreset() {
        // todo
        loading = true;
        PresetSaver::Open(CoroutineFunc(OnSavedPreset), this);
    }

    void OnSavedPreset() {
        loading = false;
    }
}



class LazyMap {
    string uid;
    LazyMap(const string &in uid) {
        this.uid = uid;
        startnew(CoroutineFunc(LoadMap));
    }

    string name = "??";
    string author = "??";
    string authorTime = "??";
    string thumbUrl;

    void LoadMap() {
        auto map = GetMapFromUid(uid);
        name = ColoredString(map.Name);
        author = map.AuthorDisplayName;
        authorTime = Time::Format(map.AuthorScore);
        thumbUrl = map.ThumbnailUrl;
        startnew(CoroutineFunc(LoadThumbnail));
    }

    UI::Texture@ tex;
    void LoadThumbnail() {
        trace('loading thumbnail: ' + thumbUrl);
        auto req = Net::HttpGet(thumbUrl);
        while (!req.Finished()) yield();
        @tex = UI::LoadTexture(req.Buffer());
    }

    void DrawThumbnail(vec2 size = vec2()) {
        UI::Text("UID: " + uid + "       (click to copy)");
        if (tex is null) {
            UI::Text("Loading thumbnail...");
        } else {
            if (size.LengthSquared() > 0)
                UI::Image(tex, size);
            else
                UI::Image(tex);
        }
    }
}



enum SvrLoc {
    EuWest, CaCentral
}

const string SvrLocStr(SvrLoc s) {
    if (s == SvrLoc::EuWest) return "eu-west";
    return "ca-central";
}

SvrLoc SvrLocFromString(const string &in str) {
    if (str == "eu-west") return SvrLoc::EuWest;
    return SvrLoc::CaCentral;
}
