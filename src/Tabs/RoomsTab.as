
class RoomsTab : Tab {
    int clubId;
    string clubName, clubTag;
    Json::Value@ myRooms = Json::Array();
    bool loading = false;

    RoomsTab(int clubId, const string &in clubName, const string &in clubTag = "") {
        string inParens = clubTag.Length > 0 ? clubTag : clubName;
        super(Icons::BuildingO + " " + inParens + ": Rooms", false);
        this.clubId = clubId;
        this.clubName = clubName;
        this.clubTag = clubTag;
        startnew(CoroutineFunc(SetRooms));
        canCloseTab = true;
    }

    uint clubCount = 0;
    uint maxPage = 0;

    void SetRooms() {
        @myRooms = Json::Array();
        loading = true;
        try {
            auto resp = GetClubActivities(clubId, 100, 0);
            AddActivitiesFrom(resp['activityList']);
            maxPage = resp['maxPage'];
            clubCount = resp['itemCount'];
            if (maxPage > 1) GetAdditionalRooms();
            loading = false;
        } catch {
            NotifyWarning('Failed to update rooms list: ' + getExceptionInfo());
        }
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
            AddActivitiesFrom(GetClubActivities(clubId, 100, (page - 1) * 100)['activityList']);
        }
    }

    void DrawInner() override {
        DrawControlBar();
        UI::Separator();
        DrawRoomsTable();
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
        ControlButton(Icons::Plus + "##room-add", CoroutineFunc(this.OnClickAddRoom));
        ctrlBtnRect = UI::GetItemRect();
        ControlButton(Icons::Refresh + "##room-refresh", CoroutineFunc(this.SetRooms));

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

    void DrawRoomsTable() {
        uint nCols = 6;
        if (UI::BeginTable("clubs table", nCols, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("ID");
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Active");
            UI::TableSetupColumn("Public");
            UI::TableSetupColumn("Password");
            UI::TableSetupColumn("##clubs col btns", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();

            UI::ListClipper mapClipper(myRooms.Length);
            while (mapClipper.Step()) {
                for (uint i = mapClipper.DisplayStart; i < mapClipper.DisplayEnd; i++) {
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
            UI::Text(bool(room['active']) ? greenCheck : redTimes);

            UI::TableNextColumn();
            UI::Text(bool(room['public']) ? greenCheck : redUserSecret);

            UI::TableNextColumn();
            bool isPassworded = bool(room['password']);
            UI::Text(isPassworded ? redLock : greenUnlock);
            if (isPassworded) {
                UI::SameLine();
                if (UI::Button(Icons::Clone)) OnClickCopyPassword(roomId);
            }

            UI::TableNextColumn();
            if (UI::Button(Icons::PencilSquareO + "##" + roomId)) OnClickEditRoom(roomId, room['name'], room['public']);
    }

    int pwGetRoomId;
    void OnClickCopyPassword(int roomId) {
        pwGetRoomId = roomId;
        startnew(CoroutineFunc(GetAndCopyPassword));
    }

    void GetAndCopyPassword() {
        auto roomId = pwGetRoomId;
        auto resp = GetRoomPassword(clubId, roomId);
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
