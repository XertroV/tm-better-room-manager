namespace Auth {
    string g_Token;
    uint lastTokenTime = 0;

    bool updateInProg = false;
    void UpdateToken() {
        if (updateInProg) {
            while (updateInProg) yield();
            return;
        }
        updateInProg = true;
        auto t = Auth::GetToken();
        while (!t.Finished()) yield();
        g_Token = t.Token();
#if DEV
        trace('got token: ' + g_Token);
#endif
        lastTokenTime = Time::Stamp;
        updateInProg = false;
    }

    const string GetCachedToken() {
        if (Time::Stamp - lastTokenTime > 60 * 55) {
            UpdateToken();
        }
        while (g_Token == "") UpdateToken();
        return g_Token;
    }
}
