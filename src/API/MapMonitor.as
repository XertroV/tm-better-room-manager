const string MM_API_PROD_ROOT = "https://map-monitor.xk.io";
const string MM_API_DEV_ROOT = "http://localhost:8000";

// [Setting category="Debug" name="Local Dev Server"]
bool S_LocalDev = false;

const string MM_API_ROOT {
    get {
        if (S_LocalDev) return MM_API_DEV_ROOT;
        else return MM_API_PROD_ROOT;
    }
}

Json::Value@ GetNbPlayersForMap(const string &in mapUid) {
    return CallMapMonitorApiPath('/map/' + mapUid + '/nb_players/refresh');
}
