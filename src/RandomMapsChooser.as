funcdef void RandomMapsCallback(LazyMap@[]@ maps);

const int NUM_TAGS = 67;

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
    void toggle() {
        this.checked = !this.checked;
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
    NoGrip = 67,
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
    RandomMapsChooser::includeMode = 0;
    setAllTags(tags, false);
    // default off: 23,37,40,46,47
    // see API/TMX.as for list used in HTTP request formation
    uint[] defaultOff = {23,40,46};
    for (uint i = 0; i < defaultOff.Length; i++) {
        if (defaultOff[i] > tags.Length) continue;
        tags[defaultOff[i] - 1].setChecked(true);
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

    [Setting hidden]
    string uidBlacklist;

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
            // if (UI::Button("Check All")) setAllTags(tags, true);
            // UI::SameLine();
            // if (UI::Button("Uncheck All")) setAllTags(tags, false);
            if (UI::Button("Exclude")) SetIncludeMode(tags, false);
            UI::SameLine();
            if (UI::Button("Include Any")) SetIncludeMode(tags, true);
            UI::SameLine();
            if (UI::Button("Include All")) SetIncludeMode(tags, true, true);
            // UI::SameLine();
            UI::AlignTextToFramePadding();
            UI::TextWrapped("Mode: " + GetIncludeModeStr() + ". " + GetIncludeModeDesc());
            DrawTagsValidation(tags);
            DrawTagsCheckboxes(tags);
        }

        UI::Separator();
        if (UI::CollapsingHeader("Map Blacklist")) {
            UI::TextWrapped("Blacklist maps with these UIDs. Separate UIDs with commas. \n\t\\$i(Example: 5fGlGwXEd6kNdfeZpmIsHw66FZd, 4Tk25U832EwU2LG8aLHZ0cEsx4m)");
            auto mlTextWidth = UI::GetWindowContentRegionWidth() * 0.6;
            bool changed;
            uidBlacklist = UI::InputTextMultiline("Blacklist (Comma Separated UIDs)", uidBlacklist, changed, vec2(mlTextWidth, 100));
            if (changed) UpdateBlacklistPreview();
            DrawBlacklistPreview();
        }

        UI::EndDisabled();
    }

    // exclude = 0, include = 1, include all = 2
    int includeMode = 0;
    void SetIncludeMode(array<Tag@>& tags, bool include, bool all = false) {
        auto lastInclude = includeMode;
        includeMode = include ? (all ? 2 : 1) : 0;
        UpdateTagCheckboxes(tags, includeMode, lastInclude);
    }

    string GetIncludeModeStr() {
        switch (includeMode) {
            case 0: return "Exclude";
            case 1: return "Include Any";
            case 2: return "Include All";
        }
        return "Unknown";
    }

    string GetIncludeModeDesc() {
        switch (includeMode) {
            case 0: return "Exclude maps with any of up to 10 tags.";
            case 1: return "Include maps with any of up to 10 tags.";
            case 2: return "Include maps with all of up to 3 tags.";
        }
        return "Unknown Mode: " + includeMode + ".";
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

    void UpdateTagCheckboxes(array<Tag@>& tags, int mode, int lastMode) {
        if (mode == lastMode) return;
        if (mode == 0) {
            setAllTagsToDefault(tags);
        } else if (lastMode == 0) {
            setAllTags(tags, false);
        }
    }

    void DrawTagsCheckboxes(array<Tag@>& tags) {
        if (tags is null) return;
        UI::AlignTextToFramePadding();
        UI::Columns(6);
        auto nbPerCol = (NUM_TAGS - 1) / 6 + 1;
        for (uint i = 0; i < tags.Length; i++) {
            if ((i % nbPerCol == 0) && i != 0) {
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

    void DrawTagsValidation(array<Tag@>& tags) {
        uint nbChecked = 0;
        for (uint i = 0; i < tags.Length; i++) {
            if (tags[i].checked) nbChecked++;
        }
        uint maxTags = includeMode == 2 ? 3 : 10;
        UI::AlignTextToFramePadding();
        if ((0 < nbChecked || includeMode == 0) && nbChecked <= maxTags) {
            // good
            UI::TextWrapped("\\$4f4" + Icons::CheckSquareO + " " + nbChecked + " tags selected.");
        } else {
            UI::TextWrapped("\\$fa4" + Icons::TimesCircleO + " " + nbChecked + " tags selected. Must be between 1 and " + maxTags + ", inclusive.");
        }
    }

    void OnChooseRandomSettings() {
        loadingMaps = true;
        startnew(RunGetMaps);
    }

    uint getMapReqFailed = 0;

    void RunGetMaps() {
        getMapReqFailed = 0;
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
        auto blacklistDict = ParseBlacklistToDict(uidBlacklist);
        string tagStr = toTagString(tags);
        while (loadingMaps && int(gotMaps.Length) < nbMaps && getMapReqFailed < 10) {
            auto @newMap = GetARandomMap(tagStr, includeMode == 0, includeMode == 2);
            if (newMap is null) {
                getMapReqFailed++;
                continue;
            }
            @newMap = newMap['Results'][0];
            // return type: https://api2.mania.exchange/Method/Index/4
            // https://api2.mania.exchange/Method/Index/53
            MapDifficulty diff = MapDifficulty(int(newMap['Difficulty']));
            if (diff < minDifficulty || maxDifficulty < diff) {
                warn("Skipping map with difficulty: " + int(newMap['MapId']) + ", " + tostring(diff));
                continue;
            }
            int len = float(newMap['Length']) / 1000;
            if (len < minLen || maxLen < len) {
                warn("Skipping map with length: " + int(newMap['MapId']) + ", " + len);
                continue;
            }
            string mapUid = newMap['MapUid'];
            if (blacklistDict.Exists(mapUid)) {
                trace("Skipping blacklisted map: " + mapUid);
                continue;
            }

            if (IsMapUploadedToNadeo(mapUid)) {
                if (loadingMaps && int(gotMaps.Length) < nbMaps)
                    gotMaps.InsertLast(LazyMap(mapUid));
            } else {
                warn('skipping unuploaded map: ' + int(newMap['MapId']) + ", " + mapUid);
            }
        }
    }

    void RunCallback() {
        cb(gotMaps);
        active = false;
        loadingMaps = false;
    }
}

dictionary@ ParseBlacklistToDict(const string &in blacklist, bool warnOnInvalid = true) {
    dictionary blacklistDict;
    auto@ blacklistArray = blacklist.Replace("\n", ",").Split(",");
    for (uint i = 0; i < blacklistArray.Length; i++) {
        auto uid = blacklistArray[i].Trim();
        // skip empty-ish strings
        if (uid.Length < 2) continue;
        // warn on otherwise bad-looking UIDs, but add them so we can give feedback
        if (uid.Length > 27 || uid.Length < 24) {
            if (warnOnInvalid) NotifyWarning("Invalid UID in blacklist: " + uid);
            // continue;
        }
        blacklistDict[uid] = true;
    }
    return blacklistDict;
}

string[]@ blacklistElements;

void UpdateBlacklistPreview() {
    auto bl = ParseBlacklistToDict(RandomMapsChooser::uidBlacklist, false);
    @blacklistElements = bl.GetKeys();
}

void DrawBlacklistPreview() {
    if (blacklistElements is null) {
        UpdateBlacklistPreview();
    }
    if (blacklistElements is null) {
        UI::Text("\\$f80No blacklist preview (this is a bug).");
        return;
    }
    if (UI::BeginChild("BlacklistPreview", vec2(-1, -1), UI::ChildFlags::Border | UI::ChildFlags::AutoResizeY, UI::WindowFlags::AlwaysVerticalScrollbar)) {
        UI::Columns(2);
        for (uint i = 0; i < blacklistElements.Length; i++) {
            UI::Text(blacklistElements[i]);
        }
        UI::NextColumn();
        for (uint i = 0; i < blacklistElements.Length; i++) {
            if (blacklistElements[i].Length == 27) {
                UI::Text("\\$0f0" + Icons::CheckSquareO);
            } else {
                UI::Text("\\$f80" + Icons::TimesCircleO + " Bad length");
            }
        }
        UI::Columns(1);
    }
    UI::EndChild();
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
