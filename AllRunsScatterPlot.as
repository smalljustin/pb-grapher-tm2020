class AllRunsScatterPlot 
{
    float padding = 0;
    int ACTIVE_NUM_CPS = 0;
    float MAX_MAP_TIME = 0;
    vec4 valueRange;
    vec2 min, max;
    string active_map_uuid = "";

    int current_run_starttime;
    int current_run_id;
    int current_cp_id;
    int current_cp_idx;
    int current_lap = 1;
    
    bool loaded = false;

    CpLog fastest_run;
    CpLog slowest_run;

    array<array<CpLog>> cp_log_array(0, array<CpLog>(0));
    array<CpLog> active_run_buffer(0, CpLog());


    AllRunsScatterPlot() {
    }

    vec4 renderTrailsColor(1, 1, 1, 1);


    void Update() {
        handleMapUpdate();
        if (getCurrentCheckpoint() == -1) {
            return;
        }
        handleRunStart();
        handleWatchCheckpoint();
    }

    float getAuthor() {
        return GetApp().RootMap.TMObjective_AuthorTime;
    }
    float getGold() {
        return GetApp().RootMap.TMObjective_GoldTime;
    }
    float getSilver() {
        return GetApp().RootMap.TMObjective_SilverTime;
    }
    float getBronze() {
        return GetApp().RootMap.TMObjective_BronzeTime;
    }
    int getNumLaps() {
        return GetApp().RootMap.TMObjective_NbLaps;
    }
    bool isMultiLap() {
        return GetApp().RootMap.TMObjective_IsLapRace;
    }

    void Render(vec2 parentSize, float LineWidth) {
        if (cp_log_array.Length == 0) {
            return;
        }
        float _padding = padding;
        min = vec2(_padding, parentSize.y - _padding);
        max = vec2(parentSize.x - _padding, _padding);

        vec4 active_color = POINT_FADE_COLOR;
        for (int i = 0; i < cp_log_array.Length; i++) {
            renderRunHistoryScatter(cp_log_array[i], active_color);
        }
        renderMedals();
    }

    bool isIdxFinish(int idx) {
        return getPlayground().Arena.MapLandmarks[idx].Waypoint.IsFinish;
    }

    void UpdateSettings() {
        doCpLogRefresh(active_map_uuid);
    }

     
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

        bool race_completed = false;
        if (isMultiLap()) {
            log("Current lap: " + tostring(current_lap));
            if (isIdxFinish(current_cp_id)) {
                if (current_lap == getNumLaps()) {
                    race_completed = true;
                    current_lap = 1;
                } else {
                    current_lap += 1;
                }
            }
        } else if (isIdxFinish(current_cp_id)) {
            race_completed = true;
        }
        if (race_completed) {
            databasefunctions.persistBuffer(active_run_buffer);
            current_run_id += 1;
            doCpLogRefresh(active_map_uuid);
            race_completed = false;
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
        fastest_run = in_cplog;
        ACTIVE_NUM_CPS = fastest_run.cp_id;
    }

    void updateSlowestRun(CpLog in_cplog) {
        slowest_run = in_cplog;
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

    void reloadValueRange() {
        int max_run_id = 0;
        int min_run_id = 10 ** 5;

        for (int i = 0; i < cp_log_array.Length; i++) {
            min_run_id = Math::Min(min_run_id, cp_log_array[i][0].run_id);
            max_run_id = Math::Max(max_run_id, cp_log_array[i][0].run_id);
        }
        min_run_id = Math::Max(min_run_id, max_run_id - NUM_SCATTER_PAST_GHOSTS);

        valueRange = vec4(min_run_id - 1, max_run_id + 1, Math::Max(fastest_run.cp_time + PB_BOTTOM_MULT * 1000, 0), fastest_run.cp_time  + PB_TOP_MULT * 1000);
    }

    void renderRunHistoryScatter(array<CpLog> drawn_cp_array, vec4 color) {
        if (drawn_cp_array.Length == 0) {
            return;
        }
        float x_loc, y_loc; 

        CpLog run_cplog = drawn_cp_array[drawn_cp_array.Length - 1];
        x_loc = run_cplog.run_id;
        y_loc = run_cplog.cp_time;

        if (x_loc < valueRange.x) {
            return;
        }
        if (y_loc > valueRange.w) {
            return;
        }
        
        vec4 current_color = color;

        if (run_cplog.cp_log_id != fastest_run.cp_log_id) {
            current_color *= RUN_FALLOFF_RATIO ** (1 + (run_cplog.cp_time - fastest_run.cp_time) / 100);
        }
        
        current_color.w = 1;


        nvg::BeginPath();
        nvg::Circle(
            TransformToViewBounds(ClampVec2(vec2(x_loc, y_loc), valueRange), min, max),
            POINT_RADIUS
        );
        nvg::StrokeColor(current_color);
        nvg::StrokeWidth(LineWidth);
        nvg::Stroke();
        nvg::ClosePath();
    }

    void renderMedals() {
        if (DRAW_AUTHOR) {
            renderMedal(getAuthor(), AUTHOR_COLOR);
        }
        if (DRAW_GOLD) {
            renderMedal(getGold(), GOLD_COLOR);
        }
        if (DRAW_SILVER) {
            renderMedal(getSilver(), SILVER_COLOR);
        }
        if (DRAW_BRONZE) {
            renderMedal(getBronze(), BRONZE_COLOR);
        }
    }

    void renderMedal(float time, vec4 color) {
        if (time > valueRange.z && time < valueRange.w) {
            nvg::BeginPath();
            nvg::MoveTo(TransformToViewBounds(ClampVec2(vec2(valueRange.x, time), valueRange), min, max));
            nvg::LineTo(TransformToViewBounds(ClampVec2(vec2(valueRange.y, time), valueRange), min, max));
            nvg::StrokeColor(color);
            nvg::StrokeWidth(LineWidth);
            nvg::Stroke();
            nvg::ClosePath();
        }
    }

    void doCpLogRefresh(string map_uuid) {
        active_map_uuid = map_uuid;
        current_run_id = databasefunctions.getMaxPreviousRunId(map_uuid) + 1;
        cp_log_array = databasefunctions.getCpLogsForMap(map_uuid);

        if (cp_log_array.Length > 0 && cp_log_array[0].Length > 0) {
            updateFastestRun(cp_log_array[0][cp_log_array[0].Length - 1]);
            updateSlowestRun(cp_log_array[cp_log_array.Length - 1][cp_log_array[cp_log_array.Length - 1].Length - 1]);
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
        nvg::LineTo(TransformToViewBounds(ClampVec2(vec2((valueRange.x) + (valueRange.y - valueRange.x), vel_t), valueRange), min, max));
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