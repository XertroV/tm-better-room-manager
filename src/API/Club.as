
/** example ret val
    * {"uid":"jAtn7LQt2MTG5xv4BeiQwZAX1K","cardinal":376,"records":[{"player":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","score":52414,"rank":230}]}
    */
Json::Value@ GetChallengePlayerRank(int challengeid, const string &in mapid, const string &in userId) {
    return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + userId);
}

/* see above */
Json::Value@ GetChallengePlayerRanks(int challengeid, const string &in mapid, const string[]&in userIds) {
    string players = string::Join(userIds, ",");
    return CallCompApiPath("/api/challenges/" + challengeid + "/records/maps/" + mapid + "/players?players[]=" + players);
}
/** {"id":1814,"edition":2,"competition":{"id":4442,"liveId":"LID-COMP-foq0qr0vktc3m1g","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","name":"Cup of the Day 2023-01-02 #2","participantType":"PLAYER","description":null,"registrationStart":null,"registrationEnd":null,"startDate":1672712190,"endDate":1672719390,"matchesGenerationDate":1672712165,"nbPlayers":0,"spotStructure":"{\"version\":1,\"rounds\":[{\"matchGeneratorData\":{\"matchSize\":64,\"matchGeneratorType\":\"daily_cup\"},\"matchGeneratorType\":\"daily_cup\"}]}","leaderboardId":11292,"manialink":null,"rulesUrl":null,"streamUrl":null,"websiteUrl":null,"logoUrl":null,"verticalUrl":null,"allowedZones":[],"deletedOn":null,"autoNormalizeSeeds":true,"region":"ca-central","autoGetParticipantSkillLevel":"DISABLED","matchAutoMode":"ENABLED"},"challenge":{"id":2229,"uid":"3384ab9e-f6cf-4dd6-94b3-3ad0c1554b5d","name":"Cup of the Day 2023-01-02 #2 - Challenge","scoreDirection":"ASC","startDate":1672711260,"endDate":1672712160,"status":"INIT","resultsVisibility":"PUBLIC","creator":"afe7e1c1-7086-48f7-bde9-a7e320647510","admins":["0060a0c1-2e62-41e7-9db7-c86236af3ac4","54e4dda4-522d-496f-8a8b-fe0d0b5a2a8f","2116b392-d808-4264-923f-2bfcfa60a570","6ce163d5-f240-4741-870b-f2adad843865","a76653e1-998a-4c53-8a91-0a396e15bfb5"],"nbServers":0,"autoScale":false,"nbMaps":1,"leaderboardId":11290,"deletedOn":null,"leaderboardType":"SUM","completeTimeout":5},"startDate":1672711260,"endDate":1672719390,"deletedOn":null}
    */
Json::Value@ GetCotdStatus() {
    return CallCompApiPath("/api/daily-cup/current");
}
