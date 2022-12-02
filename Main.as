GraphHud @ graphHud;
DatabaseFunctions @ databasefunctions;
float g_dt = 0;
float HALF_PI = 1.57079632679;
string surface_override = "";


vec2 m_size;

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

    if (app!is null && app.GameScene!is null) {
      if (UseCurrentlyViewedPlayer) {
        graphHud.Render(VehicleState::ViewingPlayerState());
      } else {
        CSceneVehicleVis @[] allStates = VehicleState::GetAllVis(app.GameScene);
        if (allStates.Length > 0) {
          if (player_index < 0 || (allStates!is null && allStates.Length > player_index)) {
            graphHud.Render(allStates[player_index].AsyncState);
          } else {
            UI::SetNextWindowContentSize(400, 150);
            UI::Begin("\\$f33Invalid player index!");
            UI::Text("No player found within player states at index " + tostring(player_index));
            UI::Text("");
            UI::End();
          }
        }
      }
    }
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