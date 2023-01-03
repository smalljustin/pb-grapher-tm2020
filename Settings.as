[Setting category="General" name="Visible"]
bool g_visible = true;

[Setting category="General" name="Draw run distribution chart"]
bool DRAW_RIGHT_SIDE_SCATTER = false;

[Setting category="General" name="Save respawn runs"]
bool SAVE_RESPAWN_RUNS = false;

[Setting category="General" name="View best runs by checkpoint"]
bool VIEW_BY_CHECKPOINT = false;

[Setting category="Display" name="Graph Width" drag min=50 max=2000]
int graph_width = 500;

[Setting category="Display" name="Graph Height" drag min=50 max=1000]
int graph_height = 150;

[Setting category="Display" name="Graph X Offset" drag min=0 max=4000]
int graph_x_offset = 32;

[Setting category="Display" name="Graph Y Offset" drag min=0 max=2000]
int graph_y_offset = 32;

[Setting category="Display" name="Line Width" drag min=0 max=5]
float LineWidth = 2.0f;

[Setting category="Display" name="Backdrop Color" color]
vec4 BackdropColor = vec4(0, 0, 0, 0.7f);

[Setting category="Display" name="Border Color" color]
vec4 BorderColor = vec4(0, 0, 0, 1);

[Setting category="Display" name="Border Width" drag min=0 max=10]
float BorderWidth = 1.0f;

[Setting category="Display" name="Border Radius" drag min=0 max=50]
float BorderRadius = 5.0f;

[Setting category="Display" name="Padding" drag min=0 max=10]
float Padding = .25f;

[Setting category="General" name="Scatter view: Past runs to draw" drag min=2 max=500]
int NUM_SCATTER_PAST_GHOSTS = 100;

[Setting category="General" name="Line graph view: Past runs to draw" drag min=2 max=200]
int NUM_LINE_PAST_GHOSTS = 5;

[Setting category="Display" name="Best runs falloff ratio" drag min=0.7 max=1]
float RUN_FALLOFF_RATIO = 0.95f;

[Setting category="Display" name="Point radius" min=0.1 max=10 drag]
float POINT_RADIUS = 2;

[Setting category="Display" name="Point fade color" color]
vec4 POINT_FADE_COLOR = vec4(1, 1, 1, 1);

[Setting category="Display" name="PB Color" color]
vec4 PB_COLOR = vec4(0.5843137254901961, 0.9764705882352941, 0.8901960784313725, 1.0);

[Setting category="General" name="Scatter point width (fraction of graph_width)" drag min=1 max=80]
float RIGHT_SCATTER_BAR_WIDTH = 20;

[Setting category="General" name="Scatter point height (fraction of graph_height)" drag min=1 max=80]
float RIGHT_SCATTER_BAR_HEIGHT = 20;

[Setting category="Display" name="Right Side Scatter point opacity" drag min=0.01 max=1]
float RIGHT_SIDE_SCATTER_POINT_OPACITY = 0.1;

[Setting category="Display" name="Right Side Scatter border radius" drag min=0 max=10]
float RIGHT_SIDE_BORDER_RADIUS = 5; 

[Setting category="General" name="Standard deviations to show below PB" drag min=0 max=2]
float LOWER_STDEV_MULT = 0.5;

[Setting category="General" name="Standard deviations to show above PB" drag min=0 max=8]
float UPPER_STDEV_MULT = 2.5;

[Setting category="Display" name="Custom target color" color]
vec4 CUSTOM_TARGET_COLOR = vec4(0.5215686274509804, 0.4196078431372549, 0.6039215686274509, 1.0);

[Setting category="Medals" name="Draw Author Line"]
bool DRAW_AUTHOR = true;

[Setting category="Medals" name="Author Line Color" color]
vec4 AUTHOR_COLOR = vec4(0.003921568, 0.20784, 0.16078, 1);

[Setting category="Medals" name="Draw Gold Line"]
bool DRAW_GOLD = true;

[Setting category="Medals" name="Gold Line Color" color]
vec4 GOLD_COLOR = vec4(0.6823529411764706, 0.5529411764705882, 0.192156862745098, .7);

[Setting category="Medals" name="Draw Silver Line"]
bool DRAW_SILVER = true;

[Setting category="Medals" name="Silver Line Color" color]
vec4 SILVER_COLOR = vec4(.6509803921568627, .6509803921568627, .6509803921568627, .7);

[Setting category="Medals" name="Draw Bronze Line"]
bool DRAW_BRONZE = true;

[Setting category="Medals" name="Bronze Line Color" color]
vec4 BRONZE_COLOR = vec4(0.5490196078431373, 0.3529411764705882, 0.203921568627451, .7);

[Setting category="General" name="Cutoff Multiplier for Slow Runs" drag min=1 max=3]
float SLOW_RUN_CUTOFF = 1.15;

[Setting category="General" name="Show over-time runs in graph"]
bool SHOW_OVERTIME_RUNS = true;

[Setting category="General" name="Over-time run color" color]
vec4 OVERTIME_RUN_COLOR = vec4(0.19215686274509805, 0.6235294117647059, 0.5803921568627451, 1.0);

[Setting category="General" name="Over-time run color fade constant" drag min=10 max=1000]
int OVERTIME_RUN_FADE_CONSTANT = 50;

[Setting category="General" name="Enable SSD mode (shorter delay after run)"]
bool SSD = false;
