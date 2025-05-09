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
    if (UI::MenuItem("Main BRM Window", "", WindowOpen)) {
        WindowOpen = !WindowOpen;
    }
    UI::Separator();

    CopyLabel("\\$aaaServer", Text::OpenplanetFormatCodes(si.ServerName));
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

    if (WatchServer::IsAdmin) {
        Draw_BRM_QuickMenu_Admin();
    }
}

int m_CustMoveOnInSeconds = 90;
int m_SetTimeLimitSeconds = -1;

void Draw_BRM_QuickMenu_Admin() {
    UI::Separator();
    UI::AlignTextToFramePadding();
    UI::Text(" >> Room Admin (\\$fa4for TA only\\$z)");
    if (UI::BeginMenu("Set Time Limit")) {
        m_SetTimeLimitSeconds = Math::Clamp(UI::InputInt("Time Limit (S)", m_SetTimeLimitSeconds), -1, 99999);
        string limit = m_SetTimeLimitSeconds <= 0 ? "Unlimited" : Time::Format(m_SetTimeLimitSeconds*1000, false, true, false);
        UI::Text("\\$aaaNew Time Limit: " + limit);
        if (UI::MenuItem("Set Time Limit")) {
            startnew(MenuAdmin_SetTimeLimit, m_SetTimeLimitSeconds);
        }
        UI::EndMenu();
    }
    if (UI::BeginMenu("Move On In...")) {
        if (UI::MenuItem("15 Seconds")) {
            startnew(MenuAdmin_MoveOnInSeconds, 15);
        }
        if (UI::MenuItem("30 Seconds")) {
            startnew(MenuAdmin_MoveOnInSeconds, 30);
        }
        if (UI::MenuItem("1 Minute")) {
            startnew(MenuAdmin_MoveOnInSeconds, 60);
        }
        if (UI::MenuItem("2 Minutes")) {
            startnew(MenuAdmin_MoveOnInSeconds, 120);
        }
        if (UI::MenuItem("5 Minutes")) {
            startnew(MenuAdmin_MoveOnInSeconds, 300);
        }
        // custom
        UI::Separator();
        m_CustMoveOnInSeconds = Math::Clamp(UI::InputInt("Custom (S)", m_CustMoveOnInSeconds), 1, 99999);
        UI::Text("\\$aaaNew remaining time: " + Time::Format(m_CustMoveOnInSeconds*1000, false, true, false));
        string custLabel = m_CustMoveOnInSeconds < 120 ? tostring(m_CustMoveOnInSeconds) + " seconds" : Text::Format("%.1f minutes", float(m_CustMoveOnInSeconds) / 60.0);
        if (UI::MenuItem("Set Move on in " + custLabel)) {
            startnew(MenuAdmin_MoveOnInSeconds, int64(m_CustMoveOnInSeconds));
        }
        UI::EndMenu();
    }
    if (UI::MenuItem("Extend TimeLimit by 5 min")) {
        startnew(MenuAdmin_ExtendTimeLimit_5min);
    }
    if (UI::MenuItem("Go to Next Map")) {
        startnew(MenuAdmin_GoToNextMap);
    }
}

void MenuAdmin_SetTimeLimit(int64 newTimeLimitSeconds) {
    auto builder = BRM::CreateRoomBuilder(WatchServer::ClubId, WatchServer::RoomId);
    builder.LoadCurrentSettingsAsync();
    Notify("Setting room time limit to " + newTimeLimitSeconds + " seconds...");
    builder.SetTimeLimit(newTimeLimitSeconds)
        .SaveRoom();
    Notify("\\$8f8Updated\\$z room time limit to " + newTimeLimitSeconds + " seconds.");
}


uint moiNonce = 0;

void MenuAdmin_MoveOnInSeconds(int64 moiSeconds) {
    moiNonce += 1;
    auto nonce = moiNonce;
    auto builder = BRM::CreateRoomBuilder(WatchServer::ClubId, WatchServer::RoomId);
    builder.LoadCurrentSettingsAsync();
    if (!builder.HasModeSetting("S_TimeLimit")) {
        // set default
        builder.SetModeSetting("S_TimeLimit", "300");
    }
    auto currRoomTimeLimit = Text::ParseInt(builder.GetModeSetting("S_TimeLimit"));
    auto actualCurrArenaTime = GetArenaCurrentTimeSeconds();
    auto newTimeLimit = actualCurrArenaTime + moiSeconds;
    Notify("Setting room time limit to " + newTimeLimit + " seconds");
    builder.SetTimeLimit(newTimeLimit)
        .SaveRoom();
    Notify("\\$8f8Updated\\$z time limit to " + newTimeLimit + " seconds. Waiting for it to activate...");
    sleep(2000 + Math::Max(moiSeconds, 5) * 1000);
    if (nonce != moiNonce) return;
    Notify("Restoring old room time limit: " + currRoomTimeLimit);
    builder.SetTimeLimit(currRoomTimeLimit)
        .SaveRoom();
    Notify("\\$8f8Restored\\$z time limit to " + currRoomTimeLimit + " seconds.");
}

void MenuAdmin_ExtendTimeLimit_5min() {
    auto builder = BRM::CreateRoomBuilder(WatchServer::ClubId, WatchServer::RoomId);
    builder.LoadCurrentSettingsAsync();
    if (!builder.HasModeSetting("S_TimeLimit")) {
        NotifyError("Cannot extend time limit when the setting doesn't exist.");
        return;
    }
    auto currTimeLimit = Text::ParseInt(builder.GetModeSetting("S_TimeLimit"));
    if (currTimeLimit < 0) {
        Notify("Time limit is already set to unlimited");
        return;
    }
    builder.SetTimeLimit(currTimeLimit + 300)
        .SaveRoom();
    Notify("Extended time limit by 5 minutes.");
}

void MenuAdmin_GoToNextMap() {
    auto builder = BRM::CreateRoomBuilder(WatchServer::ClubId, WatchServer::RoomId);
    builder.LoadCurrentSettingsAsync();
    if (!builder.HasModeSetting("S_TimeLimit")) {
        NotifyError("Cannot go to next map when the setting doesn't exist.");
        return;
    }
    auto currTimeLimit = Text::ParseInt(builder.GetModeSetting("S_TimeLimit"));
    builder.SetTimeLimit(1)
        .SaveRoom();
    Notify("Set room time limit to 1 second, should trigger end of round.");
    sleep(6000);
    builder.SetTimeLimit(currTimeLimit).SaveRoom();
    Notify("Restored time limit to " + currTimeLimit + " seconds.");
}
