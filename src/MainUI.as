[Setting hidden]
bool WindowOpen = true;

bool ShowAddMapsWindow = false;
bool ShowNotificationsWindow = false;

// should all be free/instant to load
UI::Font@ subheadingFont = UI::LoadFont("DroidSans-Bold.ttf", 16);
UI::Font@ headingFont = UI::LoadFont("DroidSans.ttf", 20);
UI::Font@ titleFont = UI::LoadFont("DroidSans.ttf", 26);


const string PluginIcon = Icons::BuildingO;
const string ColorPluginIcon = "\\$f83" + PluginIcon;
const string MenuTitle = ColorPluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

uint g_NbNotifications = 1;

/** Render function called every frame intended only for menu items in `UI`.
*/
void RenderMenu() {
    // string notifs = g_NbNotifications == 0 ? "" : ("\\$f22(" + g_NbNotifications + ")");
    if (UI::MenuItem(MenuTitle, "", WindowOpen)) {
        WindowOpen = !WindowOpen;
    }
}

void RenderMainUI() {
    RenderRoomManagerWindow();
    RenderAddMapWindow();
}

void RenderRoomManagerWindow() {
    if (!WindowOpen) return;
    vec2 size = vec2(1200, 700);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    if (UI::Begin(MenuTitle, WindowOpen)) {
        UI::BeginDisabled(IsAnyChooserActive());
        UI::BeginTabBar("rm-tabs", UI::TabBarFlags::AutoSelectNewTabs);
        for (uint i = 0; i < mainTabs.Length; i++) {
            mainTabs[i].DrawTab();
        }
        UI::EndTabBar();
        UI::EndDisabled();
    }
    UI::End();
}

array<Tab@> mainTabs;
ClubsTab@ mainClubsTab;

void SetUpTabs() {
    // mainTabs.InsertLast(AboutTab());
    @mainClubsTab = ClubsTab();
    mainTabs.InsertLast(mainClubsTab);
#if DEV
    // auto @statClub = RoomsTab(82393, "Stat's club", "", "admin");
    // mainTabs.InsertLast(statClub);
    // mainTabs.InsertLast(RoomTab(statClub, 703876, "the room", true, true));
    // auto @builder = BRM::CreateRoomBuilder(82393, 703876);
    // builder.LoadCurrentSettingsAsync();
    // print("got room config: " + Json::Write(builder.GetCurrentSettingsJson()));
    // hmm works fine, why did he get a bad response?
#endif
}

void MarkRoomTabStale(int roomId) {
    for (uint i = 0; i < mainTabs.Length; i++) {
        auto rt = cast<RoomTab>(mainTabs[i]);
        if (rt is null) continue;
        if (rt.roomId != roomId) continue;
        startnew(CoroutineFunc(rt.LoadRoom));
        break;
    }
}


bool IsAnyChooserActive() {
    return PresetChooser::active
        || RandomMapsChooser::active
        || ScriptOptChooser::active
        || MapChooser::active
        || PresetSaver::active
        ;
}




string m_addMapUid;
void RenderAddMapWindow() {
    if (!ShowAddMapsWindow) return;
    UI::SetNextWindowSize(400, 400, UI::Cond::FirstUseEver);
    if (UI::Begin("Add Map", ShowAddMapsWindow)) {
        UI::AlignTextToFramePadding();
        UI::Text("Search for map:");
        m_addMapUid = UI::InputText("Map UID", m_addMapUid);
    }
    UI::End();
}


vec4 colNotifBtnBg = vec4(0.641f, 0.121f, 0.121f, 1.f);
vec4 colNotifBtnBgActive = vec4(0.851f, 0.192f, 0.192f, 1.000f);
vec4 colNotifBtnBgHovered = vec4(0.981f, 0.269f, 0.269f, 1.000f);

void NotificationsCtrlButton(vec2 size) {
    if (g_NbNotifications == 0) {
        ControlButton(Icons::Inbox + "##notifs", OnClickShowNotifications, size);
        return;
    }
    UI::PushStyleColor(UI::Col::Button, colNotifBtnBg);
    UI::PushStyleColor(UI::Col::ButtonActive, colNotifBtnBgActive);
    UI::PushStyleColor(UI::Col::ButtonHovered, colNotifBtnBgHovered);
    ControlButton(tostring(g_NbNotifications) + "##notifs", OnClickShowNotifications, size);
    UI::PopStyleColor(3);
}


void OnClickShowNotifications() {
    ShowNotificationsWindow = true;
}

bool ControlButton(const string &in label, CoroutineFunc@ onClick, vec2 size = vec2()) {
    bool ret = UI::Button(label, size);
    if (ret) startnew(onClick);
    UI::SameLine();
    return ret;
}


void CopyLabel(const string &in label, const string &in value) {
    UI::Text(label + ": " + value);
    if (UI::IsItemHovered()) UI::SetMouseCursor(UI::MouseCursor::Hand);
    if (UI::IsItemClicked()) {
        Notify("Copying: " + value);
        IO::SetClipboard(value);
    }
}



void SubHeading(const string &in text) {
    UI::PushFont(subheadingFont);
    UI::AlignTextToFramePadding();
    UI::Text(text);
    UI::PopFont();
}
