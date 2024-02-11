# mfd.nas to drive gauges of the VMD MFD #

### Original code copied from EC130.nas, original author Melchior Franz ###
### adopted by litzi for Helionix VMD-, NAVD-, DMAP- and FND-displays ###

# ==== NAVDISPLAY =====
# calculate bearing and distances of navaids for navdisplay (navd).
# the last and the next 4 waypoints of the flightplan are 
# shown on the navd.

var navdisplay = {
  new: func () {
    var m = { parents: [Timerloop.new(), navdisplay] };
    
    m.maxrng = 40;
    m.maxn = 20;
    m.navlist = [];
    m.usedids = std.Vector.new();
    m.navdfilter = 1;
    m.rr = 5;
    m.id = 99;
    return m;
  },

  addsym: func (i, x) {
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/sym",
            x.symbol);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-norm",
            x.reldst);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-nm",
            x.distance_nm);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-bearing",
            x.relbearing);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/bearing-deg",
            x.bearing_deg);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-course",
            x.relcourse);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/id", x.id);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/ils-course", x.course);
    
    var info = "";
    # generate the info string for VOR and ILS
    if (x.symbol == 0 or x.symbol == 5)
         var info = sprintf("%-8.8s %6.2f", x.name, x.frequency/100);
    #..for waypoints     
    if (x.symbol == 1 or x.symbol == 4) var info=sprintf("%-11.11s", x.name);
    
    if (x.symbol == 2)        
         var info = sprintf("%-11.11s %3.0f", x.name, x.frequency/100);
    if (x.symbol == 3)
         var info = sprintf("%-8.8s %4.0fft", x.name, x.elevation*M2FT);
    
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/info", info);
    
    if (x.type == "ILS" or x.type == "VOR" or x.type == "NDB")
        setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", x.frequency);
    else
        setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", 0);
    
    return x.id;
  },

  delsym: func (i) {
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/sym", -1);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-norm", 99);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/distance-nm", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-bearing", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/rel-course", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/bearing-deg", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/ils-course", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/frequency", 0);
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/id", "");
    setprop(mfdroot ~ "navd/sym[" ~ i ~ "]/info", "");
  },

  update: func() {

    me.navlist = [];
    me.usedids = std.Vector.new();
    me.navdfilter = getprop(datafltr);
    me.rr = (getprop(rngprop) or 1) * (getprop(scaleprop) or 1);
    me.maxrng = (getprop(rngprop) or 5) * 1.4;

    if (me.navdfilter==2) {
      
        # add flightplan waypoints on top of list
        var fplan = flightplan();
        var fplans = fplan.getPlanSize();
        # for mode 1 show only 4 next wypts
        
        var first = max(0, fplan.current - 1);
        var n = (me.navdfilter!=1) ? fplans : min(5 + first, fplans);
        
        for (var i=first; i<n; i+=1) {
            var thiswp = fplan.getWP(i);
            me.addto([thiswp],(i == fplan.current) ? 4 : 1);
            me.usedids.append(thiswp.id);
            }
        }
        
    if (me.navdfilter==3) {
        var x=findNavaidsWithinRange(me.maxrng, "airport");
        me.addto(x,3);
        }
        
    if (me.navdfilter==1) {
        var x=findNavaidsWithinRange(me.maxrng, "vor");
        me.addto(x,0);
        }
        
    if (me.navdfilter==1) {
        var x=findNavaidsWithinRange(me.maxrng, "ndb");
        me.addto(x,2);
        }
        
    if (me.navdfilter==4) {
        var x=findNavaidsWithinRange(me.maxrng, "ils");
        me.addto(x,5);
        }
        
    if (me.navdfilter==2) {
        var x=findNavaidsWithinRange(me.maxrng, "fix");
        me.addto(x,6);
        }
        
    # sort all the symbols by distance from aircraft
    # except in flightplan views
    
    if (me.navdfilter!=2) 
        me.navlist = sortNavaidByDistance(me.navlist);
    
    l = min(me.maxn, size(me.navlist));
    
    # then transfer up to maxn to the plan view properties
    for (var j=0; j < l; j+=1) me.addsym(j, me.navlist[j] );
        
    # deactivate unused symbols
    if (j <= me.maxn) for (var i = j; i < me.maxn; i+=1) me.delsym(i);
  
  },
   
  addto: func(x, symbol) {
          var myhdg = getprop("/orientation/heading-deg");
          
          foreach(var sym; x) {
           if (!me.usedids.contains(sym.id)) {
                
              var y = ghostcopy(sym);
              
              #do not add fixes with numbers, they seem to have
              #a (strange?) special meaning
              
              if (!(num(right(y.id,1))!=nil and y.type=="fix")) {             
                var (c, d) = courseAndDistance(
                        {lat: sym.lat, 
                        lon: sym.lon} );
                        
                y.distance_nm = d;
                y.bearing_deg = c;
                y.symbol = symbol;
                y.relbearing  = c - myhdg;
                y.relcourse  = y.course - myhdg;
                y.reldst = d / me.rr;
                
                append(me.navlist, y);
              }
           }
          }
   }

};

var nav = navdisplay.new();

# === UPDATERS ===
# run updaters with delay for an even distrubution of load

setlistener("sim/signals/fdm-initialized", func {
  nav.run(0.2, delay=0.12);
}  );
