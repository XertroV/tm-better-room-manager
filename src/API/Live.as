
/* example ret val:
        RetVal = {"monthList": MonthObj[], "itemCount": 23, "nextRequestTimestamp": 1654020000, "relativeNextRequest": 22548}
        MonthObj = {"year": 2022, "month": 5, "lastDay": 31, "days": DayObj[], "media": {...}}
        DayObj = {"campaignId": 3132, "mapUid": "fJlplQyZV3hcuD7T1gPPTXX7esd", "day": 4, "monthDay": 31, "seasonUid": "aad0f073-c9e0-45da-8a70-c06cf99b3023", "leaderboardGroup": null, "startTimestamp": 1596210000, "endTimestamp": 1596300000, "relativeStart": -57779100, "relativeEnd": -57692700}
    as of 2022-05-31 there are 23 items, so limit=100 will give you all data till 2029.
*/
Json::Value@ GetTotdByMonth(uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/campaign/month?" + LengthAndOffset(length, offset));
}

/** https://webservices.openplanet.dev/live/clubs/clubs-mine
    */
Json::Value@ GetMyClubs(uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/club/mine?" + LengthAndOffset(length, offset));
}

// {"id":55829,"name":"$z$e71\uf292$z$s$iTic Tac GO!","tag":"$Z$E71$I$S\uf292$Z$FFF$STTG","description":"$L[https:\/\/openplanet.dev\/plugin\/cgf]https:\/\/openplanet.dev\/plugin\/cgf$L","authorAccountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","latestEditorAccountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","iconUrl":"","logoUrl":"","decalUrl":"","screen16x9Url":"","decalSponsor4x1Url":"","screen8x1Url":"","screen16x1Url":"","verticalUrl":"","backgroundUrl":"","creationTimestamp":1671505006,"popularityLevel":0,"state":"public","featured":false,"walletUid":"7f5a3686-4238-415b-b1bb-03c32d93afab","metadata":"","editionTimestamp":1693279393,"iconTheme":"","decalTheme":"","screen16x9Theme":"","screen8x1Theme":"","screen16x1Theme":"","verticalTheme":"","backgroundTheme":"","verified":false}
Json::Value@ GetClubDetails(uint clubId) {
    return CallLiveApiPath("/api/token/club/" + clubId);
}

// Payload: {"name":"$z$e71$z$s$iTic Tac GO!","tag":"$Z$E71$I$S$Z$FFF$STTG","description":"$L[https://openplanet.dev/plugin/cgf]https://openplanet.dev/plugin/cgf$L","state":"public","iconTheme":"","decalTheme":"","backgroundTheme":"","verticalTheme":"","screen16x9Theme":"","screen8x1Theme":"","screen16x1Theme":""}
Json::Value@ SetClubDetails(uint clubId, Json::Value@ data) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/edit", data);
}

// returns {accountId: string, tagClubId: int, tag: string, pinnedClub: 0 or 1}
Json::Value@ SetClubTag(uint clubId) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/tag", null);
}

// returns {accountId: string, tagClubId: int, tag: string, pinnedClub: 0 or 1}
Json::Value@ SetPinnedClub(uint clubId) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/pin", null);
}

// https://webservices.openplanet.dev/live/clubs/members
Json::Value@ GetClubMembers(uint clubId, uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/club/" + clubId + "/member?" + LengthAndOffset(length, offset));
}

// https://webservices.openplanet.dev/live/clubs/activities
Json::Value@ GetClubActivities(uint clubId, bool active, uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/club/" + clubId + "/activity?active=" + tostring(active) + "&" + LengthAndOffset(length, offset));
}
// https://webservices.openplanet.dev/live/clubs/activities
Json::Value@ GetClubActivities(uint clubId, uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/club/" + clubId + "/activity?" + LengthAndOffset(length, offset));
}

// https://webservices.openplanet.dev/live/clubs/room-by-id
Json::Value@ GetClubRoom(uint clubId, uint roomId) {
    return CallLiveApiPath("/api/token/club/" + clubId + "/room/" + roomId);
}

// Payload: [json/update-room.json](json/update-room.json)
Json::Value@ SaveEditedRoomConfig(uint clubId, uint roomId, Json::Value@ data) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/room/" + roomId + "/edit", data);
}

// Payload: {public: 0 or 1} or {active: 0 or 1}
Json::Value@ EditClubActivity(uint clubId, uint roomId, Json::Value@ data) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/activity/" + roomId + "/edit", data);
}

// https://live-services.trackmania.nadeo.live/api/token/club/{TTG_CLUB_ID}/room/create -- same payload as SaveEditedRoomConfig
Json::Value@ CreateClubRoom(uint clubId, Json::Value@ data) {
    return PostLiveApiPath("/api/token/club/" + clubId + "/room/create", data);
}

// returns {password: string}
Json::Value@ GetRoomPassword(uint clubId, uint roomId) {
    return CallLiveApiPath("/api/token/club/" + clubId + "/room/" + roomId + "/get-password");
}

// returns {joinLink: string, starting: bool} -- throws if the server is deactivated
Json::Value@ GetJoinLink(uint clubId, uint roomId) {
    auto resp = PostLiveApiPath("/api/token/club/" + clubId + "/room/" + roomId + "/join", Json::Object());
    if (resp !is null && resp.GetType() == Json::Type::Array) {
        if (resp.Length > 0 && string(resp[0]) == "roomServer:error-NoServerAvailable") {
            throw("Getting join link: roomServer:error-NoServerAvailable -- The room is probably deactivated");
        }
    }
    return resp;
}

// https://webservices.openplanet.dev/live/maps/uploaded
Json::Value@ GetYourUploadedMaps(uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/map?" + LengthAndOffset(length, offset));
}

// https://webservices.openplanet.dev/live/leaderboards/surround
// example for response.tops: [{"top":[{"score":45438,"accountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","zoneId":"301e309b-7e13-11e8-8060-e284abfd2bc4","position":1560,"zoneName":"New South Wales"}],"zoneId":"301e1b69-7e13-11e8-8060-e284abfd2bc4","zoneName":"World"},{"top":[{"score":45438,"accountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","zoneId":"301e309b-7e13-11e8-8060-e284abfd2bc4","position":42,"zoneName":"New South Wales"}],"zoneId":"301e237a-7e13-11e8-8060-e284abfd2bc4","zoneName":"Oceania"},{"top":[{"score":45438,"accountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","zoneId":"301e309b-7e13-11e8-8060-e284abfd2bc4","position":32,"zoneName":"New South Wales"}],"zoneId":"301e2dc2-7e13-11e8-8060-e284abfd2bc4","zoneName":"Australia"},{"top":[{"score":45438,"accountId":"0a2d1bc0-4aaa-4374-b2db-3d561bdab1c9","zoneId":"301e309b-7e13-11e8-8060-e284abfd2bc4","position":8,"zoneName":"New South Wales"}],"zoneId":"301e309b-7e13-11e8-8060-e284abfd2bc4","zoneName":"New South Wales"}]
Json::Value@ GetSurrondingRecords(const string &in mapUid, uint score, int below=1, int above=1) {
    return GetSurrondingRecords("Personal_Best", mapUid, score, below, above);
}

// https://webservices.openplanet.dev/live/leaderboards/surround
Json::Value@ GetSurrondingRecords(const string &in groupId, const string &in mapUid, uint score, int below=1, int above=1) {
    return CallLiveApiPath("/api/token/leaderboard/group/" + groupId + "/map/" + mapUid + "/surround/"+below+"/"+above+"?score=" + score);
}

/**
  https://webservices.openplanet.dev/live/leaderboards/top
  This endpoint only allows you to read a leaderboard's first 10,000 records. The rest of the leaderboard is not available at this level of detail.
  onlyWorld=true
  */
Json::Value@ GetRecords(const string &in mapUid, uint length = 100, uint offset = 0) {
    return GetRecords("Personal_Best", mapUid, length, offset);
}

/**
  https://webservices.openplanet.dev/live/leaderboards/top
  This endpoint only allows you to read a leaderboard's first 10,000 records. The rest of the leaderboard is not available at this level of detail.
  onlyWorld=true
  */
Json::Value@ GetRecords(const string &in groupId, const string &in mapUid, uint length = 100, uint offset = 0) {
    return CallLiveApiPath("/api/token/leaderboard/group/" + groupId + "/map/" + mapUid + "/top?onlyWorld=true&" + LengthAndOffset(length, offset));
}

namespace Live {
    // name max: 20 chars
    // headline max: 40 chars
    // body max: 2000 chars
    Json::Value@ SetNewsDetails(int clubId, int activityId, const string &in name, const string &in headline, const string &in body) {
        Json::Value@ data = Json::Object();
        data["name"] = name;
        data["headline"] = headline;
        data["body"] = body;
        // https://live-services.trackmania.nadeo.live/api/token/club/46587/news/602018/edit
        return PostLiveEndpoint("/api/token/club/"+clubId+"/news/"+activityId+"/edit", data);
    }

    Json::Value@ GetNewsDetails(int clubId, int activityId) {
        // https://live-services.trackmania.nadeo.live/api/token/club/46587/news/602018
        return CallLiveApiPath("/api/token/club/"+clubId+"/news/"+activityId);
    }

    Json::Value@ CreateNews(int clubId, const string &in name, const string &in headline, const string &in body) {
        Json::Value@ data = Json::Object();
        data["name"] = name;
        data["headline"] = headline;
        data["body"] = body;
        // https://live-services.trackmania.nadeo.live/api/token/club/46587/news/create
        return PostLiveEndpoint("/api/token/club/"+clubId+"/news/create", data);
    }
}
