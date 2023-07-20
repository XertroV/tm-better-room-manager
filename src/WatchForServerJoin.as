namespace WatchServer {

    void Main() {
        auto app = cast<CTrackMania>(GetApp());
        while (true) {
            yield();
            while (!IsInAServer(app)) yield();
            startnew(OnJoinedServer);
            while (IsInAServer(app)) yield();
            startnew(OnLeftServer);
        }
    }

    bool IsInAServer(CTrackMania@ app) {
        if (app.ManiaPlanetScriptAPI is null) return false;
        return app.ManiaPlanetScriptAPI.CurrentServerLogin.Length > 0;
    }

    string ServerLogin;
    string ServerName;
    int ClubId = -1;

    void OnJoinedServer() {
        auto app = cast<CTrackMania>(GetApp());
        ServerLogin = app.ManiaPlanetScriptAPI.CurrentServerLogin;
        ServerName = app.ManiaPlanetScriptAPI.CurrentServerName;
        ClubId = -1;
        auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
        auto declaredVars = tostring(app.Network.ClientManiaAppPlayground.Dbg_DumpDeclareForVariables(si.TeamProfile1, false));
        while (app.Network.ClientManiaAppPlayground !is null && !declaredVars.Contains("Net_DecoImage_ClubId = ")) {
            sleep(1000);
            declaredVars = tostring(app.Network.ClientManiaAppPlayground.Dbg_DumpDeclareForVariables(si.TeamProfile1, false));
        }
        auto parts = declaredVars.Split("Net_DecoImage_ClubId = ");
        if (parts.Length <= 1) return;
        ClubId = Text::ParseInt(parts[1].Split("\n")[0]);
        print("Joined server with ClubId: " + ClubId + " / ServerLogin: " + ServerLogin);
    }

    void OnLeftServer() {
        // auto app = cast<CTrackMania>(GetApp());
        ServerLogin = "";
        ServerName = "";
        ClubId = -1;
    }
}
