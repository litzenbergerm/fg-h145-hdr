# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

var HELIONIXPATH = "Aircraft/ec145/Models/instruments/EUcopter-mfd-c/";

io.include(HELIONIXPATH ~ "Nasal/common.nas");
io.include(HELIONIXPATH ~ "Nasal/helionix_mfd_control.nas");
io.include(HELIONIXPATH ~ "Nasal/masterlist.nas");
io.include(HELIONIXPATH ~ "Nasal/navsymbols.nas");

# list of allowed of modules (=pages) names
var MODULES = ["init", "fnd", "vmd", "navd", "stbyai", "dmap", "efb"];

# load the page code
foreach (var x; MODULES) 
     io.include(HELIONIXPATH~"Nasal/"~x~"_page.nas");
     
# 3D model of screen slightly distorted, therefore not quadratic

mfd_add([1034, 1024], [1034, 1024]); # mfd0 plt FND
mfd_add([1034, 1024], [1034, 1024]); # mfd1 coplt FND
mfd_add([1034, 1024], [1034, 1024]); # mfd2 VMD, NAVD, MAPD
mfd_add([512, 512], [512, 512]);     # mfd3 stby horizon

# init the startup
setlistener("sim/signals/fdm-initialized", func {
  
    print("Initializing Helionix MFD ...");
    
    for (var i=0; i<size(mfd); i += 1) {
      
        # setup all pages on each MFD
        mfd[i].display.addPlacement({"node": "xmfd"~i~"screen"});
        mfd[i].pages = split(",", getprop("/instrumentation/mfd["~i~"]/mode-list"));;
        
        foreach (var pg; mfd[i].pages) {
            # put page p on mfd index i
            if (isin(pg, MODULES) > -1) {
                  page_setup[pg](i);
                  print(i,".",pg);
                  
            }
        }
            
        # start the button and modes handling            
        if (mfdctrl[i] != nil) {
           mfdctrl[i] = EUcoptermfd.new(i);
           mfdctrl[i].run(0.2);
        }           
    }  
    
    # force a refresh of all sensors 
    # to init the screen animations
    adc._refresh_();
    if (USE_CENTRAL_UPDATE_LOOP)
       adc.initUpdates(0);
        
    print(" ... Done.");
});


setlistener("sim/signals/reinit", func {
  adc._del_();
});

# in debug update callback statistics every 5 sec
if (DEBUG) {
  var dtimer = maketimer(5, func {
     adc._benchmark_();    
     debugloop += 1;
  });
  dtimer.start();
};
