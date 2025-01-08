namespace WatchServer {
    void Main() {
        auto app = cast<CTrackMania>(GetApp());
        while (true) {
            yield();
            while (!IsInAServer(app)) yield();
            lastServerLogin = app.ManiaPlanetScriptAPI.CurrentServerLogin;
            startnew(OnJoinedServer);
            while (IsInAServer(app) && lastServerLogin == app.ManiaPlanetScriptAPI.CurrentServerLogin) yield();
            startnew(OnLeftServer);
        }
    }

    Json::Value@ RefreshRoomsState = Json::Object();
    string lastServerLogin;

    bool IsInAServer(CTrackMania@ app) {
        if (app.ManiaPlanetScriptAPI is null) return false;
        if (app.Network.ClientManiaAppPlayground is null) return false;
        return app.ManiaPlanetScriptAPI.CurrentServerLogin.Length > 0;
    }

    string ServerLogin;
    string ServerName;
    int ClubId = -1;
    int RoomId = -1;
    bool IsAdmin = false;
    bool FinishedLoading = false;

    void OnJoinedServer() {
        auto app = cast<CTrackMania>(GetApp());
        ServerLogin = app.ManiaPlanetScriptAPI.CurrentServerLogin;
        ServerName = app.ManiaPlanetScriptAPI.CurrentServerName;
        ClubId = -1;
        RoomId = -1;
        FinishedLoading = false;
        auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
        auto declaredVars = string(app.Network.ClientManiaAppPlayground.Dbg_DumpDeclareForVariables(si.TeamProfile1, false));
        // wait up to Xs for club ID
        auto maxWait = 60 * 1000;
        int startedAt = Time::Now;
        while (app.Network.ClientManiaAppPlayground !is null
            && !declaredVars.Contains("Net_TMGame_DecoImage_ClubId = ")
            && Time::Now - startedAt < maxWait
            && ServerLogin == app.ManiaPlanetScriptAPI.CurrentServerLogin
        ) {
            declaredVars = string(app.Network.ClientManiaAppPlayground.Dbg_DumpDeclareForVariables(si.TeamProfile1, false));
            sleep(250);
        }
        auto parts = declaredVars.Split("Net_TMGame_DecoImage_ClubId = ");
        FinishedLoading = parts.Length <= 1;
        if (FinishedLoading) return;
        ClubId = Text::ParseInt(parts[1].Split("\n")[0]);
        trace("Joined server with ClubId: " + ClubId + " / ServerLogin: " + ServerLogin);
        _CheckRoomsForClub();
        FinishedLoading = true;
    }

    void _CheckRoomsForClub() {
        // cache this in case we change servers quickly or w/e
        string cid = tostring(ClubId);
        string serverName = ServerName;
        int clubId = ClubId;
        if (clubId <= 0) {
            return;
        }

        // set IsAdmin flag
        auto myClubs = BRM::GetMyClubs();
        for (uint i = 0; i < myClubs.Length; i++) {
            if (ClubId == int(myClubs[i]['id'])) {
                IsAdmin = myClubs[i]['isAnyAdmin'];
                break;
            }
        }

        if (!RefreshRoomsState.HasKey(cid)) {
            _SetRefreshStateDefault(cid);
        }
        auto @j = RefreshRoomsState[cid];
        int lastRefresh = j['lastRefresh'];
        auto @rooms = j['rooms'];
        bool doNotRefresh = rooms.GetType() != Json::Type::Null && lastRefresh > 0 && Time::Now - lastRefresh < (30 * 60 * 1000);
        if (!doNotRefresh) {
            j['lastRefresh'] = Time::Now;
            trace("Refreshing WatchForServerJoin rooms for club: " + cid);
            auto activities = GetClubActivities(clubId, true, 100, 0);
            @rooms = activities['activityList'];
            auto pages = int(activities['maxPage']);
            if (pages > 1) {
                trace("[WARN] Only checking the first page of club activities for club " + cid + " since there are " + pages + " pages");
            }
            j['rooms'] = rooms;
        }
        int foundRoom = -1;
        for (uint i = 0; i < rooms.Length; i++) {
            auto activity = rooms[i];
            if (string(activity['activityType']) != "room") continue;
            if (string(activity['name']) != serverName) continue;
            foundRoom = activity['id'];
            break;
        }
        RoomId = foundRoom;
        trace('Found room: ' + RoomId);
    }

    void _SetRefreshStateDefault(const string &in cid) {
        auto @j = Json::Object();
        j['lastRefresh'] = 0;
        j['room'] = Json::Value();
        RefreshRoomsState[cid] = j;
    }

    void OnLeftServer() {
        // auto app = cast<CTrackMania>(GetApp());
        ServerLogin = "";
        ServerName = "";
        ClubId = -1;
        RoomId = -1;
        FinishedLoading = false;
    }
}


int GetArenaCurrentTimeSeconds() {
    return (PlaygroundNow() - GetRulesStartTime()) / 1000;
}


uint PlaygroundNow() {
    auto app = GetApp();
    auto pg = app.Network.PlaygroundClientScriptAPI;
    if (pg is null) return uint(-1);
    return uint(pg.GameTime);
}

// measured in ms
uint GetRulesStartTime() {
    auto app = GetApp();
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp is null || cp.Arena is null || cp.Arena.Rules is null) return uint(-1);
    return uint(cp.Arena.Rules.RulesStateStartTime);
}

// measured in ms
uint GetRulesEndTime() {
    auto app = GetApp();
    auto cp = cast<CSmArenaClient>(app.CurrentPlayground);
    if (cp is null || cp.Arena is null || cp.Arena.Rules is null) return uint(-1);
    return uint(cp.Arena.Rules.RulesStateEndTime);
}

// int GetSecondsLeft() {
//     return (int64(GetRulesEndTime()) - int64(GetRulesStartTime())) / 1000;
// }


void AwaitPodiumWithTimeout(uint timeout) {
    auto start = Time::Now;
    auto app = GetApp();
    while (Time::Now < start + timeout) {
        auto pg = cast<CSmArenaClient>(app.CurrentPlayground);
        if (pg is null) return;
        if (pg.GameTerminals.Length == 0) return;
        auto gt = pg.GameTerminals[0];
        if (gt is null) return;
        auto seq = gt.UISequence_Current;
        if (seq == SGamePlaygroundUIConfig::EUISequence::Podium
            || seq == SGamePlaygroundUIConfig::EUISequence::UIInteraction
            || seq == SGamePlaygroundUIConfig::EUISequence::None) {
            return;
        }
        yield();
    }
    warn("Timeout waiting for podium");
}
