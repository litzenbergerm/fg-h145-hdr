# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

var helionixpath = "Aircraft/ec145/Models/instruments/EUcopter-mfd-c/";
var DEBUG = 0;
var DEBUG_TIME = 5;
var ENABLE_PROP_RULES = 0; # 0 to disable or 1/frq. in Hz, DO NOT ENABLE/NOT IMPLEMENTED!
var ENABLE_THREADS = 0;
var FAST= 1/20; # 20 Hz
var SLOW = 1/2; # 2 Hz

# those need to be in the global scope
var fnd_canvas = nil;
var fnd_display = nil;
var vmd_canvas = nil;
var vmd_display = nil;
var adc = nil;

var font_mapper = func(family, weight)
{
        return "LiberationFonts/LiberationSansNarrow-Bold.ttf";
        #return "isocpeur.ttf";
      
        if( family == "'Liberation Sans'" and weight == "normal" )
                return "LiberationFonts/LiberationSans-Regular.ttf";

        if( family == "'Liberation Sans'" and weight == "bold" )
                return "LiberationFonts/LiberationSans-Regular.ttf";

};

io.include(helionixpath ~ "Nasal/sensor.nas");
io.include(helionixpath ~ "Nasal/filter.nas");
io.include(helionixpath ~ "Nasal/mfd.nas");
io.include(helionixpath ~ "Nasal/masterlist.nas");
io.include(helionixpath ~ "Nasal/vmd_screen_func.nas");
io.include(helionixpath ~ "Nasal/fnd_screen_func.nas");

# init the startup
setlistener("sim/signals/fdm-initialized", func {
  
    io.include(helionixpath ~ "Nasal/airdata.nas");
    io.include(helionixpath ~ "Nasal/fnd_screen.nas");
    io.include(helionixpath ~ "Nasal/vmd_screen.nas");
    
    # place the displays on the screens
    fnd_display.addPlacement({"node": "xmfd0screen"});
    fnd_display.addPlacement({"node": "xmfd2screen"});
    vmd_display.addPlacement({"node": "xmfd1screen"});
    
    helionix.showPfd = func() {
        var dlg = canvas.Window.new([500, 500], "dialog").set("resize", 1);
        dlg.setCanvas(fnd_display);
    };
    
});


setlistener("sim/signals/reinit", func {
  vmd_canvas.del();
  fnd_canvas.del();
  adc.del();
});
