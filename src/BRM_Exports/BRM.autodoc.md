## Functions

### CreateRoomBuilder -- `IRoomSettingsBuilder@ CreateRoomBuilder(uint clubId, uint roomId)`

### GameModeFromStr -- `GameMode GameModeFromStr(const string &in modeStr)`

### GameModeToFullModeString -- `const string GameModeToFullModeString(GameMode m)`

### GetClubRooms -- `const Json::Value@ GetClubRooms(uint clubId)`

### GetCurrentServerInfo -- `ServerInfo@ GetCurrentServerInfo(CGameCtnApp@ app, bool waitForClubId = true)`

### GetModeSettingType -- `string GetModeSettingType(const string &in settingName)`

### GetMyClubs -- `const Json::Value@ GetMyClubs()`

Returns a JSON Array of JSON Objects.
The format is equivalent to under .clubList in the payload returned by <https://webservices.openplanet.dev/live/clubs/clubs-mine>
There are some additional fields, like nameSafe, tagSafe, and isAdmin (dump the json object for everything)

### IsInAServer -- `bool IsInAServer(CGameCtnApp@ app)`

### JoinLinkReady -- `bool JoinLinkReady(Json::Value@ pl)`

### JoinServer -- `void JoinServer(uint clubId, uint roomId, const string &in password = "")`

join a server via clubId + roomId

# Types/Classes

## BRM::GameMode (enum)

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


## BRM::IRoomSettingsBuilder (class)

### Functions

#### AddMaps -- `IRoomSettingsBuilder@ AddMaps(const array<string> &in maps)`

Add a map to the rooms map list

#### GetCurrentSettingsAsync -- `IRoomSettingsBuilder@ GetCurrentSettingsAsync()`

Populate based on current room settings. This function may yield.

#### GoToNextMapAndThenSetTimeLimit -- `IRoomSettingsBuilder@ GoToNextMapAndThenSetTimeLimit(const string &in mapUid, int limit, int ct = 1)`

This will yield! An easy 'go to next map' command for club rooms in TimeAttack mode. Duration is 5s + 2 http requests to nadeo.

#### SaveRoom -- `Json::Value@ SaveRoom()`

saves the room and returns the result; will yield internally

#### SaveRoomInCoro -- `IRoomSettingsBuilder@ SaveRoomInCoro()`

Save the room; returns immediately

#### SetChatTime -- `IRoomSettingsBuilder@ SetChatTime(int ct)`

Set the chat time (seconds)

#### SetMaps -- `IRoomSettingsBuilder@ SetMaps(const array<string> &in maps)`

Set the rooms map list

#### SetMode -- `IRoomSettingsBuilder@ SetMode(GameMode mode, bool withDefaultSettings = false)`

Set the room game mode

#### SetModeSetting -- `IRoomSettingsBuilder@ SetModeSetting(const string &in key, const string &in value)`

Set a game mode setting (e.g., S_TimeLimit)

#### SetName -- `IRoomSettingsBuilder@ SetName(const string &in name)`

Set the room name

#### SetPlayerLimit -- `IRoomSettingsBuilder@ SetPlayerLimit(uint limit)`

Set the room player limit (1 - 100)

#### SetTimeLimit -- `IRoomSettingsBuilder@ SetTimeLimit(int limit)`

Set the time limit (seconds)

## BRM::ServerInfo (class)

### Properties

#### clubId -- `int clubId`

#### login -- `string login`

#### name -- `string name`

#### roomId -- `int roomId`
