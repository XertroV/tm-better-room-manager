### Functions

#### CreateRoomBuilder -- `IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId)`

Create an IRoomSettingsBuilder object for a given club and room

#### GameModeFromStr -- `GameMode GameModeFromStr(const string &in modeStr)`

Returns a `BRM::GameMode` based on the script path, e.g., "TrackMania/TM_Cup_Online.Script.txt"

#### GameModeToFullModeString -- `const string GameModeToFullModeString(GameMode m)`

Returns a scirpt path, e.g., "TrackMania/TM_Cup_Online.Script.txt", for a given `BRM::GameMode`

#### GetCurrentServerInfo -- `ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true)`

Returns some basic info for the current server, including Club and Room IDs. Yields if waitForClubId=true otherwise might return null if club/room ID detection is still loading.

#### GetModeSettingType -- `string GetModeSettingType(const string &in settingName)`

Get the setting type (integer, bool, text) for a given setting, e.g., S_TimeLimit

#### GetMyClubs -- `const Json::Value@ GetMyClubs()`

Returns a JSON Array of JSON Objects.
The format is equivalent to under .clubList in the payload returned by <https://webservices.openplanet.dev/live/clubs/clubs-mine>
There are some additional fields, like nameSafe, tagSafe, and isAdmin (dump the json object for everything)

#### GetRoomInfoFromAPI -- `Json::Value@ GetRoomInfoFromAPI(uint clubId, uint roomId)`

Get a room info from the API. <https://webservices.openplanet.dev/live/clubs/room-by-id>

#### IsInAServer -- `bool IsInAServer(CGameCtnApp@ app)`

Returns true if the client is connected to a server

#### JoinServer -- `void JoinServer(uint clubId, uint roomId, const string &in password = "")`

Join a server by getting the joinlink for a given club and room

## Types/Classes

### BRM::GameMode (enum)

- `Unknown`
- `Cup`
- `Knockout`
- `Laps`
- `Teams`
- `TimeAttack`
- `Rounds`
- `RoyalTimeAttack`
- `TMWTTeams`
- `TMWTMatchmaking`
- `TeamsMatchmaking`
- `TimeAttackDaily`
- `KnockoutDaily`
- `COTDQualifications`
- `CupClassic`
- `ChampionSpring2022`
- `MultiTeams`
- `HeadToHead`
- `Final42TMGL`
- `XXX_LAST`


### BRM::IRoomSettingsBuilder (interface)

#### Functions

##### AddMaps -- `IRoomSettingsBuilder@ AddMaps(const array<string> &in maps)`

Add a map to the rooms map list

##### LoadCurrentSettingsAsync -- `IRoomSettingsBuilder@ LoadCurrentSettingsAsync()`

Populate based on current room settings. This function may yield.

##### GetCurrentSettingsJson -- `Json::Value@ GetCurrentSettingsJson()`

Get the current raw settings json object (which is mutable). Call LoadCurrentSettingsAsync first to load current settings.

##### GoToNextMapAndThenSetTimeLimit -- `IRoomSettingsBuilder@ GoToNextMapAndThenSetTimeLimit(const string &in mapUid, int limit = -1, int ct = 1)`

This will yield! An easy 'go to next map' command for club rooms in TimeAttack mode. Duration is 5s + 2 http requests to nadeo.

##### GetModeSetting -- `string GetModeSetting(const string &in key)`

Gets a game mode setting's current value. Throws if it does not exist.

##### HasModeSetting -- `bool HasModeSetting(const string &in key)`

Whether a game mode setting exists (note: you probably want to call LoadCurrentSettingsAsync first)

##### SaveRoom -- `Json::Value@ SaveRoom()`

saves the room and returns the result; will yield internally

##### SaveRoomInCoro -- `IRoomSettingsBuilder@ SaveRoomInCoro()`

Save the room; returns immediately

##### SetChatTime -- `IRoomSettingsBuilder@ SetChatTime(int ct)`

Set the chat time (seconds)

##### SetLoadingScreenUrl -- `IRoomSettingsBuilder@ SetLoadingScreenUrl(const string &in url)`

Set the loading screen image URL

##### SetMaps -- `IRoomSettingsBuilder@ SetMaps(const array<string> &in maps)`

Set the rooms map list

##### SetMode -- `IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false)`

Set the room game mode

##### SetModeSetting -- `IRoomSettingsBuilder@ SetModeSetting(const string &in key, const string &in value)`

Set a game mode setting (e.g., S_TimeLimit)

##### SetName -- `IRoomSettingsBuilder@ SetName(const string &in name)`

Set the room name

##### SetPlayerLimit -- `IRoomSettingsBuilder@ SetPlayerLimit(uint limit)`

Set the room player limit (1 - 100)

##### SetTimeLimit -- `IRoomSettingsBuilder@ SetTimeLimit(int limit)`

Set the time limit (seconds)

### BRM::ServerInfo (class)

#### Properties

##### clubId -- `int clubId`

##### login -- `string login`

##### name -- `string name`

##### roomId -- `int roomId`
