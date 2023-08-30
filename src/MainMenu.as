/** Render function called every frame intended only for menu items in the main menu of the `UI`.
*/
void RenderMenuMain() {
    auto app = cast<CGameManiaPlanet>(GetApp());
    auto net = cast<CTrackManiaNetwork>(app.Network);
    auto si = cast<CTrackManiaNetworkServerInfo>(net.ServerInfo);
    if (si is null) return;
    if (app.PlaygroundScript !is null) return;
    if (app.CurrentPlayground is null) return;
    if (si.JoinLink.Length == 0) return;
    // should be on a server, now
    if (UI::BeginMenu(ColorPluginIcon + "\\$z BRM")) {
        Draw_BRM_QuickMenu(net, si);
        UI::EndMenu();
    }
}

void Draw_BRM_QuickMenu(CTrackManiaNetwork@ net, CTrackManiaNetworkServerInfo@ si) {
    CopyLabel("\\$aaaServer", si.ServerName);
    CopyLabel("\\$aaaServerLogin", si.ServerLogin);
    auto extra = BRM::GetCurrentServerInfo(GetApp(), false);
    if (extra !is null && extra.clubId > 0) {
        CopyLabel("\\$aaaClub ID", tostring(extra.clubId));
    }
    if (extra !is null && extra.roomId > 0) {
        CopyLabel("\\$aaaRoom ID", tostring(extra.roomId));
    }
    if (!WatchServer::FinishedLoading) {
        UI::Text("\\$888  Detecting Club/Room ID...");
    }

    UI::Separator();

    if (UI::MenuItem("Copy JoinLink")) {
        IO::SetClipboard(si.JoinLink);
        Notify("Copied: " + si.JoinLink);
    }
    AddSimpleTooltip(si.JoinLink);

    UI::Separator();

    auto pcsapi = net.PlaygroundClientScriptAPI;
    UI::BeginDisabled(pcsapi.Request_IsInProgress || pcsapi.Vote_CanVote || pcsapi.Vote_Question.Length > 0);
    if (UI::MenuItem("Call Vote: Next Map")) {
        pcsapi.RequestNextMap();
    }

    UI::Separator();

    if (UI::MenuItem("Call Vote: Restart Map")) {
        pcsapi.RequestRestartMap();
    }
    // if (UI::MenuItem("Call Vote: Restart Map")) {
    //     pcsapi.MapList_Request();
    // }
    UI::EndDisabled();

    if (lastJoinedRoomLink == si.JoinLink && lastJoinedRoomTab !is null) {
        Draw_BRM_QuickMenu_Admin();
    }
}

void Draw_BRM_QuickMenu_Admin() {
    auto roomTab = lastJoinedRoomTab;
    if (roomTab is null) return;

}
