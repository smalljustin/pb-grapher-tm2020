GraphHud @ graphHud;
DatabaseFunctions @ databasefunctions;
float g_dt = 0;
float HALF_PI = 1.57079632679;
string surface_override = "";


vec2 m_size = vec2(graph_width, graph_height);

void Update(float dt) {
  graphHud.update();
}

string getMapUid() {
  auto app = cast < CTrackMania > (GetApp());
  if (app != null) {
    if (app.RootMap != null) {
      if (app.RootMap.MapInfo != null) {
        return app.RootMap.MapInfo.MapUid;
      }
    }
  }
  return "";
}

void Render() {
  if (graphHud!is null) {
    auto app = GetApp();
    if (Setting_General_HideWhenNotPlaying) {
      if (app.CurrentPlayground!is null && (app.CurrentPlayground.UIConfigs.Length > 0)) {
        if (app.CurrentPlayground.UIConfigs[0].UISequence == CGamePlaygroundUIConfig::EUISequence::Intro) {
          return;
        }
      }
    }
    if (getMapUid() != "")
      graphHud.Render();
  }
}

void OnSettingsChanged() {
  graphHud.OnSettingsChanged();
  if (UseCurrentlyViewedPlayer) {
    player_index = 0;
  }
}

void Main() {
  @graphHud = GraphHud();
  @databasefunctions = DatabaseFunctions();
  startnew(CheckForUpdatesOnLoad);
}