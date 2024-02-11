# common constants and functions for the Helionix MFD framework

var DEBUG = 0;                     # very (!) verbose debug info on console
var FAST= 0;                       # timer interval for fast updated instruments, such a compass, speed, needles
var SLOW = 1/2;                    # timer interval for slow indications such as Nav Frequencies or IDs as text 
var ENABLE_THREADS = 0;            # unused, not implemented anymore in mfd.nas
var USE_CENTRAL_UPDATE_LOOP = 0;   # collects all sensors' timers into one central timer loop

# those need to be in the global scope

var debugloop = 0;
var page_setup={};
var mfdctrl = [1,1,1,1];
var mfdroot = "/instrumentation/efis/";
var mfd = [];

var updaters = []; #this is a list containing all objects that need periodic update


# some constants needed for the XML code
props.globals.initNode("/constants/true",1,"BOOL");
props.globals.initNode("/constants/false",0,"BOOL");
props.globals.initNode("/constants/zero",0,"DOUBLE");

# init some configuration parameters for the MFDs
var rngprop = mfdroot ~ "navd/range";
var scaleprop = mfdroot ~ "navd/scale";
var numprop = mfdroot ~ "vmd/nums";
var datapageprop = mfdroot ~ "vmd/datapage";
var mapprop = mfdroot ~ "dmap/terrainmode";
var planprop = mfdroot ~ "dmap/planmode";
var dataprop = mfdroot ~ "dmap/db-mode";
var databpage = mfdroot ~ "dmap/db-page";
var datafltr  = mfdroot ~ "dmap/db-filter";

setprop(rngprop, 20);
setprop(mapprop, 0); 
setprop(planprop, 1); 
setprop(dataprop, 1); 
setprop(databpage, 0); 
setprop(datafltr, 1); 
setprop(datapageprop, 0); 

# helper functions
#
#

var max = func(a, b) a > b ? a : b;
var min = func(a, b) a < b ? a : b;
var clamp = func(v, min = 0, max = 1) v < min ? min : v > max ? max : v;
var rem = func(val, div) { return val-int(val/div)*div;}

# air data computer and its methods, the actual sensors of the ADC are defined in airdata.nas
#
#

var adc = {
  update_items: [],
  sensor_idx: 0,
  
  add : func (params) {
    params.name = "idx_"~me.sensor_idx;    
    me[params.name] = Sensor.new(params);
    me.sensor_idx += 1;
    return me[params.name];
  },  
    
  _recurse_ : func (i, f) {
    # recurse deep into all sensors in airdatacomputer
    # and apply a function f to all sensor objects
    
    var k = keys(i);    
    foreach (var x; k) { 
      if (contains(i[x], "is_a_sensor")) { 
        f( i[x] );
      } else {
        if (typeof(i[x]) == "hash") me._recurse_(i[x], f);
      }  
    }
  },
    
  _benchmark_ : func () {
    me._recurse_(me, func (x) { benchmark_output(x, debugloop) } );   
    print("- - - - - -");  
  },

  _del_ : func () {
    if (DEBUG) print("adc ... del");
    me._recurse_(me, func (x) { x._del_() } );   
  },

  _refresh_ : func () {
    if (DEBUG) print("adc ... refresh");
    me._recurse_(me, func (x) { x.compile() } ); 
    me._recurse_(me, func (x) { x.refresh() } ); 
  },

  initUpdates : func (dt) {
    # collect all sensors, that have no listeners in update_items
    me._recurse_(me, func (x) {
            if (x.li == nil) {
              append( me.update_items, x);
            }
        }
    );
    me._timer_ = maketimer(dt, func {
        foreach (var update_item; me.update_items) {
             update_item.update();
        }
      }
    );
    me._timer_.start();    
  }
};

var mfd_add = func(s1, s2) {
  
  var i = size(mfd);
  append(mfd, Canvas_mfd.new(i, s1, s2) );
  return i;
};

var colored = func(a) { 
     # color code the terminal output
     if (a>20)
        return "\x1b[7;49;91m" ~ a ~ "\x1b[0m"
     elsif (a>5)
        return "\x1b[7;49;92m" ~ a ~ "\x1b[0m"
     elsif (a>0)
        return "\x1b[7;49;39m" ~ a ~ "\x1b[0m"
     else 
        return a
};

var benchmark_output = func(a,k) {
     if (a.calls>0) print(a.name, ":", colored(int(a.calls/k)), "/", int(a.freq/k) );
};


# find an element in a list
#
#

var isin = func (needle, haystack) {
  var i=0;
  foreach (x; haystack) {
    if (x==needle) return i;
    i += 1;
    }
  return -1;
}

var pad2strings = func(a, b, l) {
    var d = l-size(a)-size(b);
    if (d>0) {
        var spc = left("                    ",d);
        return (a ~ spc ~ b);
    } else {
        return substr(a, d) ~ " " ~ b;
    }
}
    
var toggleprop = func (prop) setprop(prop, getprop(prop) == nil ? 0 : !getprop(prop) );

var incrprop = func (prop) setprop(prop, getprop(prop) == nil ? 0 : getprop(prop)+1 );

var decrprop = func (prop) setprop(prop, getprop(prop) == nil ? 0 : max(0, getprop(prop)-1) );

var cycleprop = func (prop, opts) {
    k = getprop(prop);
    if (k==nil) {
      setprop(prop, opts[0]);
      return;
      }
      
    i = isin(k, opts);
    if (i<0) {
      setprop(prop, opts[0]);
      return;
      }
      
    # cycle to next element in list
    i = rem(i+1, size(opts));
    setprop(prop, opts[i]);
}


# simple timer class with methods to inherit from
# for periodic execution and a start delay
#

var Timerloop = {

    new: func {
        return { parents: [Timerloop] };
    },
    
    run: func (period, delay=0) { 
           me.period=period;
           settimer( func me._loop() , delay);
    },

    _loop: func { 
           # update method must be provided by the derived class
           me.update();
           settimer( func me._loop(), me.period);
    },

};

var font_mapper = func(family, weight)
{
        if( weight == "normal" ) {
           return "Helionix.ttf"
        } else {         
           return "LiberationFonts/LiberationSansNarrow-Bold.ttf";
        }
};

var ghostcopy = func (gin) {
  out = {};
  out.id = gin.id;
  
  if (ghosttype(gin) != "flightplan-leg") {
      out.type = gin.type;
      out.name = gin.name;
      out.elevation = gin.elevation or 0;
      out.frequency = gin.frequency or 0;
      out.course = gin.course or 0;
  } else {
      out.type = "waypoint";
      out.name = "";
      out.elevation = 0;
      out.frequency = 0;
      out.course = 0;
  }    
  return out;
}

var sortNavaidByDistance = func (listofnav) {
   #return the sorted list
   return sort(listofnav, 
         func (a,b) {return a.distance_nm > b.distance_nm ? 1 : -1}
         );
}

# linear interpolator class
# by litzi
# adopted from Zivko Edge
# original author Torsten Dreyer

var LUT = {
  new: func(pairs, nn=100)
  {
    var m = { parents: [ LUT ] };
    m.pairs = pairs;
    m.pairs2 = [];
    m.d = [];
    m.n = size(pairs)-1;
    
    m.resample(nn);
    
    return m;
  },
  resample: func (nn) {
    # resample pairs with equal spacing for
    # improved speed    
    me.res = (me.pairs[-1][0]-me.pairs[0][0])/(nn-1);
    
    for (var x=me.pairs[0][0]; x<me.pairs[-1][0]; x+=me.res) 
       append(me.pairs2, [x, me._get(x)]);
    
    me.nn = size(me.pairs2)-1;
    
    for (var i=0; i<me.nn; i+=1)
       append(me.d, (me.pairs2[i+1][1]-me.pairs2[i][1])/me.res);
  },
  _get: func(x)
  {
    if( x <= me.pairs[0][0] ) {
     return me.pairs[0][1];
    }
    if( x >= me.pairs[me.n][0] ) {
      return me.pairs[me.n][1];
    }
    for( var i = 0; i < me.n; i+=1 ) {
      if( x > me.pairs[i][0] and x <= me.pairs[i+1][0] ) {
        var x1 = me.pairs[i][0];
        var x2 = me.pairs[i+1][0];
        var y1 = me.pairs[i][1];
        var y2 = me.pairs[i+1][1];
        return (x-x1)/(x2-x1)*(y2-y1)+y1;
      }
    }
    return me.pairs[i][1];
  },
  get: func (x)
  {
    x = math.clamp(x,me.pairs2[0][0],me.pairs2[-1][0]);
    var i = math.clamp( int( (x-me.pairs2[0][0]) / me.res), 0, me.nn-1);
    return me.pairs2[i][1]+(x-me.pairs2[i][0])*me.d[i];
  },
  del: func() {}  
};


var checkrules = func (p) {
    if (p.prop != nil)
        return 1;        
    if (p.sensor != nil)
      if (p.sensor.prop != nil)
        return 1;                      
    return 0;
};

var change_all_ids = func (node, post) {
    if(node == nil) 
        return;
    
    var children = node.getChildren();
    
    foreach(var c; children) {
        var name = c.getName();
        if (name=="group" or name=="text" or name=="path") {
            # recurse deeper
            change_all_ids(c, post);
          
        } elsif (name == "id") {
          
            var val = c.getValue();
            c.setValue(val~post);
        }
     }
};

var splitpath = func (p, a, b) {
  var out = "";
  foreach (var x; split("/", p)[a:b])
    out = out~x~"/";       
  return out;
};

var compile_filter_function = func (f) {
    # construct a string to compile a filter function from  
        
    # use sensor value as a argument to a function
    if (f.funcof)
        var functionbody = "var x = " ~ f.funcof ~ "(arg[0]);";
    else 
        var functionbody = "var x = arg[0];";
    
    if (f.mod)
        functionbody ~= "x = math.mod(x," ~ f.mod ~ ");";
    
    if (f.max != 1e20 or f.min != -1e20)
        functionbody ~= "x = math.clamp(x," ~ f.min ~ "," ~ f.max ~ ");";        
    
    if (f.scale != 1 or f.offset != 0)
        functionbody ~= "x = x * " ~ f.scale ~ " + " ~ f.offset ~";";
    
    if (f.trunc) 
        functionbody ~= "x = int(x);";
        
    if (f.abs) 
        functionbody ~= "x = abs(x);";

    # check if we need a string output
    if (f.format == nil) {
        functionbody ~= "";
    } else {
        functionbody ~= "x= sprintf(\"" ~ f.format ~"\", x);";
    }
    if (DEBUG) 
    print(functionbody);
    
    return functionbody;
};
    
io.include(HELIONIXPATH ~ "Nasal/sensor.nas");
io.include(HELIONIXPATH ~ "Nasal/mfd.nas");

# start the air data computer sensor loops
io.include(HELIONIXPATH ~ "Nasal/airdata.nas");
