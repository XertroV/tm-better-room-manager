bool UserHasPermissions = false;

void Main() {
    AddAudiences();
    SetUpTabs();
    startnew(MainCoro);
}

void MainCoro() {
    mainTabs.InsertLast(RoomsTab(46587, 'xert', 'xert'));
    yield();
    auto _ttgRooms = RoomsTab(55829, 'ttg', 'ttg');
    mainTabs.InsertLast(_ttgRooms);
    yield();
    mainTabs.InsertLast(RoomTab(_ttgRooms, 345704, 'test name', true));
}

/** Render function called every frame.
*/
void Render() {
    RenderMainUI();
    RoomOpts::Render();
    PresetChooser::Render();
    ScriptOptChooser::Render();
    RandomMapsChooser::Render();
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
