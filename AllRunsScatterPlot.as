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

    float standard_deviation = 0;
    
    bool loaded = false;

    float input_target_time = 30;

    vec4 bounding_rect(0, 0, 0, 0);

    int precision;

    CpLog fastest_run;
    CpLog slowest_run;

    array<array<CpLog>> cp_log_array(0, array<CpLog>(0));
    array<CpLog> active_run_buffer(0, CpLog());

    array<HistogramGroup> histogramGroupArray();

    array<CustomTimeTarget> custom_time_targets();

    bool RUN_IS_RESPAWN;

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


    bool isIdxFinish(int idx) {
        return getPlayground().Arena.MapLandmarks[idx].Waypoint.IsFinish;
    }

    void OnSettingsChanged() {
        reloadValueRange();
        bounding_rect = vec4(graph_x_offset, graph_x_offset + m_size.x, graph_y_offset, graph_y_offset + m_size.y);
    }

     
    int getCurrentGameTime() {
        return getPlayground().Interface.ManialinkScriptHandler.GameTime;
    }

    float GET_SLOWEST_RUN_CUTOFF() {
        if (HISTOGRAM_VIEW) {
            return SLOW_RUN_CUTOFF_HIST;
        } else {
            return SLOW_RUN_CUTOFF_SCATTER;
        }
    }

    /**
     * Returns the player's starting time as an integer. 
     */
    int getPlayerStartTime() {
        return getPlayer().StartTime;
    }

    void testPlayerRespawned() {
        if (RUN_IS_RESPAWN) {
            return;
        }
        auto player = getPlayer();
        auto scriptPlayer = player is null ? null : cast<CSmScriptPlayer>(player.ScriptAPI);
        RUN_IS_RESPAWN = scriptPlayer.Score.NbRespawnsRequested > 0;
    }

    void renderCustomInputMenu() {
        if (showTimeInputWindow) {
            UI::Begin("Enter a custom time target", UI::WindowFlags::AlwaysAutoResize);
                input_target_time = UI::InputFloat("Target time", input_target_time, 0.005);
                if (UI::Button("Save", vec2(200, 30))) {
                    databasefunctions.addCustomTimeTarget(active_map_uuid, input_target_time);
                    doCustomTimeTargetRefresh();
                };
                if (UI::Button("Remove All", vec2(200, 30))) {
                    databasefunctions.removeAllCustomTimeTargets(active_map_uuid);
                    doCustomTimeTargetRefresh();
                };

            UI::End();
        }
    }

    void renderMouseHover() {
        if (shouldRenderHistStatistics()) {
            return;
        }
        vec2 mouse_pos = UI::GetMousePos();
        if (mouse_pos.x > bounding_rect.x && mouse_pos.x < bounding_rect.y && mouse_pos.y > bounding_rect.z && mouse_pos.y < bounding_rect.w) {
            string text; 

            if (HISTOGRAM_VIEW) {
                float mouse_hover_x = Math::Lerp(valueRange.x, valueRange.y, Math::InvLerp(bounding_rect.x, bounding_rect.y, mouse_pos.x));
                float mouse_hover_y = Math::Lerp(valueRange.z, valueRange.w, Math::InvLerp(bounding_rect.w, bounding_rect.z, mouse_pos.y));

                int idx = (mouse_hover_x - fastest_run.cp_time) / precision;

                if (idx < 0 || idx >= histogramGroupArray.Length) {
                    return;
                }
                HistogramGroup @histGroup = histogramGroupArray[idx];

                if (precision == 1) {
                    text = "Time: " + Text::Format("%.3f", histGroup.lower / 1000);
                } else {
                    text = "Time: " + Text::Format("%.3f", histGroup.lower / 1000) + " to " + Text::Format("%.3f", histGroup.upper / 1000);
                }

                text += "\tRuns: " + tostring(Math::Ceil(histGroup.cpLogArrays.Length));

            } else {
                float mouse_hover_y = Math::Lerp(valueRange.z, valueRange.w, Math::InvLerp(bounding_rect.w, bounding_rect.z, mouse_pos.y));
                text = "Time: " + tostring(Math::Round(mouse_hover_y / 10) / 100);
            }

            nvg::BeginPath();
            // nvg::Rect(mouse_pos - vec2(0, nvg::TextBounds(text).y), nvg::TextBounds(text));
            nvg::FillColor(vec4(.9, .9, .9, 1));
            // nvg::Fill();
            nvg::Text(mouse_pos, text);
            nvg::Stroke();
            nvg::ClosePath();
        }
    }

    bool shouldRenderHistStatistics() {
        vec2 textPos = vec2(graph_width + graph_x_offset, graph_y_offset * 2);

        if (((UI::GetMousePos() + vec2(80, 0)) - textPos).LengthSquared() > 10000) {
            return false;
        }
        return true;
    }

    void renderHistStatistics() {
        vec2 textPos = vec2(graph_width + graph_x_offset, graph_y_offset * 2);

        if (!shouldRenderHistStatistics()) {
            return;
        }

        array<string> lines();

        lines.InsertLast("\n\nStatistics");
        // lines.InsertLast("----------------------------");
        // lines.InsertLast( "Total Runs: " + Text::Format("%d", cp_log_array.Length));
        
        vec2 textSize = nvg::TextBounds(lines[0]);
        // vec2 textPos = vec2(graph_width + graph_x_offset, graph_y_offset);
        // textPos = UI::GetMousePos();

        textPos -= textSize * 1.1;
        nvg::BeginPath();
        nvg::FillColor(vec4(.9, .9, .9, 1));
        nvg::TextAlign(0);

        for (int i = 0; i < lines.Length; i++) {
            string text = lines[i];
            nvg::Text(textPos, text);
            textPos.y += textSize.y + 4;
        }

        textPos.y += 4;

        int i = 0;
        while (true) {
            if (histogramGroupArray[i].cpLogArrays.Length != 0) {
                nvg::Text(textPos, "\n" + Text::Format("%.3f", histogramGroupArray[i].lower / 1000) + ":\t" + tostring(histogramGroupArray[i].cpLogArrays.Length));
                textPos.y += textSize.y + 4;
            }
            i += 1;

            if (textPos.y > (graph_y_offset + graph_height - ((textSize.y * BOTTOM_MARGIN) + 4))) {
                break;
            }
        }
        nvg::Stroke();
        nvg::ClosePath();
    }
    
    void Render(vec2 parentSize, float LineWidth) {
        // log(tostring(UI::GetMousePos()));
        if (!g_visible) {
            return;
        }
        if (cp_log_array.Length == 0) {
            return;
        }
        float _padding = padding;
        min = vec2(_padding, parentSize.y - _padding);
        max = vec2(parentSize.x - _padding, _padding);

        if (!HISTOGRAM_VIEW) {
            vec4 active_color = POINT_FADE_COLOR;

            for (int i = 0; i < cp_log_array.Length; i++) {
                renderRunHistoryScatter(cp_log_array[i], PB_COLOR, active_color);
            }
            renderRightSideScatter(fastest_run, PB_COLOR);
        } else {
            renderHistogram();
            renderHistStatistics();
        }
        renderMouseHover();
        renderMedals();
        renderCustomInputMenu();
    }

    void doCustomTimeTargetRefresh() {
        custom_time_targets = databasefunctions.getCustomTimeTargetsForMap(active_map_uuid);
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
            active_run_buffer = array<CpLog>();
            RUN_IS_RESPAWN = false;
            return false;
        }
    }

    void handleWatchCheckpoint() {
        testPlayerRespawned();
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
            if (!RUN_IS_RESPAWN || SAVE_RESPAWN_RUNS) {
                databasefunctions.persistBuffer(active_run_buffer);
                cp_log_array.InsertLast(active_run_buffer);
                current_run_id += 1;
                reloadValueRange();
                startnew(CoroutineFunc(this.delayedActiveCpLogRefresh));
            }
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

    void updateFastestRun() {
        fastest_run = cp_log_array[0][cp_log_array[0].Length - 1];
        for (int i = 0; i < cp_log_array.Length; i++) {
            CpLog @curCpLog = cp_log_array[i][cp_log_array[i].Length - 1];
            if (curCpLog.cp_time < fastest_run.cp_time) {
                fastest_run = curCpLog;
            }
        }
        ACTIVE_NUM_CPS = fastest_run.cp_id;
    }

    void updateSlowestRun() {
        slowest_run = fastest_run;
        for (int i = 0; i < cp_log_array.Length; i++) {
            CpLog @curCpLog = cp_log_array[i][cp_log_array[i].Length - 1];
            if (curCpLog.cp_time > fastest_run.cp_time * GET_SLOWEST_RUN_CUTOFF()) {
                continue;
            }
            if (curCpLog.cp_time > slowest_run.cp_time) {
                slowest_run = curCpLog;
            }
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

    void reloadValueRange() {
        if (cp_log_array.Length > 0 && cp_log_array[0].Length > 0) {
            updateFastestRun();
            updateSlowestRun();
        } else {
            ACTIVE_NUM_CPS = 0;
            MAX_MAP_TIME = 100 * 100;
        }
        standard_deviation = getStandardDeviation(cp_log_array, NUM_SCATTER_PAST_GHOSTS);
        updateHistogramGroups();
        if (HISTOGRAM_VIEW) {
            reloadValueRangeHistogram();
        } else {
            reloadValueRangeScatter();
        }

    }

    void reloadValueRangeHistogram() {
        valueRange = vec4(fastest_run.cp_time - 3 * precision, fastest_run.cp_time * GET_SLOWEST_RUN_CUTOFF(), -1, getMaxHistogramCount() + 1);
    }

    void reloadValueRangeScatter() {
        int max_run_id = 0;
        int min_run_id = 10 ** 5;


        for (int i = 0; i < cp_log_array.Length; i++) {
            min_run_id = Math::Min(min_run_id, cp_log_array[i][0].run_id);
            max_run_id = Math::Max(max_run_id, cp_log_array[i][0].run_id);
        }
        min_run_id = Math::Max(min_run_id, max_run_id - NUM_SCATTER_PAST_GHOSTS);

        valueRange = vec4(min_run_id - 1, max_run_id + 1, fastest_run.cp_time - LOWER_STDEV_MULT * standard_deviation, fastest_run.cp_time + standard_deviation * UPPER_STDEV_MULT);
    }

    void renderRunHistoryScatter(array<CpLog> @drawn_cp_array, vec4 pb_color, vec4 active_color) {
        if (drawn_cp_array.Length == 0) {
            return;
        }
        float x_loc, y_loc; 

        CpLog @run_cplog = drawn_cp_array[drawn_cp_array.Length - 1];
        
        vec4 current_color;
        
        if (run_cplog.cp_log_id == fastest_run.cp_log_id) {
            current_color = pb_color;
        } else {
            current_color = active_color;
        }
        x_loc = run_cplog.run_id;
        y_loc = run_cplog.cp_time;

        if (x_loc <= valueRange.x) {
            return;
        }
        if (y_loc >= valueRange.w) {
            if (!SHOW_OVERTIME_RUNS) {
                return;
            } else {
                current_color = OVERTIME_RUN_COLOR;
                if (run_cplog.cp_time < valueRange.w + standard_deviation * UPPER_STDEV_MULT * OVERTIME_MAX_CONSTANT ** 2) {
                    float mult = Math::InvLerp(valueRange.w, valueRange.w + standard_deviation * OVERTIME_MAX_CONSTANT ** 2 * UPPER_STDEV_MULT, run_cplog.cp_time);
                    current_color *= mult;
                }
            }
        } else {
            if (run_cplog.cp_log_id != fastest_run.cp_log_id) {
                float mult = 1 - Math::InvLerp(valueRange.z, valueRange.w, run_cplog.cp_time);
                current_color *= mult;
            }
        }



        vec2 max_with_width = max;
        if (DRAW_RIGHT_SIDE_SCATTER) {
            max_with_width.x -= graph_width / RIGHT_SCATTER_BAR_WIDTH;
        }
        
        current_color.w = 1;

        nvg::BeginPath();
        nvg::Circle(
            TransformToViewBounds(ClampVec2(vec2(x_loc, y_loc), valueRange), min, max_with_width),
            POINT_RADIUS
        );
        nvg::StrokeColor(current_color);
        nvg::StrokeWidth(POINT_RADIUS ** 2);
        nvg::Stroke();
        nvg::ClosePath();

        renderRightSideScatter(run_cplog, POINT_FADE_COLOR);
    }

    void renderRightSideScatter(CpLog @run_cplog, vec4 color) {
        if (!DRAW_RIGHT_SIDE_SCATTER) {
            return;
        }
        float x_loc, y_loc; 

        x_loc = valueRange.y;
        y_loc = run_cplog.cp_time;

        if (y_loc > valueRange.w) {
            return;
        }
        vec4 current_color = color;
        
        if (run_cplog.run_id != fastest_run.run_id) {
            current_color.w = RIGHT_SIDE_SCATTER_POINT_OPACITY;
        } else {
            current_color.w = (1 + RIGHT_SIDE_SCATTER_POINT_OPACITY) / 2;
        }

        float width = graph_width / RIGHT_SCATTER_BAR_WIDTH;
        float height = graph_height / RIGHT_SCATTER_BAR_HEIGHT;

        vec2 pos = TransformToViewBounds(ClampVec2(vec2(x_loc, y_loc), valueRange), min, max);
        pos.x -= width;
        pos.y -= height;
        pos.y += (height / 2);

        vec2 size = vec2(width, height);


        nvg::BeginPath();
        nvg::RoundedRect(pos, size, RIGHT_SIDE_BORDER_RADIUS);
        nvg::FillColor(current_color);
        nvg::Fill();
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

        for (int i = 0; i < custom_time_targets.Length; i++) {
            renderMedal(custom_time_targets[i].target_time, CUSTOM_TARGET_COLOR);
        }
    }

    void renderMedal(float time, vec4 color) {
        if (HISTOGRAM_VIEW && SHOW_MEDALS_IN_HISTOGRAM) {
            if (time > valueRange.x && time < valueRange.y) {
                nvg::BeginPath();
                nvg::MoveTo(TransformToViewBounds(ClampVec2(vec2(time, valueRange.z), valueRange), min, max));
                nvg::LineTo(TransformToViewBounds(ClampVec2(vec2(time, valueRange.w), valueRange), min, max));
                nvg::StrokeColor(color);
                nvg::StrokeWidth(LineWidth);
                nvg::Stroke();
                nvg::ClosePath();
            }
        } else {
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


    }

    void delayedActiveCpLogRefresh() {
        doCpLogRefresh(active_map_uuid);
    }

    void doCpLogRefresh(string _map_uuid) {
        active_map_uuid = _map_uuid;
        current_run_id = databasefunctions.getMaxPreviousRunId(_map_uuid) + 1;
        cp_log_array = databasefunctions.getCpLogsForMap(_map_uuid);
        reloadValueRange();
    }


    void handleMapUpdate() {
        string map_uuid = getMapUid();
        if (map_uuid == "" || map_uuid == active_map_uuid) {
            return;
        }
        doCpLogRefresh(map_uuid);
        doCustomTimeTargetRefresh();
        input_target_time = getAuthor() / 1000;
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

    void updateHistogramGroups() {
        if (cp_log_array.Length == 0) {
            return;
        }
        precision = HIST_PRECISION_VALUE * 1000;
        histogramGroupArray = array<HistogramGroup>();
        for (int i = fastest_run.cp_time; i < fastest_run.cp_time * GET_SLOWEST_RUN_CUTOFF(); i += precision) {
            histogramGroupArray.InsertLast(HistogramGroup(i, i + precision));
        }

        int end_pos = cp_log_array.Length - HIST_RUN_START_OFFSET;
        int start_pos = Math::Max(0, end_pos - HIST_RUNS_TO_SHOW);
        
        for (int i = start_pos; i < end_pos; i++) {
            float time = cp_log_array[i][cp_log_array[i].Length - 1].cp_time;
            int idx = (time - fastest_run.cp_time) / precision;
            if (idx >= histogramGroupArray.Length) {
                continue;
            }
            histogramGroupArray[idx].cpLogArrays.InsertLast(cp_log_array[i]);
        }
    }

    int getMaxHistogramCount() {
        float m = 0; 
        for (int i = 0; i < histogramGroupArray.Length; i++) {
            m = Math::Max(histogramGroupArray[i].cpLogArrays.Length, m);
        }
        return m;
    }

    int getMaxRunId(HistogramGroup @histogramGroup) {
        if (histogramGroup.maxRunId != -1) {
            return histogramGroup.maxRunId;
        } else {
            histogramGroup.maxRunId = getMaxRunId(histogramGroup.cpLogArrays);
            return histogramGroup.maxRunId;
        }
    }

    int getMinRunId(HistogramGroup @histogramGroup) {
        if (histogramGroup.minRunId != -1) {
            return histogramGroup.minRunId; 
        } else {
            histogramGroup.minRunId = getMinRunId(histogramGroup.cpLogArrays);
            return histogramGroup.minRunId; 
        }
    }

    int getMaxRunId(array<array<CpLog>@>@ cp_log_array) {
        int max_run_id = -1;
        for (int i = 0; i < cp_log_array.Length; i++) {
            max_run_id = Math::Max(max_run_id, cp_log_array[i][0].run_id);
        }

        return max_run_id; 
    }

    int getMinRunId(array<array<CpLog>@>@ cp_log_array) {
        int min_run_id = 10 ** 6;
        for (int i = 0; i < cp_log_array.Length; i++) {
            min_run_id = Math::Min(min_run_id, cp_log_array[i][0].run_id);
        }
        return min_run_id;
    }

    void renderHistogram() {
        for (int i = 0; i < histogramGroupArray.Length; i++) {
            for (int j = 0; j < histogramGroupArray[i].cpLogArrays.Length; j++) {
                array<CpLog>@ activeArr = histogramGroupArray[i].cpLogArrays[j];
                float x_loc = activeArr[activeArr.Length - 1].cp_time;
                float y_loc = Math::Lerp(0, histogramGroupArray[i].cpLogArrays.Length, 
                    Math::InvLerp(
                        getMinRunId(@histogramGroupArray[i]),
                        getMaxRunId(@histogramGroupArray[i]
                    ),
                    activeArr[0].run_id));

                if (histogramGroupArray[i].cpLogArrays.Length == 1) {
                    y_loc = 0;
                }
                
                vec4 color = OVERTIME_RUN_COLOR * Math::InvLerp(0, current_run_id, activeArr[0].run_id) ** 0.5;

                if (x_loc == fastest_run.cp_time) {
                    color = CUSTOM_TARGET_COLOR;
                }
                

                nvg::BeginPath();
                nvg::Circle(
                TransformToViewBounds(ClampVec2(vec2(x_loc, y_loc), valueRange), min, max),
                POINT_RADIUS
                );
                nvg::StrokeColor(color);
                nvg::StrokeWidth(POINT_RADIUS ** 2);
                nvg::Stroke();
                nvg::ClosePath();
            }
        }
    }

    

}