// rewrite of existing api
class CachedImage {
    string url;
    protected MemoryBuffer@ buf;
    protected UI::Texture@ tex;
    bool success;
    string error;
    bool done;

    CachedImage(const string &in url) {
        this.url = url;
        startnew(CoroutineFunc(DownloadFile));
    }

    void DownloadFile() {
        trace("Downloading image: " + url);
        Net::HttpRequest@ req = Net::HttpGet(url);
        while (!req.Finished()) yield();
        auto code = req.ResponseCode();
        done = true;
        if (code >= 200 || code < 300) {
            @buf = req.Buffer();
            success = true;
        } else {
            error = "Failed to download image: " + code + " / " + req.Error();
            success = false;
        }
    }

    bool hasWarnedOnFailed = false;
    UI::Texture@ GetTex() {
        if (!done || !success) return null;
        if (tex is null && buf !is null) {
            @tex = UI::LoadTexture(buf);
            if (tex.GetSize().x <= 0.4) {
                if (!hasWarnedOnFailed) {
                    warn("Failed to load image: " + url + " / size.x = " + tex.GetSize().x);
                    hasWarnedOnFailed = true;
                }
                @buf = null;
                @tex = null;
            }
        }
        return tex;
    }
}

namespace Images
{
    dictionary g_cachedImages;

    CachedImage@ FindExisting(const string &in url) {
        if (g_cachedImages.Exists(url)) return cast<CachedImage>(g_cachedImages[url]);
        return null;
    }

    CachedImage@ CachedFromURL(const string &in url) {
        auto@ img = FindExisting(url);
        if (img is null) {
            @img = CachedImage(url);
            @g_cachedImages[url] = img;
        }
        return img;
    }
}
