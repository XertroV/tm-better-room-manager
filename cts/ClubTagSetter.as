#if DEV
namespace ClubTagSetter {
    bool active = false;
    CoroutineFuncUserdata@ cb = null;
    Json::Value@ club;
    int clubId;
    string m_newTag;

    bool Open(CoroutineFuncUserdata@ callback, Json::Value@ _club) {
        if (active) return false;
        active = true;
        @cb = callback;
        @club = _club;
        clubId = club['id'];
        m_newTag = club['tag'];
        return true;
    }

    bool WindowOpen {
        get { return active; }
        set {
            active = value;
        }
    }

    void Render() {
        if (!active) return;
        UI::SetNextWindowSize(500, 300, UI::Cond::Appearing);
        if (UI::Begin("Club Tag Setter", WindowOpen)) {
            DrawInner();
        }
        UI::End();
    }

    string chosenKey;
    float btnWidth = 100;

    void DrawInner() {
        string currentTag = club['tag'];
        string name = club['name'];

        SubHeading("Set Club Tag for " + name + " ("+clubId+")");
        // UI::SameLine();
        // UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        // auto pos = UI::GetCursorPos();

        // if (UI::Button("Open Docs##game opts")) OpenBrowserURL("https://wiki.trackmania.io/en/dedicated-server/Usage/OfficialGameModesSettings");
        // UI::SameLine();

        // UI::BeginDisabled(chosenKey.Length == 0);
        // if (UI::Button("Add##add game opt")) OnChooseScriptOpt();
        // UI::SameLine();

        // UI::EndDisabled();
        // btnWidth = UI::GetCursorPos().x - pos.x;
        // UI::Dummy(vec2());

        UI::Text("Current Tag: " + Text::OpenplanetFormatCodes(currentTag));
        UI::Text("Current Tag: " + currentTag);
        if (UI::Button("Copy Tag")) {
            IO::SetClipboard(currentTag);
            Notify("Copied: " + currentTag);
        }

        bool changed = false;
        m_newTag = UI::InputText("New Tag", m_newTag, changed);

        UI::BeginDisabled(loading);
        UI::Text("Preview: " + Text::OpenplanetFormatCodes(m_newTag));
        if (UI::Button("Set Tag")) {
            loading = true;
            startnew(OnClickSetTag);
        }
        UI::EndDisabled();

        if (loading) {
            UI::Text("Setting tag...");
        }

        if (m_error.Length > 0) {
            UI::Text("Response Error: " + m_error);
        }
    }

    string m_error = "";
    bool loading = false;
    string[] payloadKeys = {"name", "tag", "description", "state", "iconTheme", "decalTheme", "backgroundTheme", "verticalTheme", "screen16x9Theme", "screen8x1Theme", "screen16x1Theme"};
    void OnClickSetTag() {
        if (clubId != 55829 && clubId != 71821)
            throw("wrong club");
        m_error = "";
        Json::Value@ data = Json::Object();
        for (uint i = 0; i < payloadKeys.Length; i++) {
            data[payloadKeys[i]] = club[payloadKeys[i]];
        }
        data["tag"] = m_newTag;
        auto resp = SetClubDetails(clubId, data);
        trace("Edit club tag resp: " + Json::Write(resp));
        loading = false;

        // error
        if (resp.GetType() == Json::Type::Array) {
            m_error = resp[0];
        } else {
            resp['role'] = club['role'];
            @club = resp;
            // active = false;
            startnew(cb, resp);
        }
    }
}
#endif
