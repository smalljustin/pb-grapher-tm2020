class PbGrapherWindow {
    float padding = 0;
    int ACTIVE_NUM_CPS = 0;
    float MAX_MAP_TIME = 0;
    vec4 valueRange = vec4(0, ACTIVE_NUM_CPS, 0, 1);
    vec2 min, max;
    string active_map_uuid = "";

    int current_run_starttime;
    int current_run_id;
    int current_cp_id;
    int current_cp_idx;

    bool loaded = false;

    CpLog fastest_run;
    array<float> fastest_run_cp_times;
    array<float> slowest_run_cp_times;

    array<array<CpLog>> cp_log_array(0, array<CpLog>(0));
    array<CpLog> active_run_buffer(0, CpLog());

    vec4 renderTrailsColor(1, 1, 1, 1);

    
    PbGrapherWindow() {
    }

    void Update() {
        handleMapUpdate();
        if (getCurrentCheckpoint() == -1) {
            return;
        }
        handleRunStart();
        handleWatchCheckpoint();
    }

    void Render(vec2 parentSize, float LineWidth) {
        if (cp_log_array.Length < 2) {
            return;
        }
        float _padding = padding;
        min = vec2(_padding, parentSize.y - _padding);
        max = vec2(parentSize.x - _padding, _padding);

        vec4 active_color = renderTrailsColor;

        for (int i = 0; i < cp_log_array.Length; i++) {
            renderCpLogArray(cp_log_array[i], active_color);
            active_color *= 0.7;
        }
    }

    bool isIdxFinish(int idx) {
        return getPlayground().Arena.MapLandmarks[idx].Waypoint.IsFinish;
    }

    void UpdateSettings() {
        doCpLogRefresh(active_map_uuid);
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

    /**
     * Returns the player's starting time as an integer. 
     */
    int getPlayerStartTime() {
        return getPlayer().StartTime;
    }

    /**
     * handleRunStart: To be called at the beginning of each frame. 
     * Returns true if the run is continuing, and false if it has been reset.
     */
    bool handleRunStart() {
        if (getPlayerStartTime() == current_run_starttime) {
            // Continuing a run. 
            return true;
        } else {
            current_run_starttime = getPlayerStartTime();
            current_cp_idx = 0;
            // If we've reset, we're now at the start checkpoint. 
            // Don't save this run.
            current_cp_id = getCurrentCheckpoint();
            active_run_buffer.RemoveRange(0, active_run_buffer.Length);
            return false;
        }
    }

    void handleWatchCheckpoint() {
        if (getCurrentCheckpoint() == current_cp_id) {
            return;
        } else {
            active_run_buffer.InsertLast(
                CpLog(active_map_uuid, current_run_id, current_cp_idx, getCurrentRunTime())
            );
            current_cp_idx += 1;
            current_cp_id = getCurrentCheckpoint();
        }

        if (isIdxFinish(current_cp_id)) {
            databasefunctions.persistBuffer(active_run_buffer);
            current_run_id += 1;
            doCpLogRefresh(active_map_uuid);        
        }
    }

    void handleCpIdx() {
        if (getCurrentCheckpoint() == current_cp_id) {
            // Still at that checkpoint.
        } else {
            current_cp_id = getCurrentCheckpoint();
            current_cp_idx += 1;
            saveCheckpointInformation();
        }
    }

    int getCurrentRunTime() {
        return getCurrentGameTime() - getPlayerStartTime();
    }

    void updateFastestRun(CpLog in_cplog) {
        log("Updating fastest run: " + in_cplog.tostring());
        fastest_run = in_cplog;
        ACTIVE_NUM_CPS = fastest_run.cp_id;
        if (fastest_run_cp_times.Length != fastest_run.cp_id + 1) {
            fastest_run_cp_times.Resize(fastest_run.cp_id + 1);
            slowest_run_cp_times.Resize(fastest_run.cp_id + 1);
        }
    }

    /**
     * Saves the previous checkpoint information to the active run buffer.
     */
    void saveCheckpointInformation() {
        active_run_buffer.InsertLast(
            CpLog(active_map_uuid, current_run_id, current_cp_idx, getCurrentRunTime())
        );
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


    void reloadValueRange() {
        valueRange = vec4(0, 1, 0, 1);
    }

    void renderCpLogArray(array<CpLog> drawn_cp_array, vec4 color) {
        if (drawn_cp_array.Length == 0) {
            return;
        }
        float x_loc, y_loc; 
        nvg::BeginPath();
        nvg::MoveTo(TransformToViewBounds(ClampVec2(vec2(0, 0), valueRange), min, max));
        for (int i = 0; i < drawn_cp_array.Length; i++) {
            x_loc = fastest_run_cp_times[drawn_cp_array[i].cp_id] / fastest_run.cp_time;

            float ft = fastest_run_cp_times[drawn_cp_array[i].cp_id];
            float st = slowest_run_cp_times[drawn_cp_array[i].cp_id];
            float ct = drawn_cp_array[i].cp_time;
            y_loc = (st - ct) / (st - ft);

            nvg::LineTo(TransformToViewBounds(ClampVec2(vec2(x_loc, y_loc), valueRange), min, max));
        }
        nvg::StrokeColor(color);
        nvg::StrokeWidth(LineWidth);
        nvg::Stroke();
        nvg::ClosePath();


    }

    void doCpLogRefresh(string map_uuid) {
        active_map_uuid = map_uuid;
        current_run_id = databasefunctions.getMaxPreviousRunId(map_uuid) + 1;
        cp_log_array = databasefunctions.getCpLogsForMap(map_uuid);

        if (cp_log_array.Length > 0 && cp_log_array[0].Length > 0) {
            updateFastestRun(cp_log_array[0][cp_log_array[0].Length - 1]);
            for(int i = 0; i < cp_log_array[0].Length; i++) {
                float _min = 10 ** 5;
                float _max = 0; 
                for (int j = 0; j < cp_log_array.Length; j++) {
                    if (cp_log_array[j].Length == 0) {
                        continue;
                    }
                    _min = Math::Min(_min, cp_log_array[j][i].cp_time);
                    _max = Math::Max(_max, cp_log_array[j][i].cp_time);
                }
                fastest_run_cp_times[i] = _max;
                slowest_run_cp_times[i] = _min;
            }
        } else {
            ACTIVE_NUM_CPS = 0;
            MAX_MAP_TIME = 100 * 100;
        }
        reloadValueRange();
    }

    void handleMapUpdate() {
        string map_uuid = getMapUid();
        if (map_uuid == "" || map_uuid == active_map_uuid) {
            return;
        }
        doCpLogRefresh(map_uuid);
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