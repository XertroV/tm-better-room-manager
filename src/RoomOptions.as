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

namespace RoomOpts {
    [Setting hidden]
    bool RoomOptsWindowOpen = true;

    void Render() {
        if (!RoomOptsWindowOpen) return;
        DrawMainWindow();
    }

    string name;
    bool public = true;
    SvrLoc region = SvrLoc::EuWest;
    uint maxPlayers = 64; // 2 to 100
    bool scalable = false;
    bool passworded = false;

    bool _creatingRoom = false;

    void DrawMainWindow() {
        UI::SetNextWindowSize(700, 400, UI::Cond::FirstUseEver);
        UI::PushID("room-opts");
        UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, 1));
        if (UI::Begin("Room Options", RoomOptsWindowOpen)) {
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
        UI::End();
        UI::PopStyleColor();
        UI::PopID();
    }

    void DrawLocationCombo() {
        if (UI::BeginCombo("Server Loc.", SvrLocStr(region))) {
            if (UI::Selectable(SvrLocStr(SvrLoc::EuWest), region == SvrLoc::EuWest)) region = SvrLoc::EuWest;
            if (UI::Selectable(SvrLocStr(SvrLoc::CaCentral), region == SvrLoc::CaCentral)) region = SvrLoc::CaCentral;
            UI::EndCombo();
        }
    }

    void DrawGameModeSettings() {
        if (UI::CollapsingHeader("Game Mode Options")) {
        // todo

        }
    }

    void DrawSaveButton() {
        UI::BeginDisabled(IsInvalidSettings);
        if (UI::Button(_creatingRoom ? "Create Room" : "Update Room")) OnClickSaveRoom();
        UI::EndDisabled();
    }

    void OnClickSaveRoom() {

    }

    bool IsInvalidSettings {
        get {
            return false;
        }
    }
}
