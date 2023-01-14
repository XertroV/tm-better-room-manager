[Setting hidden]
bool WindowOpen = true;

bool ShowAddMapsWindow = false;
bool ShowNotificationsWindow = false;

// should all be free/instant to load
UI::Font@ subheadingFont = UI::LoadFont("DroidSans-Bold.ttf", 16);
UI::Font@ headingFont = UI::LoadFont("DroidSans.ttf", 20);
UI::Font@ titleFont = UI::LoadFont("DroidSans.ttf", 26);


const string PluginIcon = Icons::BuildingO;
const string MenuTitle = "\\$3f3" + PluginIcon + "\\$z " + Meta::ExecutingPlugin().Name;

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
    RenderMapMonitorWindow();
    RenderAddMapWindow();
}

void RenderMapMonitorWindow() {
    if (!WindowOpen) return;
    vec2 size = vec2(1200, 700);
    vec2 pos = (vec2(Draw::GetWidth(), Draw::GetHeight()) - size) / 2.;
    UI::SetNextWindowSize(int(size.x), int(size.y), UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(int(pos.x), int(pos.y), UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));
    if (UI::Begin(MenuTitle, WindowOpen)) {
        UI::BeginTabBar("rm-tabs", UI::TabBarFlags::AutoSelectNewTabs);
        for (uint i = 0; i < mainTabs.Length; i++) {
            mainTabs[i].DrawTab();
        }
        UI::EndTabBar();
    }
    UI::End();
    UI::PopStyleColor();
}

array<Tab@> mainTabs;

void SetUpTabs() {
    // mainTabs.InsertLast(AboutTab());
    mainTabs.InsertLast(ClubsTab());
}




// class AboutTab : Tab {
//     AboutTab() {
//         super(Icons::InfoCircle + " About", false);
//     }

//     void DrawTab() override {
//         if (!tabOpen || !S_ShowAboutTab) return;
//         if (UI::BeginTabItem(tabName, S_ShowAboutTab, TabFlags)) {
//             DrawTogglePop();
//             DrawInner();
//             UI::EndTabItem();
//         }
//     }

//     void DrawInner() override {
//         UI::Markdown("""
//  # About Map Monitor

//  Map Monitor (MM) will monitor maps for: top times, a player's time/rank, and the number of players.
//  Data gathered is saved to a database and available for analysis.

//  ## Using MM

//  To use MM, you must add at least 2 things: a map, and a watcher.
//  Watchers are how you tell MM what data to monitor a map for.
//  Each watcher applies to exactly one map.
//  Once a watcher is added, MM will start gathering relevant data for that map.

//  To recieve notifications, you need to set up a notify rules (or just 'rules').
//  A rule tells MM what events you should be notified about.
//  For example:
//  - Your rank decreases (someone beats your time)
//  - If a player's PB improves
//  - If a player beats your time (a specific player, or any)
//  - If someone plays your map (or when thresholds are reached, like 100 players, 1000 players, etc)
//  - Summary data: like how many people played your maps in the last week

//  Notifications are put in your inbox, and you can browse past notifications, too.

//  ## Feedback, Suggestions, Bugs, etc

//  - [Map Monitor thread on the Openplanet Discord](https://discord.com/channels/276076890714800129/1062289118647824414)
//  - [Github Repo Issues](https://github.com/XertroV/tm-map-monitor/issues)
//  - @XertroV on the Openplanet Discord

//         """);
//     }
// }


class RulesTab : Tab {
    RulesTab() {
        super(Icons::Table + " Rules", false);
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
}


class InboxTab : Tab {
    InboxTab() {
        super(Icons::Inbox + " Inbox", false);
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
}

class TopTimesTab : Tab {
    TopTimesTab() {
        super(Icons::Trophy + " Top Times", false);
        icon = Icons::Trophy;
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
}

class TimesTab : Tab {
    TimesTab() {
        super(Icons::ClockO + " Pb Times", false);
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
}

class RanksTab : Tab {
    RanksTab() {
        super(Icons::ListOl + " Ranks", false);
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
}

class NbPlayersTab : Tab {
    NbPlayersTab() {
        super(Icons::Users + " Nb Players", false);
    }

    void DrawInner() override {
        // DrawControlBar();
        UI::Separator();
        // DrawMapsTable();
    }
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




void SubHeading(const string &in text) {
    UI::PushFont(subheadingFont);
    UI::AlignTextToFramePadding();
    UI::Text(text);
    UI::PopFont();
}
