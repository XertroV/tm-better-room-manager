
class RoomsTab : Tab {
    int clubId;
    string clubName, clubTag, role;
    Json::Value@ myRooms = Json::Array();
    bool loading = false;
    bool IsLimited = false;
    bool disableActiveToggleSafety = false;

    RoomsTab(int clubId, const string &in clubName, const string &in clubTag, const string &in role) {
        string inParens = clubTag.Length > 0 ? clubTag : clubName;
        super(Icons::BuildingO + " " + inParens + "\\$z: Rooms", false);
        this.clubId = clubId;
        this.clubName = clubName;
        this.clubTag = clubTag;
        this.role = role;
        this.IsLimited = role == CONTENT_CREATOR;
        if (!IsLimited) disableActiveToggleSafety = true;
        startnew(CoroutineFunc(SetRooms));
        canCloseTab = true;
    }

    uint clubCount = 0;
    uint maxPage = 0;

    void SetRooms() {
        @myRooms = Json::Array();
        loading = true;
        try {
            auto resp = GetRoleDependantClubActivities();
            AddActivitiesFrom(resp['activityList']);
            maxPage = resp['maxPage'];
            clubCount = resp['itemCount'];
            if (maxPage > 1) GetAdditionalRooms();
            loading = false;
        } catch {
            NotifyWarning('Failed to update rooms list: ' + getExceptionInfo());
        }
    }

    Json::Value@ GetRoleDependantClubActivities(uint length = 100, uint offset = 0) {
        // content creators cannot see deactivated rooms
        if (IsLimited)
            return GetClubActivities(clubId, true, length, offset);
        return GetClubActivities(clubId, length, offset);
    }

    void AddActivitiesFrom(Json::Value@ activityList) {
        if (activityList.GetType() != Json::Type::Array) throw('activity list not an array');
        for (uint i = 0; i < activityList.Length; i++) {
            auto item = activityList[i];
            item['name'] = ColoredString(item['name']);
            if ("room" == item['activityType']) myRooms.Add(item);
        }
    }

    void GetAdditionalRooms() {
        for (uint page = 2; page <= maxPage; page++) {
            AddActivitiesFrom(GetRoleDependantClubActivities(100, (page - 1) * 100)['activityList']);
        }
    }

    void DrawInner() override {
        UI::BeginDisabled(loading);
        DrawControlBar();
        UI::Separator();
        DrawRoomsTable();
        UI::EndDisabled();
    }

    vec2 get_ButtonIconSize() {
        float s = UI::GetFrameHeight();
        return vec2(s, s);
    }

    float ctrlRhsWidth;
    vec4 ctrlBtnRect;
    float lastActiveColumnCursorX = 200;
    void DrawControlBar() {
        float width = UI::GetContentRegionMax().x;

        UI::BeginDisabled(loading);
        ControlButton(Icons::Plus + "##room-add", CoroutineFunc(this.OnClickAddRoom));
        ctrlBtnRect = UI::GetItemRect();
        ControlButton(Icons::Refresh + "##room-refresh", CoroutineFunc(this.SetRooms));

        UI::EndDisabled();

        if (loading) {
            UI::AlignTextToFramePadding();
            UI::Text("Loading...");
            UI::SameLine();
        }
        auto pos = UI::GetCursorPos();
        UI::SetCursorPos(vec2(Math::Max(pos.x, lastActiveColumnCursorX), pos.y));
        if (IsLimited) {
            disableActiveToggleSafety = UI::Checkbox("Disable toggle safety", disableActiveToggleSafety);
        }
        UI::Dummy(vec2());

        // // rhs buttons
        // UI::SetCursorPos(vec2(width - ctrlRhsWidth, UI::GetCursorPos().y));
        // auto curr = UI::GetCursorPos();
        // NotificationsCtrlButton(vec2(ctrlBtnRect.z, ctrlBtnRect.w));
        // ControlButton(Icons::FloppyO + "##main-export2", CoroutineFunc(this.OnClickExport));
        // ctrlRhsWidth = (UI::GetCursorPos() - curr - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing)).x;

        // // control buttons always end with SameLine so put a dummy here to go to next line.

    }

    void DrawRoomsTable() {
        uint nCols = 9;
        if (UI::BeginTable("clubs table", nCols, UI::TableFlags::SizingStretchSame | UI::TableFlags::ScrollY)) {
            UI::TableSetupColumn("ID", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("##clubs col btns", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Active", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Public", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Password", UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn("##-club-room-rhs", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("##-club-room-rhs2", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("##-club-room-rhs3", UI::TableColumnFlags::WidthStretch);
            UI::TableHeadersRow();

            UI::ListClipper mapClipper(myRooms.Length);
            while (mapClipper.Step()) {
                for (int i = mapClipper.DisplayStart; i < mapClipper.DisplayEnd; i++) {
                    DrawRoomsTableRow(myRooms[i]);
                }
            }

            UI::EndTable();
        }
    }

    string greenCheck = "\\$<\\$4f8" + Icons::Check + "\\$>";
    string greenUnlock = "\\$<\\$4f8" + Icons::Unlock + "\\$>";
    string redLock = "\\$<\\$f84" + Icons::Lock + "\\$>";
    string redTimes = "\\$<\\$f84" + Icons::Times + "\\$>";
    string redUserSecret = "\\$<\\$f84" + Icons::UserSecret + "\\$>";

    void DrawRoomsTableRow(Json::Value@ room) {
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            int roomId = int(room['id']);
            UI::Text(tostring(roomId));

            UI::TableNextColumn();
            UI::Text(room['name']);

            UI::TableNextColumn();
            if (UI::Button(Icons::PencilSquareO + "##" + roomId)) OnClickEditRoom(roomId, room['name'], room['public']);

            UI::TableNextColumn();
            lastActiveColumnCursorX = UI::GetCursorPos().x;
            bool isActive = room['active'];
            UI::Text(isActive ? greenCheck : redTimes);
            UI::SameLine();
            UI::BeginDisabled(!disableActiveToggleSafety);
            if (UI::Button((isActive ? Icons::ToggleOn : Icons::ToggleOff) + "##toggle-" + roomId)) OnClickToggleActive(roomId, isActive);
            UI::EndDisabled();

            UI::TableNextColumn();
            UI::Text(bool(room['public']) ? greenCheck : redUserSecret);

            UI::TableNextColumn();
            bool isPassworded = bool(room['password']);
            UI::Text(isPassworded ? redLock : greenUnlock);
            if (isPassworded) {
                UI::SameLine();
                if (UI::Button(Icons::Clone)) OnClickCopyPassword(roomId);
            }
    }

    int toggleRoomActive;
    bool toggleRoomActiveNew;
    void OnClickToggleActive(int roomId, bool currentlyActive) {
        loading = true;
        toggleRoomActive = roomId;
        toggleRoomActiveNew = !currentlyActive;
        startnew(CoroutineFunc(RunToggleRoomActive));
    }

    void RunToggleRoomActive() {
        auto roomId = toggleRoomActive;
        int active = toggleRoomActiveNew ? 1 : 0;
        auto pl = Json::Object();
        pl['active'] = active;
        EditClubActivity(clubId, roomId, pl);
        SetRooms();
    }

    int pwGetRoomId;
    void OnClickCopyPassword(int roomId) {
        loading = true;
        pwGetRoomId = roomId;
        startnew(CoroutineFunc(GetAndCopyPassword));
    }

    void GetAndCopyPassword() {
        auto roomId = pwGetRoomId;
        auto resp = GetRoomPassword(clubId, roomId);
        loading = false;
        if (resp is null || resp.GetType() != Json::Type::Object) {
            NotifyWarning("Could not get password for room: " + roomId);
        } else {
            string pw = resp.Get('password', '');
            if (pw.Length == 0) {
                NotifyWarning("Could not get password for room: " + roomId);
            } else {
                IO::SetClipboard(pw);
                Notify("Copied password for room " + roomId + " to clipboard.");
            }
        }
    }


    void OnClickAddRoom() {
        mainTabs.InsertLast(RoomTab(this, -1, "", true));
    }

    void OnClickEditRoom(int roomId, const string &in roomName, bool public) {
        mainTabs.InsertLast(RoomTab(this, roomId, roomName, public));
    }
}
