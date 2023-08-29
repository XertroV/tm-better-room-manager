namespace BRM {
    string GetModeSettingType(const string &in settingName) {
        if (settingToType.Exists(settingName)) {
            string type;
            settingToType.Get(settingName, type);
            return type;
        }
        NotifyWarning("Unknown Setting: " + settingName);
        return "Unknown Setting: " + settingName;
    }

    IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId) {
        return RoomSettingsBuilder(clubId, roomId);
    }

    // may yield
    const Json::Value@ GetMyClubs() {
        while (mainClubsTab is null) yield();
        while (mainClubsTab.loading) yield();
        return mainClubsTab.myClubs;
    }

    const Json::Value@ GetClubRooms(uint clubId) {
        // clubId
        return null;
    }


    bool IsInAServer(CGameCtnApp@ app) {
        return WatchServer::IsInAServer(cast<CTrackMania>(app));
    }

    ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true) {
        auto tm = cast<CTrackMania>(app);
        if (IsInAServer(tm)) {
            while (waitForClubId && !WatchServer::FinishedLoading) yield();
            return ServerInfo(WatchServer::ServerLogin, WatchServer::ServerName, WatchServer::ClubId, WatchServer::RoomId);
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
        IRoomSettingsBuilder@ GetCurrentSettingsAsync() {
            @currSettings = GetClubRoom(clubId, roomId);
            data['maps'] = Json::Array();
            for (uint i = 0; i < currSettings['room']['maps'].Length; i++) {
                data['maps'].Add(currSettings['room']['maps'][i]);
            }
            data['script'] = currSettings['room']['script'];
            data['scalable'] = bool(currSettings['room']['scalable']) ? 1 : 0;
            data['maxPlayersPerServer'] = currSettings['room']['maxPlayers'];
            data['settings'] = Json::Array();
            auto ssKeys = currSettings['room']['scriptSettings'].GetKeys();
            for (uint i = 0; i < ssKeys.Length; i++) {
                data['settings'].Add(currSettings['room']['scriptSettings'][ssKeys[i]]);
            }
            return this;
        }

        IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false) {
            this.gameMode = mode;
            data['script'] = GameModeToFullModeString(mode);
            if (withDefaultSettings) {
                warn('todo: default settings');
            }
            return this;
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

        // Set the chat time (seconds)
        IRoomSettingsBuilder@ GoToNextMapAndThenSetTimeLimit(const string &in mapUid, int limit, int ct = 1) {
            auto builder = this.SetTimeLimit(1).SetChatTime(ct).SetMaps({mapUid});
            auto resp = builder.SaveRoom();
            sleep(3000);
            builder.SetTimeLimit(limit);
            builder.SaveRoom();
            return builder;
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
