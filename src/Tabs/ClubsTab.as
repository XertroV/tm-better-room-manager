const string CONTENT_CREATOR = "Content_Creator";

class ClubsTab : Tab {
    Json::Value@ myClubs = Json::Array();
    bool loading = false;

    ClubsTab() {
        super(Icons::Users + " Clubs", false);
        startnew(CoroutineFunc(SetClubs));
    }

    uint clubCount = 0;
    uint maxPage = 0;

    void SetClubs() {
        @myClubs = Json::Array();
        loading = true;
        try {
            auto resp = GetMyClubs();
            @myClubs = resp['clubList'];
            FixClubNamesTags();
            maxPage = resp['maxPage'];
            clubCount = resp['clubCount'];
            if (maxPage > 1) GetAdditionalClubs();
            FixClubNamesTags(100);
            loading = false;
        } catch {
            NotifyWarning('Failed to update clubs list: ' + getExceptionInfo());
        }
    }

    void FixClubNamesTags(uint startIx = 0) {
        for (uint i = startIx; i < myClubs.Length; i++) {
            auto club = myClubs[i];
            // print(ColoredString(club['name']));
            club['nameSafe'] = ColoredString(club['name']);
            club['tagSafe'] = ColoredString(club['tag']);
            // print(club['name']);
            string role = string(club['role']);
            bool isAdmin = role == "Admin" || role == "Creator";
            bool isLimitedAdmin = role == CONTENT_CREATOR;
            bool isAnyAdmin = isAdmin || isLimitedAdmin;
            club['isAdmin'] = isAdmin;
            club['isAnyAdmin'] = isAnyAdmin;
            club['isLimitedAdmin'] = isLimitedAdmin;
        }
    }

    void GetAdditionalClubs() {
        for (uint page = 2; page <= maxPage; page++) {
            auto resp = GetMyClubs(100, (page - 1) * 100)['clubList'];
            for (uint i = 0; i < resp.Length; i++) {
                myClubs.Add(resp[i]);
            }
        }
    }

    void DrawInner() override {
        DrawControlBar();
        UI::Separator();
        DrawClubsTable();
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
        ControlButton(Icons::Refresh + "##clubs refresh", CoroutineFunc(this.SetClubs));
        UI::EndDisabled();
        ctrlBtnRect = UI::GetItemRect();

        if (loading) {
            UI::AlignTextToFramePadding();
            UI::Text("Loading...");
        } else {
            UI::Dummy(vec2());
        }

        // ControlButton(Icons::FloppyO + "##main-export", CoroutineFunc(this.OnClickExport));

        // // rhs buttons
        // UI::SetCursorPos(vec2(width - ctrlRhsWidth, UI::GetCursorPos().y));
        // auto curr = UI::GetCursorPos();
        // NotificationsCtrlButton(vec2(ctrlBtnRect.z, ctrlBtnRect.w));
        // ControlButton(Icons::FloppyO + "##main-export2", CoroutineFunc(this.OnClickExport));
        // ctrlRhsWidth = (UI::GetCursorPos() - curr - UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing)).x;

        // // control buttons always end with SameLine so put a dummy here to go to next line.
        // UI::Dummy(vec2());
    }

    void DrawClubsTable() {
        uint nCols = 5;
        if (UI::BeginTable("clubs table", nCols, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("ID");
            UI::TableSetupColumn("Name");
            UI::TableSetupColumn("Tag");
            UI::TableSetupColumn("Role");
            UI::TableSetupColumn("##clubs col btns", UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();

            UI::ListClipper mapClipper(myClubs.Length);
            while (mapClipper.Step()) {
                for (int i = mapClipper.DisplayStart; i < mapClipper.DisplayEnd; i++) {
                    DrawClubsTableRow(myClubs[i]);
                }
            }

            UI::EndTable();
        }
    }

    void DrawClubsTableRow(Json::Value@ club) {
        int clubId = int(club['id']);
        string club_id = tostring(clubId);

        // Creator, Admin, Content_Creator, Member?, VIP?
        string role = string(club['role']);
        bool isAdmin = role == "Admin" || role == "Creator";

        UI::TableNextRow();
        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(club_id);

        UI::TableNextColumn();
        UI::Text(club['nameSafe']);

        UI::TableNextColumn();
        UI::Text(club['tagSafe']);

        UI::TableNextColumn();
        UI::Text(role);

        UI::TableNextColumn();
        if (isAdmin || role == CONTENT_CREATOR) {
            UI::BeginDisabled(RoomsTabExists(clubId));
            if (UI::Button("Rooms##"+club_id))
                OnClickRoomsForClub(clubId, club['nameSafe'], club['tagSafe'], role);
            UI::EndDisabled();
        }
    }

    void OnClubTagUpdated(ref@ r) {
        Json::Value@ resp = cast<Json::Value>(r);
        for (uint i = 0; i < myClubs.Length; i++) {
            if (int(myClubs[i]['id']) == int(resp['id'])) {
                myClubs[i]['tag'] = resp['tag'];
                myClubs[i]['tagSafe'] = ColoredString(resp['tag']);
                break;
            }
        }
    }

    void OnClickRoomsForClub(int clubId, const string &in clubName, const string &in clubTag, const string &in role) {
        auto room = RoomsTab(clubId, clubName, clubTag, role);
        mainTabs.InsertLast(room);
    }

    bool RoomsTabExists(int clubId) {
        for (uint i = 0; i < mainTabs.Length; i++) {
            auto rsTab = cast<RoomsTab>(mainTabs[i]);
            if (rsTab !is null && rsTab.clubId == clubId) return true;
        }
        return false;
    }
}
