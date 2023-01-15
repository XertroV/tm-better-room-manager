
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

const string randMapEndpoint = "https://trackmania.exchange/mapsearch2/search?api=on&random=1{params_str}";

Json::Value@ GetARandomMap() {
    string url = randMapEndpoint.Replace("{params_str}", "&etags=23,37,40,46,47");
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting rand map from TMX: " + req.Error());
        return null;
    }
    print("Got rand map: " + req.String());
    return Json::Parse(req.String());
}

const string multiMapEndpoint = "https://trackmania.exchange/api/maps/get_map_info/multi/";

// returns json array of maps
Json::Value@ GetMapsByTrackIDs(string[] &in tids) {
    string url = multiMapEndpoint + string::Join(tids, ",");
    auto req = PluginGetRequest(url);
    req.Start();
    while (!req.Finished()) yield();
    if (req.ResponseCode() >= 400 || req.ResponseCode() < 200 || req.Error().Length > 0) {
        warn("[status:" + req.ResponseCode() + "] Error getting maps by TrackID from TMX: " + req.Error());
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
