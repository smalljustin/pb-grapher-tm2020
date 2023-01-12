GraphHud @ graphHud;
DatabaseFunctions @ databasefunctions;
float g_dt = 0;
float HALF_PI = 1.57079632679;
string surface_override = "";

bool showTimeInputWindow = false;

vec2 m_size = vec2(graph_width, graph_height);

void Update(float dt) {
  graphHud.update();
}

string getMapUid() {
  auto app = cast < CTrackMania > (GetApp());
  if (@app != null) {
    if (@app.RootMap != null) {
      if (@app.RootMap.MapInfo != null) {
        return app.RootMap.MapInfo.MapUid;
      }
    }
  }
  return "";
}

void RenderMenu() {
  if (UI::BeginMenu(Icons::Cog + " PB Grapher")) {
    if (UI::MenuItem("Manage Custom Time Targets")) {
      showTimeInputWindow = !showTimeInputWindow;
    }
      if (UI::MenuItem("Switch to/from Histogram")) {
      HISTOGRAM_VIEW = !HISTOGRAM_VIEW;
      graphHud.OnSettingsChanged();
    }
    UI::EndMenu();
  }
}


void Render() {
  if (!UI::IsRendering()) {
    return;
  }
  if (graphHud!is null) {
    auto app = GetApp();
    if (app.CurrentPlayground!is null && (app.CurrentPlayground.UIConfigs.Length > 0)) {
      if (app.CurrentPlayground.UIConfigs[0].UISequence == CGamePlaygroundUIConfig::EUISequence::Intro) {
        return;
      }
    }
    if (getMapUid() != "" && UI::IsGameUIVisible())
      graphHud.Render();
  }
}

void OnSettingsChanged() {
  graphHud.OnSettingsChanged();
}

void Main() {
  @graphHud = GraphHud();
  @databasefunctions = DatabaseFunctions();
  graphHud.OnSettingsChanged();
}

void OnMouseButton(bool down, int button, int x, int y) {
  graphHud.OnMouseButton(down, button, x, y);
}