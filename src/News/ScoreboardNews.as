class NewsScoreBoardManager : BRM::INewsScoreBoardManager {
	NewsScoreBoardSection@[] sections;
	private string _serverName;
	private string _newsName;
	private int newsActivityId = -1;
	private int clubId;

	NewsScoreBoardManager(int clubId, const string &in serverName = "", bool autoCreateNews = false) {
		_serverName = serverName;
		this.clubId = clubId;
		if (serverName.Length == 0) {
			_serverName = GetCurrentServerName();
		}
		if (_serverName.Length == 0) {
			throw("NewsScoreBoardManager: ServerName is empty; and no current server");
			return;
		}
		_newsName = ("LB:" + _serverName).SubStr(0, 20);
		if (autoCreateNews) {
			startnew(CoroutineFunc(this.GetOrCreateClubNewsActivity));
		}
	}

	int get_NewsActivityId() {
		return newsActivityId;
	}

	string get_ServerName() {
		return _serverName;
	}

	string get_NewsName() {
		return _newsName;
	}

	bool getNewsActivityStarted = false;
	void EnsureNewsActivityCreatedAsync() {
		if (newsActivityId > 0 || getNewsActivityStarted) return;
		getNewsActivityStarted = true;
		GetOrCreateClubNewsActivity();
	}

	private void GetOrCreateClubNewsActivity() {
		if (_serverName.Length == 0) throw("GetOrCreateClubNewsActivity: ServerName is empty");

		auto activities = GetClubActivities(clubId)["activityList"];
		Json::Value@ activity;
		string _name;
		for (uint i = 0; i < activities.Length; i++) {
			@activity = activities[i];
			if (string(activity["activityType"]) != "news") continue;
			_name = string(activity["name"]);
			if (_name != _newsName) continue;
			// found it
			newsActivityId = int(activity["id"]);
			trace("Found news activity for news: " + _newsName + ", id: " + newsActivityId);
			return;
		}
		// if we're here, it doesn't exist in first 100 things in club
		auto resp = Live::CreateNews(clubId, _newsName, "", "# Scoreboard\n# Uninitialized");
		newsActivityId = int(resp["id"]);
		trace("Created news activity for news: " + _newsName + ", id: " + newsActivityId);
	}

	BRM::INewsScoreBoardSection@ GetOrCreateSection(const string &in sectionName) {
		auto section = GetSection(sectionName);
		if (section !is null) return section;
		@section = NewsScoreBoardSection(sectionName);
		sections.InsertLast(section);
		return section;
	}

	BRM::INewsScoreBoardSection@ GetSection(const string &in sectionName) {
		for (uint i = 0; i < sections.Length; i++) {
			auto section = sections[i];
			if (section.get_SectionName() == sectionName) {
				return section;
			}
		}
		return null;
	}

	void UpdateNewsAsync() {
		if (newsActivityId == -1) {
			throw("UpdateNews: newsActivityId is -1");
			return;
		}
		string newsContent = "";
		for (uint i = 0; i < sections.Length; i++) {
			newsContent += sections[i].ToNewsString();
		}
		Live::SetNewsDetails(clubId, newsActivityId, _newsName, "", newsContent);
		trace("Updated news activity for news: " + _newsName + ", id: " + newsActivityId);
	}

	void UpdateNewsInBg() {
		startnew(CoroutineFunc(this.UpdateNewsAsync));
	}

	void DeleteAllSections() {
		sections.RemoveRange(0, sections.Length);
	}

	void ClearAllEntries() {
		for (uint i = 0; i < sections.Length; i++) {
			sections[i].ClearEntries();
		}
	}
}


class NewsScoreBoardSection : BRM::INewsScoreBoardSection {
	string name;
	array<BRM::INewsScoreBoardEntry@> entries;

	NewsScoreBoardSection(const string &in name) {
		this.name = name;
	}

	string get_SectionName() {
		return name;
	}

	array<BRM::INewsScoreBoardEntry@>@ get_Entries() {
		return entries;
	}

    void AddEntry(int rank, const string &in name, int wrs = -1, int ats = -1, int golds = -1, int mapsPlayed = -1) {
		entries.InsertLast(NewsScoreBoardEntry(rank, name, wrs, ats, golds, mapsPlayed));
	}

	void ClearEntries() {
		entries.RemoveRange(0, entries.Length);
	}

    string ToNewsString() {
		string[] arr;
		arr.InsertLast("# " + name + "\n");
		for (uint i = 0; i < entries.Length; i++) {
			auto entry = entries[i];
			arr.InsertLast(entry.ToNewsString());
		}
		return string::Join(arr, "");
	}
}


class NewsScoreBoardEntry : BRM::INewsScoreBoardEntry {
	int rank;
	string name;
	int wrs;
	int ats;
	int golds;
	int mapsPlayed;

	NewsScoreBoardEntry(int rank, const string &in name, int wrs = -1, int ats = -1, int golds = -1, int mapsPlayed = -1) {
		this.rank = rank;
		this.name = name;
		this.wrs = wrs;
		this.ats = ats;
		this.golds = golds;
		this.mapsPlayed = mapsPlayed;
	}

	int get_Rank() {
		return rank;
	}

	string get_Name() {
		return name;
	}

	int get_WRs() {
		return wrs;
	}

	int get_ATs() {
		return ats;
	}

	int get_Golds() {
		return golds;
	}

	int get_MapsPlayed() {
		return mapsPlayed;
	}

	string ToNewsString() {
		return string::Join({
			"# " + rank + ". " + name,
			tostring(wrs),
			tostring(ats),
			tostring(golds),
			tostring(mapsPlayed) + "\n"
		}, "\t");
	}
}



CTrackManiaNetworkServerInfo@ GetServerInfo() {
	auto app = GetApp();
	auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
	return si;
}

string GetCurrentServerName() {
	auto si = GetServerInfo();
	if (si is null) return "";
	return si.ServerName;
}
