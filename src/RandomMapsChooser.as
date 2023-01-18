funcdef void RandomMapsCallback(LazyMap@[]@ maps);


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
        UI::SetNextWindowSize(500, 300, UI::Cond::Appearing);
        if (UI::Begin("Add Random Maps", WindowOpen)) {
            DrawInner();
        }
        UI::End();
    }

    string chosenKey;
    float btnWidth = 100;


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
        while (loadingMaps && int(gotMaps.Length) < nbMaps) {
            auto @newMap = GetARandomMap();
            if (newMap is null) continue;
            @newMap = newMap['results'][0];
            // return type: https://api2.mania.exchange/Method/Index/4
            MapDifficulty diff = MapDifficultyFromStr(newMap['DifficultyName']);
            if (diff < minDifficulty || maxDifficulty < diff) continue;
            int len = LengthNameToSecs(newMap['LengthName']);
            if (len < minLen || maxLen < len) continue;
            string mapUid = newMap['TrackUID'];
            if (IsMapUploadedToNadeo(mapUid)) {
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
