bool UserHasPermissions = false;

void Main() {
    if (!CheckPermissions()) return;
    InitDirectories();
    AddAudiences();
    SetUpTabs();
    startnew(ClearTaskCoro);
    startnew(WatchServer::Main);
#if DEV
    // startnew(TestCoro);
    trace("Current plugin id: " + Meta::ExecutingPlugin().ID);
#endif
}

bool notifiedPermissionsMissing = false;
bool CheckPermissions() {
    if (!OpenplanetHasFullPermissions()) {
        if (!notifiedPermissionsMissing)
            NotifyError("Missing permissions: This plugin will do nothing. You need club access.");
        notifiedPermissionsMissing = true;
        return false;
    }
    return true;
}


void InitDirectories() {
    string presets = IO::FromStorageFolder("presets");
    if (!IO::FolderExists(presets)) IO::CreateFolder(presets, true);
}

void TestCoro() {
#if DEV
    mainTabs.InsertLast(RoomsTab(46587, 'xert', 'xert', 'Admin'));
    yield();
    auto _ttgRooms = RoomsTab(55829, 'ttg', 'ttg', 'Admin');
    mainTabs.InsertLast(_ttgRooms);
    yield();
    mainTabs.InsertLast(RoomTab(_ttgRooms, 345704, 'test name', true, true));
#endif
}

/** Render function called every frame.
*/
void RenderInterface() {
    if (!CheckPermissions()) return;
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));

    RenderMainUI();
    MapChooser::Render();
    PresetSaver::Render();
    PresetChooser::Render();
    ScriptOptChooser::Render();
    RandomMapsChooser::Render();
    ClubTagSetter::Render();

    UI::PopStyleColor();
}


void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(msg);
        UI::EndTooltip();
    }
}

void CopyToClipboardAndNotify(const string &in toCopy) {
    IO::SetClipboard(toCopy);
    Notify("Copied: " + toCopy);
}

string[]@ Slice(string[] &in list, uint from, uint to) {
    if (to >= list.Length) to = list.Length;
    string[] r;
    for (uint i = from; i < to; i++) {
        r.InsertLast(list[i]);
    }
    return r;
}
