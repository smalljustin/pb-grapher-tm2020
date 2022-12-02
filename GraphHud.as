// Common Stuff:
const string DEFAULT_LOG_NAME = Meta::ExecutingPlugin().Name;

void log(const string & in msg) {
    log(DEFAULT_LOG_NAME, msg);
}
void log(const string & in name,
    const string & in msg) {
    print("[\\$669" + name + "\\$z] " + msg);
}


class GraphHud {
    PbGrapherWindow pbGrapherWindow();
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

    void update() {
        pbGrapherWindow.Update();
    }


    void OnSettingsChanged() {
        if (override_center_graph) {
            graph_x_offset = (Draw::GetWidth()) / 2 - (graph_width / 2);
        }

        pbGrapherWindow.UpdateSettings();
        m_size = vec2(graph_width, graph_height);
        if (SYNC_TARMAC_GENERAL_SLIP) {
            GDP_SLIP_BOUND = TARMAC_SLIP_BOUND;
        }
    }




    void Render(CSceneVehicleVisState @ visState) {
        nvg::BeginPath();
        nvg::RoundedRect(graph_x_offset, graph_y_offset, m_size.x, m_size.y, BorderRadius);

        nvg::FillColor(BackdropColor);
        nvg::Fill();

        nvg::StrokeColor(BorderColor);
        nvg::StrokeWidth(BorderWidth);
        nvg::Stroke();

        pbGrapherWindow.Render(m_size, LineWidth);
    }
}