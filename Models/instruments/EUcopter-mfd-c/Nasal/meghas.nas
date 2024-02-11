# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

var HELIONIXPATH = "Aircraft/ec145/Models/instruments/EUcopter-mfd-c/";

io.include(HELIONIXPATH ~ "Nasal/common.nas");
io.include(HELIONIXPATH ~ "Nasal/meghas_mfd_control.nas");

# start the air data computer sensor loops
io.include(HELIONIXPATH ~ "Nasal/airdata.nas");

# list of allowed of modules (=pages) names
var MODULES = ["init2", "pfd", "vemd", "cad"];

# load the page code
foreach (var x; MODULES) 
     io.include(HELIONIXPATH~"Nasal/"~x~"_page.nas");
     
mfd_add([1024, 1024], [1024, 1024]); # mfd0 plt PFD/NAVD
mfd_add([1024, 1024], [1024, 1024]); # mfd1 coplt PFD/NAVD
mfd_add([1024, 1024], [1024, 1024]); # mfd2 vemd
mfd_add([1024, 1024], [1024, 1024]); # mfd3 cad

# init the startup
setlistener("sim/signals/fdm-initialized", func {
  
    print("Initializing MEGHAS MFD ...");
    
    for (var i=0; i<size(mfd); i += 1) {
      
        # setup all pages on each MFD
        mfd[i].display.addPlacement({"node": "xmfd"~i~"screen"});
        pages = split(",", getprop("/instrumentation/mfd["~i~"]/mode-list"));
        
        foreach (var pg; pages) {
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
    # force a refresh of all sensors to init screen animations
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
  var debugloop=1;
  var dtimer = maketimer(5, func {
     adc._benchmark_(debugloop);    
     debugloop+=1;
  });
  dtimer.start();
};
