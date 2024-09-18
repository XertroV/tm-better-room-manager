funcdef void RandomMapsCallback(LazyMap@[]@ maps);

const int NUM_TAGS = 47;

class Tag {
    bool checked;
    TagTypes type;
    Tag(TagTypes type, bool checked = false){
        this.checked = checked;
        this.type = type;
    }
    void setChecked(bool check){
        this.checked = check;
    }
}

enum TagTypes {
    Altered = 49,
    Arena = 40,
    Backwards = 34,
    Bobsleigh = 44,
    Bugslide = 56,
    Bumper = 20,
    Competitive = 13,
    CruiseControl = 62,
    DesertCar = 59,
    Dirt = 15,
    Educational = 42,
    Endurance = 24,
    EngineOff = 35,
    FlagRush = 46,
    Fragile = 21,
    Freeblocking = 48,
    Freestyle = 41,
    FullSpeed = 2,
    Grass = 33,
    Ice = 14,
    Kacky = 23,
    Lol = 5,
    Magnet = 66,
    Mini = 25,
    Minigame = 30,
    Mixed = 27,
    MixedCar = 55,
    MovingItems = 58,
    Mudslide = 57,
    MultiLap = 8,
    Nascar = 28,
    NoBrake = 61,
    NoSteer = 63,
    Obstacle = 31,
    Offroad = 9,
    Pathfinding = 45,
    Pipes = 65,
    Plastic = 39,
    Platform = 18,
    PressForward = 6,
    Puzzle = 47,
    Race = 1,
    RallyCar = 54,
    Reactor = 17,
    Remake = 26,
    Royal = 37,
    Rpg = 4,
    RpgImmersive = 64,
    Sausage = 43,
    Scenery = 22,
    Signature = 36,
    SlowMotion = 19,
    SnowCar = 50,
    SpeedDrift = 29,
    SpeedFun = 12,
    SpeedMapping = 60,
    SpeedTech = 7,
    Stunt = 16,
    Tech = 3,
    Transitional = 32,
    Trial = 10,
    Turtle = 53,
    Underwater = 52,
    Water = 38,
    Wood = 51,
    Zrt = 11
}

array<Tag@> generateTags() {
    array<Tag@> tags;
    for (int i = 1; i <= NUM_TAGS; i++){
        tags.InsertLast(Tag(TagTypes(i), true));
    }
    setAllTagsToDefault(tags);
    return tags;
}

const string toTagString(array<Tag@>& tags){
    string s;
    for (int i = 0; i < NUM_TAGS; i++){
        if(tags[i].checked){
            int n = tags[i].type;
            s += (i > 0 ? "," : "") + tostring(n);
        }
    }
    return s;
}

void setAllTags(array<Tag@>& tags, bool val) {
    for (int i = 0; i < NUM_TAGS; i++) {
        tags[i].setChecked(val);
    }
}

void setAllTagsToDefault(Tag@[]& tags) {
    setAllTags(tags, true);
    // default off: 23,37,40,46,47
    // see API/TMX.as for list used in HTTP request formation
    uint[] defaultOff = {23,37,40,46,47};
    for (uint i = 0; i < defaultOff.Length; i++) {
        if (defaultOff[i] > tags.Length) continue;
        tags[defaultOff[i] - 1].setChecked(false);
    }
}

enum MapDifficulty {
    Beginner = 0,
    Intermediate = 1,
    Advanced = 2,
    Expert = 3,
    Lunatic = 4,
    Impossible = 5
}

MapDifficulty MapDifficultyFromStr(const string &in str) {
    for (uint i = 0; i <= 5; i++) {
        if (tostring(MapDifficulty(i)) == str) return MapDifficulty(i);
    }
    return MapDifficulty(0);
}

namespace RandomMapsChooser {
    bool active = false;
    RandomMapsCallback@ cb = null;
    bool loadingMaps = false;
    LazyMap@[] gotMaps;

    // RM options
    int minLen = 15;
    int maxLen = 120;
    MapDifficulty minDifficulty = MapDifficulty::Beginner;
    MapDifficulty maxDifficulty = MapDifficulty::Intermediate;
    array<Tag@> tags = generateTags();
    bool checkAll = true;
    bool uncheckAll = false;
    int nbMaps = 12;

    bool Open(RandomMapsCallback@ callback) {
        if (active) return false;
        active = true;
        @cb = callback;
        loadingMaps = false;
        gotMaps.RemoveRange(0, gotMaps.Length);
        return true;
    }

    bool WindowOpen {
        get { return active; }
        set {
            if (!value) {
                RunCallback();
            }
        }
    }

    void Render() {
        if (!active) return;
        UI::SetNextWindowSize(850, 640, UI::Cond::Appearing);
        if (UI::Begin("Add Random Maps", WindowOpen)) {
            DrawInner();
        }
        UI::End();
    }

    string chosenKey;
    float btnWidth = 100;
    string blacklist;

    void DrawInner() {
        if (!loadingMaps)
            SubHeading("Map Constraints:");
        else {
            float progWidth = UI::GetContentRegionMax().x - btnWidth - 2. * UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
            // SubHeading("Progress: " + gotMaps.Length + " / " + nbMaps + Text::Format("  (%.1f%%)", float(100 * gotMaps.Length) / float(nbMaps)));
            UI::ProgressBar(float(gotMaps.Length) / float(nbMaps), vec2(progWidth, 0), "Random Maps: " + gotMaps.Length + " / " + nbMaps);
        }

        UI::SameLine();
        UI::BeginDisabled(loadingMaps);
        UI::SetCursorPos(vec2(UI::GetContentRegionMax().x - btnWidth, UI::GetCursorPos().y));
        if (UI::Button("Add Maps##add game opt")) OnChooseRandomSettings();
        btnWidth = UI::GetItemRect().z;

        UI::Separator();
        SubHeading("Length (seconds)");
        minLen = LengthInput('Min: ', minLen);
        if (minLen > maxLen) maxLen = minLen;
        maxLen = LengthInput('Max: ', maxLen);
        if (maxLen < minLen) minLen = maxLen;


        UI::Separator();
        SubHeading("Difficulty (TMX)");
        minDifficulty = DifficultyCombo('Min: ', minDifficulty);
        maxDifficulty = DifficultyCombo('Max: ', maxDifficulty);

        UI::Separator();
        UI::AlignTextToFramePadding();
        UI::Text("Nb Maps: ");
        UI::SameLine();
        nbMaps = UI::SliderInt("##nbmaps", nbMaps, 1, 100);

        UI::Separator();
        if (UI::CollapsingHeader("Tags (TMX)")) {
            if (UI::Button("Defaults")) setAllTagsToDefault(tags);
            UI::SameLine();
            if (UI::Button("Check All")) setAllTags(tags, true);
            UI::SameLine();
            if (UI::Button("Uncheck All")) setAllTags(tags, false);
            DrawTagsCheckboxes(tags);
        }

        UI::Separator();
        if (UI::CollapsingHeader("Map Blacklist")) {
            blacklist = Text::OpenplanetFormatCodes(UI::InputText("Blacklist (mapUid1, mapUid2, ..., mapUidN)", blacklist));
        }

        UI::EndDisabled();
    }

    int LengthInput(const string &in label, int num) {
        UI::AlignTextToFramePadding();
        UI::Text(label);
        UI::SameLine();
        return Math::Clamp(UI::InputInt("##rmc-" + label, num, 15), 15, 300);
    }

    MapDifficulty DifficultyCombo(const string &in label, MapDifficulty md) {
        UI::AlignTextToFramePadding();
        UI::Text(label);
        UI::SameLine();
        MapDifficulty ret = md;
        if (UI::BeginCombo("##difficulty-"+label, tostring(md))) {
            for (uint i = 0; i <= int(MapDifficulty::Impossible); i++) {
                auto _md = MapDifficulty(i);
                if (UI::Selectable(tostring(_md), md == _md)) ret = _md;
            }
            UI::EndCombo();
        }
        return ret;
    }

    void DrawTagsCheckboxes(array<Tag@>& tags) {
        if (tags is null) return;
        UI::AlignTextToFramePadding();
        UI::Columns(6);
        for (uint i = 0; i < tags.Length; i++) {
            if ((i % 8 == 0) && i != 0) {
                UI::NextColumn();
            }
            tags[i].checked = UI::Checkbox(tostring(tags[i].type), tags[i].checked);
        }
        UI::Columns(1);
    }

    void DrawOptSelectable(const string &in key) {
        if (UI::Selectable(key, chosenKey == key)) {
            chosenKey = key;
        }
    }

    void OnChooseRandomSettings() {
        loadingMaps = true;
        startnew(RunGetMaps);
    }

    void RunGetMaps() {
        awaitany({
            startnew(GetMapsTillDone),
            startnew(GetMapsTillDone),
            startnew(GetMapsTillDone),
            startnew(GetMapsTillDone),
            startnew(GetMapsTillDone)
        });
        startnew(RunCallback);
    }

    int LengthNameToSecs(const string &in LengthName) {
        if (LengthName == "Long") {
            return 300;
        } else if (LengthName.Contains(" m ")) {
            auto ps = LengthName.Split(" m ");
            return Text::ParseInt(ps[0]) * 60 + Text::ParseInt(ps[1]);
        } else if (LengthName.Contains(" min")) {
            return 60 * Text::ParseInt(LengthName.Split(" min")[0]);
        } else if (LengthName.Contains(" secs")) {
            return Text::ParseInt(LengthName.Split(" secs")[0]);
        }
        warn("LengthNameToSecs: Unknown length name: " + LengthName);
        return 60;
    }

    void GetMapsTillDone() {
        dictionary blacklistDict = ParseBlacklistToDict(blacklist);
        string tagStr = toTagString(tags);
        while (loadingMaps && int(gotMaps.Length) < nbMaps) {
            auto @newMap = GetARandomMap(tagStr);
            if (newMap is null) continue;
            @newMap = newMap['results'][0];
            // return type: https://api2.mania.exchange/Method/Index/4
            MapDifficulty diff = MapDifficultyFromStr(newMap['DifficultyName']);
            if (diff < minDifficulty || maxDifficulty < diff) continue;
            int len = LengthNameToSecs(newMap['LengthName']);
            if (len < minLen || maxLen < len) continue;
            string mapUid = newMap['TrackUID'];
            if (blacklistDict.Exists(mapUid)) {
                warn("Skipping blacklisted map: " + mapUid);
                continue;
            }

            if (IsMapUploadedToNadeo(mapUid)) {
                if (loadingMaps && int(gotMaps.Length) < nbMaps)
                    gotMaps.InsertLast(LazyMap(mapUid));
            } else {
                warn('skipping unuploaded map: ' + int(newMap['TrackID']) + ", " + mapUid);
            }
        }
    }

    void RunCallback() {
        cb(gotMaps);
        active = false;
        loadingMaps = false;
    }
}

dictionary ParseBlacklistToDict(const string& in blacklist) {
    dictionary blacklistDict;
    string cleanBlacklist = blacklist.Replace(" ", "");
    array<string> blacklistArray = cleanBlacklist.Split(",");
    for (uint i = 0; i < blacklistArray.Length; i++) {
        blacklistDict.Set(blacklistArray[i], true);
    }
    return blacklistDict;
}


bool IsMapUploadedToNadeo(const string &in uid) {
    auto cma = cast<CGameManiaPlanet>(GetApp()).MenuManager.MenuCustom_CurrentManiaApp;
    auto dfm = cma.DataFileMgr;
    auto userId = cma.UserMgr.Users[0].Id;
    auto getFromUid = dfm.Map_NadeoServices_GetFromUid(userId, uid);
    while (getFromUid.IsProcessing) yield();
    if (getFromUid.HasSucceeded) {
        if (getFromUid.Map is null) {
            trace('get map success but null map');
            return false;
        } else {
            trace('get map success: ' + getFromUid.Map.Name + ", " + getFromUid.Map.FileUrl);
            return true;
        }
    }
    if (getFromUid.ErrorDescription.Contains("Unknown map")) {
        return false;
    }
    warn('get from uid did not succeed: ' + getFromUid.ErrorType + ", " + getFromUid.ErrorCode + ", " + getFromUid.ErrorDescription);
    return false;
}
