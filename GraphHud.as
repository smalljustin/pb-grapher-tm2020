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
    ByCheckpointLineGraph byCheckpointLineGraph();
    AllRunsScatterPlot allRunsScatterPlot();

    void update() {
        if (VIEW_BY_CHECKPOINT) {
            byCheckpointLineGraph.Update();
        } else {
            allRunsScatterPlot.Update();
        }
    }

    void OnSettingsChanged() {
        m_size = vec2(graph_width, graph_height);
        if (VIEW_BY_CHECKPOINT) {
            byCheckpointLineGraph.UpdateSettings();
        } else {
            allRunsScatterPlot.UpdateSettings();
        }
    }

    void Render() {
        nvg::BeginPath();
        nvg::RoundedRect(graph_x_offset, graph_y_offset, m_size.x, m_size.y, BorderRadius);
        nvg::FillColor(BackdropColor);
        nvg::Fill();

        nvg::StrokeColor(BorderColor);
        nvg::StrokeWidth(BorderWidth);
        nvg::Stroke();

        if (VIEW_BY_CHECKPOINT) {
            byCheckpointLineGraph.Render(m_size, LineWidth);
        } else {
            allRunsScatterPlot.Render(m_size, LineWidth);
        }
    }
}