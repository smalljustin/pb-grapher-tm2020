[Setting category="General" name="Enable utility"]
bool g_visible = true;

[Setting category="Display" name="Graph width" drag min=50 max=2000  ]
int graph_width = 500;

[Setting category="Display" name="Graph height" drag min=50 max=1000 ]
int graph_height = 150;

[Setting category="Display" name="Graph x offset" drag min=0 max=4000]
int graph_x_offset = 32;

[Setting category="Display" name="Graph y offset" drag min=0 max=2000]
int graph_y_offset = 32;

[Setting category="Display" name="Graph Projection Line Width" drag min=0 max=5]
float LineWidth = 2.0f;

[Setting category="Display" name="Backdrop Color" color]
vec4 BackdropColor = vec4(.317, .312, .312, 0.7f);

[Setting category="Display" name="Border color" color]
vec4 BorderColor = vec4(0, 0, 0, 1);

[Setting category="Display" name="Border width" drag min=0 max=10]
float BorderWidth = 1.0f;	

[Setting category="Display" name="Border radius" drag min=0 max=50]
float BorderRadius = 5.0f;

[Setting category="Display" name="Padding" drag min=0 max=.5]
float Padding = .25f;

// ############ NEW SHIT

[Setting category="General" name="Scatter view: Past runs to draw" drag min=2 max=500]
int NUM_SCATTER_PAST_GHOSTS = 50;

[Setting category="General" name="Seconds to show above PB" drag min=0 max=60]
float PB_TOP_MULT = 3;

[Setting category="General" name="Seconds to show below PB" drag min=-60 max=0]
float PB_BOTTOM_MULT = -.5;

[Setting category="General" name="Scatter view: Draw Author Line"]
bool DRAW_AUTHOR = true;

[Setting category="Display" name="Author line color" color]
vec4 AUTHOR_COLOR = vec4(0.003921568, 0.20784, 0.16078, 1);

[Setting category="General" name="Scatter view: Draw Gold Line"]
bool DRAW_GOLD = true;

[Setting category="Display" name="Gold line color" color]
vec4 GOLD_COLOR = vec4(0.6823529411764706, 0.5529411764705882, 0.192156862745098, .7);

[Setting category="General" name="Scatter view: Draw Silver Line"]
bool DRAW_SILVER = true;

[Setting category="Display" name="Silver line color" color]
vec4 SILVER_COLOR = vec4(.6509803921568627, .6509803921568627, .6509803921568627, .7);

[Setting category="General" name="Scatter view: Draw Bronze Line"]
bool DRAW_BRONZE = true;

[Setting category="Display" name="Bronze line color" color]
vec4 BRONZE_COLOR = vec4(0.5490196078431373, 0.3529411764705882, 0.203921568627451, .7);

[Setting category="General" name="Line graph view: Past runs to draw" drag min=2 max=200]
int NUM_LINE_PAST_GHOSTS = 5;

[Setting category="General" name="View best runs by checkpoint"]
bool VIEW_BY_CHECKPOINT = false;

[Setting category="General" name="Best runs falloff ratio" drag min=0.7 max=1]
float RUN_FALLOFF_RATIO = 0.95f;

[Setting category="General" name="Point radius"]
float POINT_RADIUS = 2;

[Setting category="Display" name="Point fade color" color]
vec4 POINT_FADE_COLOR = vec4(1, 1, 1, 1);

[Setting category="Display" name="PB Color" color]
vec4 PB_COLOR = vec4(0.0, 0.9411764705882353, 0.9764705882352941, 1);