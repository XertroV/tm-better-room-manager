const string DefaultTags = "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,41,42,43,44,45,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67";

const string DefaultOffTags = "23,40,46";

const string MapUrl(Json::Value@ map) {
    int trackId = map['TrackID'];
    return MapUrlTmx(trackId);
}

const string MapUrlCgf(int TrackID) {
    return "https://cgf.s3.nl-1.wasabisys.com/" + TrackID + ".Map.Gbx";
}

const string MapUrlTmx(int TrackID) {
    return "https://trackmania.exchange/maps/download/" + TrackID;
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

const string multiMapEndpoint = "https://trackmania.exchange/api/maps/get_map_info/multi/";

// returns json array of maps
Json::Value@ GetMapsByTrackIDs(string[] &in tids) {
    string url = multiMapEndpoint + string::Join(tids, ",");
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting maps by TrackID from TMX: " + req.Error() + " / " + req.String());
        return null;
    }
    return Json::Parse(req.String());
}

const string mapPackMapsEndpoint = "https://trackmania.exchange/api/mappack/get_mappack_tracks/{id}";

// returns json array of maps
Json::Value@ GetMapsFromMapPackId(const string &in mpId) {
    string url = mapPackMapsEndpoint.Replace("{id}", mpId);
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting map pack maps from TMX: " + req.Error());
        return null;
    }
    return Json::Parse(req.String());
}
