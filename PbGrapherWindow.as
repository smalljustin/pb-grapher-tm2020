class PbGrapherWindow {
    float padding = 0;
    int ACTIVE_NUM_CPS;
    float MAX_MAP_TIME;
    vec4 valueRange = vec4(0, ACTIVE_NUM_CPS, 0, MAX_MAP_TIME);
    vec2 min, max;
    string active_map_uuid;

    void UpdateSettings() {

    }

    array<array<CpLog>> cpLogArray(0, array<CpLog>(0));
    
    PbGrapherWindow() {
    }

    // bool isNotFullyInitialized() { 
    //     auto playground = getPlayground();
    //     return playground is null 
    //         || playground.GameTerminals is null
    //         || playground.GameTerminals.Length != 1
    //         || playground.Interface is null;
    // }

    int getCurrentGameTime() {
        return getPlayground().Interface.ManialinkScriptHandler.GameTime;
    }

    int getPlayerStartTime() {
        return getPlayer().StartTime;
    }

    int getCurrentCheckpoint() {
        auto player = getPlayer();
        if (player !is null) {
            return player.CurrentLaunchedRespawnLandmarkIndex;
        } else {
            return -1;
        }
    }

    CSmArenaClient@ getPlayground() {
        return cast < CSmArenaClient > (GetApp().CurrentPlayground);
    }

    CSmPlayer@ getPlayer() {
        auto playground = getPlayground();
        if (playground!is null) {
            if (playground.GameTerminals.Length > 0) {
                CGameTerminal @ terminal = cast < CGameTerminal > (playground.GameTerminals[0]);
                CSmPlayer @ player = cast < CSmPlayer > (terminal.GUIPlayer);
                if (player!is null) {
                    return player;
                }
            }
        }
        return null;
    }

    int getEngineRpm() {
        CSmArenaClient @ playground = cast < CSmArenaClient > (GetApp().CurrentPlayground);
        if (playground!is null) {
            if (playground.GameTerminals.Length > 0) {
                CGameTerminal @ terminal = cast < CGameTerminal > (playground.GameTerminals[0]);
                CSmPlayer @ player = cast < CSmPlayer > (terminal.GUIPlayer);
                if (player!is null) {
                    CSmScriptPlayer @ script_player = cast < CSmScriptPlayer > (player.ScriptAPI);
                    if (script_player!is null) {
                        return script_player.EngineRpm;
                    }
                }
            }
        }
        return -1;
    }

    array < array < CpLog >> activeDataPoints(10, array < CpLog >(NUM_PAST_GHOSTS, CpLog()));

    void reloadValueRange() {
        valueRange = vec4(0, ACTIVE_NUM_CPS, -MAX_MAP_TIME, 0);
    }

    void renderCpLogArray(array<CpLog> cpLogArray) {
        nvg::BeginPath();
        nvg::MoveTo(TransformToViewBounds(ClampVec2(vec2(0, cpLogArray[0].cp_time), valueRange), min, max));
        for (int i = 1; i < cpLogArray.Length; i++) {
            nvg::LineTo(TransformToViewBounds(ClampVec2(vec2(i, cpLogArray[i].cp_time), valueRange), min, max));
        }
        nvg::StrokeColor(vec4(.5, .5, .5, 1));
        nvg::StrokeWidth(LineWidth);
        nvg::Stroke();
        nvg::ClosePath();
    }

    void handleMapUpdate() {
        string map_uuid = getMapUid();
        if (map_uuid == active_map_uuid) {
            return;
        }
        cpLogArray.RemoveRange(0, cpLogArray.Length);
        // otherwise, we need to pull out all the existing datapoints for this map
        cpLogArray = databasefunctions.getCpLogsForMap(map_uuid);
        for (int i = 0; i < cpLogArray.Length; i++) {
            // log("### I = " + tostring(i));
            for (int j = 0; j < cpLogArray[i].Length; j++) {
                // log("### J = " + tostring(j));
                // log(cpLogArray[i][j].tostring());
            }
        }
    }


    void Update() {
        handleMapUpdate();
        log(tostring(getCurrentCheckpoint()));
        log(tostring(getPlayerStartTime()));
        log(tostring(getCurrentGameTime()));
    }

    void Render(vec2 parentSize, float LineWidth) {
        float _padding = padding;
        if (!GEAR_INPUT_TOOL_ENABLED) {
            _padding = 0;
        }
        min = vec2(_padding, parentSize.y - _padding);
        max = vec2(parentSize.x - _padding, _padding);
        handleMapUpdate();
    }

    void DrawSpeedLine(float vel_t, vec4 color) {
        nvg::BeginPath();
        nvg::MoveTo(TransformToViewBounds(ClampVec2(vec2(valueRange.x, vel_t), valueRange), min, max));
        nvg::LineTo(TransformToViewBounds(ClampVec2(vec2((valueRange.x) + (valueRange.y - valueRange.x) / SCALE, vel_t), valueRange), min, max));
        nvg::StrokeColor(color);
        nvg::StrokeWidth(LineWidth);
        nvg::Stroke();
        nvg::ClosePath();
    }

    vec2 ClampVec2(const vec2 & in val,
        const vec4 & in bounds) {
        return vec2(Math::Clamp(val.x, bounds.x, bounds.y), Math::Clamp(val.y, bounds.z, bounds.w));
    }

    vec2 TransformToViewBounds(const vec2 & in point,
        const vec2 & in min,
            const vec2 & in max) {
        auto xv = Math::InvLerp(valueRange.x, valueRange.y, point.x);
        auto yv = Math::InvLerp(valueRange.z, valueRange.w, point.y);
        return vec2(graph_x_offset + Math::Lerp(min.x, max.x, xv), graph_y_offset + Math::Lerp(min.y, max.y, yv));
    }
}