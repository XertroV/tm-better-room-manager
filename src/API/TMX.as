const string DefaultTags = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,41,42,43,44,45,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,73";

const string DefaultOffTags = "23,40,46,71,72";

const string MapUrl(Json::Value@ map) {
    int mapId = map['MapId'];
    return MapUrlTmx(mapId);
}

const string MapUrlCgf(int MapID) {
    return "https://cgf.s3.nl-1.wasabisys.com/" + MapID + ".Map.Gbx";
}

const string MapUrlTmx(int MapID) {
    return "https://trackmania.exchange/mapgbx/" + MapID;
}

const string TMX_API_FIELDS = "MapId,MapUid,Difficulty,Length";
const string randMapEndpoint = "https://trackmania.exchange/api/maps?random=1&count=1&fields="+TMX_API_FIELDS+"&{params_str}";

// tags should be a comma separated list of tags (as integers)
// https://api2.mania.exchange/Method/Index/53
Json::Value@ GetARandomMap(const string &in tags = "", bool tagExclude = false, bool tagInclusive = false) {
    auto useDefault = tags.Length == 0 || tags == DefaultTags;
    string params = (useDefault || tagExclude) ? "etag=" : "tag=";
    params += useDefault ? DefaultOffTags : tags;
    params += "&taginclusive=" + tostring(tagInclusive);
    params += "&primarytype=0";
    string url = randMapEndpoint.Replace("{params_str}", params);
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting rand map from TMX: " + req.Error() + " / " + req.String());
        warn("URL: `" + url + "`");
        return null;
    }
    trace("Got rand map: " + req.String());
    return req.Json();
}

const string multiMapEndpoint = "https://trackmania.exchange/api/maps?count=100&fields=" + TMX_API_FIELDS + "&{params_str}";

// returns json array of maps
Json::Value@ GetMapsByMapIDs(string[] &in tids) {
    string url = multiMapEndpoint.Replace("{params_str}", "id=" + Text::Join(tids, ","));
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting maps by MapID from TMX: " + req.Error() + " / " + req.String());
        return null;
    }

    return req.Json();
}

const string mapPackMapsEndpoint = "https://trackmania.exchange/api/maps?count=100&fields="+TMX_API_FIELDS+"&{params_str}";

// returns json array of maps
Json::Value@ GetMapsFromMapPackId(const string &in mpId) {
    string url = mapPackMapsEndpoint.Replace("{params_str}", "mappackid=" + mpId);
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting map pack maps from TMX: " + req.Error());
        return null;
    }
    return req.Json();
}
