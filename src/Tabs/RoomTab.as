
class RoomTab : Tab {
    int roomId;
    RoomsTab@ parent;
    string roomName;
    Json::Value@ thisRoom = Json::Object();
    bool loading = false;
    LazyMap@[] lazyMaps;

    RoomTab(RoomsTab@ parent, int roomId, const string &in roomName, bool public) {
        // string inParens = clubTag.Length > 0 ? clubTag : clubName;
        super(Icons::Server + " " + roomName + " (" + roomId + ")", false);
        this.roomId = roomId;
        this.roomName = roomName;
        @this.parent = parent;
        this.public = public;
        startnew(CoroutineFunc(LoadRoom));
        canCloseTab = true;
    }

    uint clubCount = 0;
    uint maxPage = 0;

    void LoadRoom() {
        loading = true;
        lazyMaps.RemoveRange(0, lazyMaps.Length);
        try {
            @thisRoom = GetClubRoom(parent.clubId, roomId);
            thisRoom['clubName'] = ColoredString(thisRoom['clubName']);
            thisRoom['name'] = ColoredString(thisRoom['name']);
            thisRoom['room']['name'] = ColoredString(thisRoom['room']['name']);
            ResetFormFromRoomInfo();
            PopulateMapsList();
        } catch {
            NotifyWarning('Failed up update rooms list: ' + getExceptionInfo());
        }
        loading = false;
    }

    void PopulateMapsList() {
        auto @_maps = thisRoom['room']['maps'];
        for (uint i = 0; i < _maps.Length; i++) {
            lazyMaps.InsertLast(LazyMap(_maps[i]));
        }
    }

    void DrawInner() override {
        DrawControlBar();
        UI::Separator();
        DrawMainBody();
        // DrawRoomsTable();
    }

    void DrawMainBody() {
        UI::BeginDisabled(loading);
        if (UI::BeginTable('edit-room-table##' + roomId, 2, UI::TableFlags::SizingStretchSame)) {
            UI::TableNextRow();
            UI::TableNextColumn();
            SubHeading("Room Options:");
            DrawRoomEditForm();
            UI::TableNextColumn();
            SubHeading("Maps:");
            float width = UI::GetContentRegionMax().x;
            auto pos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(width - ctrlBtnRect.z, pos.y));
            DrawRoomMapsForm();
            UI::EndTable();
        }
        UI::EndDisabled();
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
        name = UI::InputText("Room Name", name, changed);
        public = UI::Checkbox("Public?", public);
        DrawLocationCombo();
        maxPlayers = UI::SliderInt("Max. Players", maxPlayers, 2, 100);
        scalable = UI::Checkbox("Scalable?", scalable);
        passworded = UI::Checkbox("Passworded?", passworded);
        DrawGameModeSettings();
        DrawSaveButton();
    }

    void DrawLocationCombo() {
        if (UI::BeginCombo("Server Loc.", SvrLocStr(region))) {
            if (UI::Selectable(SvrLocStr(SvrLoc::EuWest), region == SvrLoc::EuWest)) region = SvrLoc::EuWest;
            if (UI::Selectable(SvrLocStr(SvrLoc::CaCentral), region == SvrLoc::CaCentral)) region = SvrLoc::CaCentral;
            UI::EndCombo();
        }
    }

    void DrawGameModeSettings() {
        if (UI::BeginCombo("Mode", tostring(mode))) {
            for (uint i = 1; i <= int(GameMode::Rounds); i++) {
                if (UI::Selectable(tostring(GameMode(i)), i == int(mode))) mode = GameMode(i);
            }
        }
        if (UI::CollapsingHeader("Game Mode Options")) {
            UI::Text("todo");
        }
    }

    void DrawSaveButton() {
        UI::BeginDisabled(IsInvalidSettings);
        if (UI::Button(_creatingRoom ? "Create Room" : "Update Room")) OnClickSaveRoom();
        UI::EndDisabled();
    }

    bool IsInvalidSettings {
        get {
            return false;
        }
    }

    void OnClickSaveRoom() {

    }



    void DrawRoomMapsForm() {
        if (UI::BeginTable("room edit maps table" + roomId, 4, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Author");
            UI::TableSetupColumn("AT");
            UI::TableSetupColumn("Img", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();
            UI::ListClipper lmClipper(lazyMaps.Length);
            while (lmClipper.Step()) {
                for (uint i = lmClipper.DisplayStart; i < lmClipper.DisplayEnd; i++) {
                    auto lm = lazyMaps[i];
                    DrawLazyMapRow(lm);
                }
            }
            UI::EndTable();
        }
    }

    void DrawLazyMapRow(LazyMap@ lm) {
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
        if (UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
            UI::BeginTooltip();
            lm.DrawThumbnail(vec2(512, 512));
            UI::EndTooltip();
        }
    }



    vec2 get_ButtonIconSize() {
        float s = UI::GetFrameHeight();
        return vec2(s, s);
    }


    float ctrlRhsWidth;
    vec4 ctrlBtnRect;

    void DrawControlBar() {
        float width = UI::GetContentRegionMax().x;

        UI::BeginDisabled(loading);
        // ControlButton(Icons::Plus + "##room-add", CoroutineFunc(this.OnClickAddRoom));
        ControlButton(Icons::Refresh + "##room-refresh" + roomId, CoroutineFunc(this.LoadRoom));
        ctrlBtnRect = UI::GetItemRect();

        UI::EndDisabled();

        if (loading) {
            UI::AlignTextToFramePadding();
            UI::Text("Loading...");
        } else {
            UI::Dummy(vec2());
        }

        // // rhs buttons
        // UI::SetCursorPos(vec2(width - ctrlRhsWidth, UI::GetCursorPos().y));
        // auto curr = UI::GetCursorPos();
        // NotificationsCtrlButton(vec2(ctrlBtnRect.z, ctrlBtnRect.w));
        // ControlButton(Icons::FloppyO + "##main-export2", CoroutineFunc(this.OnClickExport));
        // ctrlRhsWidth = (UI::GetCursorPos() - curr - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing)).x;

        // // control buttons always end with SameLine so put a dummy here to go to next line.

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
        UI::Text("UID: " + uid);
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
