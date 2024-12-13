void AddAudiences() {
    NadeoServices::AddAudience("NadeoLiveServices");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
}

Json::Value@ FetchLiveEndpoint(const string &in route) {
    trace("[FetchLiveEndpoint] Requesting: " + route);
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return req.Json();
}

Json::Value@ PostLiveEndpoint(const string &in route, Json::Value@ data) {
    trace("[FetchLiveEndpoint] Requesting: " + route);
    auto req = NadeoServices::Post("NadeoLiveServices", route, Json::Write(data));
    req.Start();
    while(!req.Finished()) { yield(); }
    return req.Json();
}

Json::Value@ FetchClubEndpoint(const string &in route) {
    trace("[FetchClubEndpoint] Requesting: " + route);
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return req.Json();
}

Json::Value@ CallLiveApiPath(const string &in path) {
    AssertGoodPath(path);
    return FetchLiveEndpoint(NadeoServices::BaseURLLive() + path);
}

Json::Value@ PostLiveApiPath(const string &in path, Json::Value@ data) {
    AssertGoodPath(path);
    return PostLiveEndpoint(NadeoServices::BaseURLLive() + path, data);
}

Json::Value@ CallCompApiPath(const string &in path) {
    AssertGoodPath(path);
    return FetchClubEndpoint(NadeoServices::BaseURLMeet() + path);
}

Json::Value@ CallClubApiPath(const string &in path) {
    AssertGoodPath(path);
    return FetchClubEndpoint(NadeoServices::BaseURLMeet() + path);
}

// Json::Value@ CallMapMonitorApiPath(const string &in path) {
//     AssertGoodPath(path);
//     auto token = Auth::GetCachedToken();
//     auto url = MM_API_ROOT + path;
//     trace("[CallMapMonitorApiPath] Requesting: " + url);
//     auto req = PluginGetRequest(MM_API_ROOT + path);
//     req.Headers['Authorization'] = 'openplanet ' + token;
//     req.Start();
//     while(!req.Finished()) { yield(); }
//     return req.Json();
// }

// Ensure we aren't calling a bad path
void AssertGoodPath(string &in path) {
    if (path.Length <= 0 || !path.StartsWith("/")) {
        throw("API Paths should start with '/'!");
    }
}

// Length and offset get params helper
const string LengthAndOffset(uint length, uint offset) {
    return "length=" + length + "&offset=" + offset;
}


Net::HttpRequest@ PluginRequest(const string &in url) {
    auto r = Net::HttpRequest();
    r.Url = url;
    r.Headers['User-Agent'] = "TM_Plugin:RoomManager / contact=@XertroV,cgf@xk.io / client_version=" + Meta::ExecutingPlugin().Version;
    return r;
}
Net::HttpRequest@ PluginPostRequest(const string &in url) {
    auto r = PluginRequest(url);
    r.Method = Net::HttpMethod::Post;
    return r;
}

Net::HttpRequest@ PluginGetRequest(const string &in url) {
    auto r = PluginRequest(url);
    r.Method = Net::HttpMethod::Get;
    return r;
}
