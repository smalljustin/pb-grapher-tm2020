const string LatestVersionApiUrl = "https://api.github.com/repos/smalljustin/pb-grapher-tm2020/releases/latest";
const string LatestVersionDownloadUrl = LatestVersionApiUrl.Replace("api.github.com/repos", "github.com");
bool g_updateAvailable = false;
string g_bestVersion = "";

// if no release, response is: `{"message": "Not Found", ...}`
// otherwise: `{"tag_name": "0.1.5", ...}` or w/e
string GetLatestVersion() {
    auto req = Net::HttpGet(LatestVersionApiUrl);
    while(!req.Finished()) { yield(); }
    try {
        return string(Json::Parse(req.String())['tag_name']);
    } catch {
        warn("unable to parse json from github: " + req.String());
        warn("exception info: " + getExceptionInfo());
        warn("http request code: " + req.ResponseCode());
        warn("http request error: " + req.Error());
    }
    return "";
}

void CheckForUpdatesOnLoad() {
#if DEV
    return;
#endif
    string currentVersion = Meta::ExecutingPlugin().Version;
    string bestVersion = GetLatestVersion();
    if (bestVersion.Length == 0) {
        warn("Checked for an update but got nothing.");
        return;
    }
    if (bestVersion != currentVersion) {
        NotifyUpdate(bestVersion);
    }
}

void NotifyUpdate(const string &in bestVersion) {
    g_updateAvailable = true;
    g_bestVersion = bestVersion;
    UI::ShowNotification(
        Meta::ExecutingPlugin().Name,
        "New version available: " + bestVersion + "!\nPlease update the plugin by downloading the latest version from the plugin manager.",
        vec4(.2, .6, .2, .4),
        15000
    );
}

/** Render function called every frame intended only for menu items in the main menu of the `UI`.
*/
void RenderMenuMain() {
    if (!g_updateAvailable) return;
    if (UI::BeginMenu("\\$d51 Update " + Meta::ExecutingPlugin().Name)) {
        if (UI::MenuItem("Download version " + g_bestVersion)) {
            OpenBrowserURL(LatestVersionDownloadUrl);
        }
        if (UI::MenuItem("Hide till next game start")) {
            g_updateAvailable = false;
        }
        UI::EndMenu();
    }
}
