namespace BRM {
    // Get the setting type (integer, bool, text) for a given setting, e.g., S_TimeLimit
    string GetModeSettingType(const string &in settingName) {
        if (settingToType.Exists(settingName)) {
            string type;
            settingToType.Get(settingName, type);
            return type;
        }
        NotifyWarning("Unknown Setting: " + settingName);
        return "Unknown Setting: " + settingName;
    }

    // Create an IRoomSettingsBuilder object for a given club and room
    IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId) {
        return RoomSettingsBuilder(clubId, roomId);
    }

    /** Returns a JSON Array of JSON Objects.
     *  The format is equivalent to under .clubList in the payload returned by <https://webservices.openplanet.dev/live/clubs/clubs-mine>
     *  There are some additional fields, like nameSafe, tagSafe, and isAdmin (dump the json object for everything)
    */
    const Json::Value@ GetMyClubs() {
        while (mainClubsTab is null) yield();
        while (mainClubsTab.loading) yield();
        return mainClubsTab.myClubs;
    }

    // Get a room info from the API. <https://webservices.openplanet.dev/live/clubs/room-by-id>
    Json::Value@ GetRoomInfoFromAPI(uint clubId, uint roomId) {
        return GetClubRoom(clubId, roomId);
    }

    // Join a server by getting the joinlink for a given club and room
    void JoinServer(uint clubId, uint roomId, const string &in password = "") {
        string pw;
        if (password.Length > 0) {
            pw = ":" + password;
        }
        Json::Value@ joinLink = GetJoinLink(clubId, roomId);
        uint count = 0;
        while (!JoinLinkReady(joinLink) && count < 10) {
            count++;
            sleep(2000);
            @joinLink = GetJoinLink(clubId, roomId);
        }
        if (count >= 10) {
            throw("No server was available after 10 retries (20+ seconds)");
        }
        string jl = joinLink.Get('joinLink', '');
        lastJoinedRoomLink = jl.Replace("#join", "#qjoin") + pw;
        ReturnToMenu();
        trace("Joining: " + lastJoinedRoomLink);
        cast<CGameManiaPlanet>(GetApp()).ManiaPlanetScriptAPI.OpenLink(lastJoinedRoomLink, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
    }

    bool JoinLinkReady(Json::Value@ pl) {
        if (pl is null || pl.GetType() != Json::Type::Object) return false;
        if (!pl.HasKey("joinLink") || !pl.HasKey("starting")) return false;
        if (bool(pl.Get("starting", true))) return false;
        return true;
    }

    // Returns true if the client is connected to a server
    bool IsInAServer(CGameCtnApp@ app) {
        return WatchServer::IsInAServer(cast<CTrackMania>(app));
    }

    // Returns some basic info for the current server, including Club and Room IDs. Yields if waitForClubId=true otherwise might return null if club/room ID detection is still loading.
    ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true) {
        auto tm = cast<CTrackMania>(app);
        if (IsInAServer(tm)) {
            while (waitForClubId && !WatchServer::FinishedLoading) yield();
            if (!waitForClubId && !WatchServer::FinishedLoading) return null;
            return ServerInfo(WatchServer::ServerLogin, WatchServer::ServerName, WatchServer::ClubId, WatchServer::RoomId, WatchServer::IsAdmin);
        }
        return null;
    }


    class RoomSettingsBuilder : IRoomSettingsBuilder {
        uint clubId;
        uint roomId;
        GameMode gameMode = GameMode::Unknown;

        Json::Value@ data = Json::Object();
        Json::Value@ currSettings = null;

        RoomSettingsBuilder(uint clubId, uint roomId) {
            this.clubId = clubId;
            this.roomId = roomId;
        }

        // Populate based on current room settings. This function may yield.
        IRoomSettingsBuilder@ LoadCurrentSettingsAsync() {
            @currSettings = GetClubRoom(clubId, roomId);
            data['maps'] = Json::Array();
            for (uint i = 0; i < currSettings['room']['maps'].Length; i++) {
                data['maps'].Add(currSettings['room']['maps'][i]);
            }
            data['script'] = currSettings['room']['script'];
            gameMode = GameModeFromStr(data['script']);
            data['scalable'] = bool(currSettings['room']['scalable']) ? 1 : 0;
            data['maxPlayersPerServer'] = currSettings['room']['maxPlayers'];
            data['settings'] = Json::Array();
            auto ssKeys = currSettings['room']['scriptSettings'].GetKeys();
            for (uint i = 0; i < ssKeys.Length; i++) {
                data['settings'].Add(currSettings['room']['scriptSettings'][ssKeys[i]]);
            }
            return this;
        }

        Json::Value@ GetCurrentSettingsJson() {
            return data;
        }

        IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false) {
            this.gameMode = mode;
            data['script'] = GameModeToFullModeString(mode);
            if (withDefaultSettings) {
                warn('todo: default settings');
            }
            return this;
        }

        bool HasModeSetting(const string &in key) {
            for (uint i = 0; i < data['settings'].Length; i++) {
                auto @s = data['settings'][i];
                if (string(s['key']) == key) {
                    return true;
                }
            }
            return false;
        }

        string GetModeSetting(const string &in key) {
            for (uint i = 0; i < data['settings'].Length; i++) {
                auto @s = data['settings'][i];
                if (string(s['key']) == key) {
                    return s['value'];
                }
            }
            throw("Key not found in settings");
            return "";
        }

        IRoomSettingsBuilder@ SetModeSetting(const string &in key, const string &in value) {
            auto s = Json::Object();
            auto type = BRM::GetModeSettingType(key);
            if (type.StartsWith("Unknown Setting")) {
                throw(type);
            }
            s['type'] = BRM::GetModeSettingType(key);
            s['key'] = key;
            s['value'] = value;
            this.AddSetting(s);
            return this;
        }

        protected void AddSetting(Json::Value@ s) {
            if (!data.HasKey('settings') || data['settings'].GetType() != Json::Type::Array) {
                data['settings'] = Json::Array();
            }
            for (uint i = 0; i < data['settings'].Length; i++) {
                if (string(data['settings'][i]['key']) == string(s['key'])) {
                    data['settings'][i] = s;
                    return;
                }
            }
            data['settings'].Add(s);
        }


        // Set the time limit (seconds)
        IRoomSettingsBuilder@ SetTimeLimit(int limit) {
            return this.SetModeSetting("S_TimeLimit", tostring(limit));
        }

        // Set the chat time (seconds)
        IRoomSettingsBuilder@ SetChatTime(int ct) {
            return this.SetModeSetting("S_ChatTime", tostring(ct));
        }

        IRoomSettingsBuilder@ SetLoadingScreenUrl(const string &in url) {
            return this.SetModeSetting("S_LoadingScreenImageUrl", url);
        }

        // This will yield! An easy 'go to next map' command for club rooms in TimeAttack mode. Duration is 5s + 2 http requests to nadeo.
        IRoomSettingsBuilder@ GoToNextMapAndThenSetTimeLimit(const string &in mapUid, int limit = -1, int chat_time = 1) {
            this.SetTimeLimit(1)
                .SetChatTime(chat_time)
                .SetModeSetting("S_DelayBeforeNextMap", "1")
                .SetMaps({mapUid})
                .SetMode(BRM::GameMode::TimeAttack);

            auto resp = this.SaveRoom();
            sleep(5000);
            this.SetTimeLimit(limit);
            auto resp2 = this.SaveRoom();
            return this;
        }


        IRoomSettingsBuilder@ SetPlayerLimit(uint limit) {
            data['maxPlayersPerServer'] = limit;
            return this;
        }

        IRoomSettingsBuilder@ SetName(const string &in roomName) {
            data['name'] = roomName;
            return this;
        }

        IRoomSettingsBuilder@ SetMaps(const array<string> &in maps) {
            data['maps'] = Json::Array();
            for (uint i = 0; i < maps.Length; i++) {
                data['maps'].Add(maps[i]);
            }
            return this;
        }

        IRoomSettingsBuilder@ AddMaps(const array<string> &in maps) {
            if (!data.HasKey('maps')) {
                data['maps'] = Json::Array();
            }
            for (uint i = 0; i < maps.Length; i++) {
                data['maps'].Add(maps[i]);
            }
            return this;
        }

        // returns immediately
        IRoomSettingsBuilder@ SaveRoomInCoro() {
            startnew(CoroutineFunc(this.SaveRoomCoro));
            return this;
        }

        // to be run via startnew
        void SaveRoomCoro() {
            SaveRoom();
        }

        // saves the room and returns the result
        Json::Value@ SaveRoom() {
            return SaveEditedRoomConfig(clubId, roomId, data);
        }
    }
}
