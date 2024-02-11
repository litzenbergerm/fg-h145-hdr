# Sensor class to avoid repeated readout of properties.
#
# Each sensor object holds a list callbacks to other objects (usually filters or canvas elements) that
# it calls to update in case of sensor value change
# (original concept seen in Thorstens Zivko Edge)

# set a default value for timer loop updates,
# if none is defined, set to max.
if (!defined("FAST"))
   var FAST = 0;

if (!defined("USE_CENTRAL_UPDATE_LOOP")) 
   var USE_CENTRAL_UPDATE_LOOP = 0;
   
var TIMERDELAY = 0;

var Sensor = {
    new: func(param) {
            var m = { parents: [Sensor] };
            
            # just to see from outside if this object is a sensor
            m.is_a_sensor = nil;
            m.val = 0;
            m.callbacks = [];
            m.mainfunction = func (x) { };
            m.mainfunctioncode  = { };
            
            m.timer = nil;
            m.li = nil;
            m.th = nil;
            m.calls = 0; #actual executions of callback func
            m.freq = 0; #frequency of property checks
            
            foreach (var a; keys(param)) {
              if (-1 == isin(a, ["prop", "function", "thres", "type", "timer", "name" ])) {
                      #debug.dump(caller(0));
                      die("unknown parameter '"~a~"' in "~caller(0)[2]);
              }
            }
                      
            m.function = contains(param, "function") ? param.function : nil;
            m.thres = contains(param, "thres") ? param.thres : 0;            
            # set listener, if timer parameter is not given
            m.disable = contains(param, "timer") ? param.timer : -1;            
            m.istext = contains(param, "type") ? (param.type == "STRING") : 0;
            m.isbool = contains(param, "type") ? (param.type == "BOOL") : 0;
            m.isnum = contains(param, "type") ? (param.type == "FLOAT") : 1;
            m.type = (m.isnum) ? "DOUBLE" : ( (m.isbool) ? "BOOL" : "STRING");            
            
            if (contains(param, "prop")) {
               m.prop = (param.prop) ? props.globals.initNode(param.prop, 0, m.type) : nil;
               m.path = param.prop;
            } else {
               m.prop = nil;
               m.path = "";
            }
            
            # names are currently not in use, may be handy for later developments
            m.name = contains(param, "name") ? param.name : nil;
            
            if (m.name == nil) {
              if (contains(param, "prop"))
                if (param.prop) 
                    m.name = string.join("/", split("/", param.prop)[-2:-1] );
                else
                    m.name = "unnamed func";
              else
                m.name = "unnamed func";
            }
            
            if (m.function==nil and m.prop==nil)            
               die("Sensor.new(): must give either 'function' or 'prop' argument!");
            
            if (m.disable != -1 or m.function != nil) {
               if (!USE_CENTRAL_UPDATE_LOOP) {
                  m.disable = (m.disable == -1) ? 0 : m.disable;
              
                  if (m.function == nil) {
                      if (m.isnum)
                          m.timer = maketimer(m.disable, func m._check_num( m.prop.getValue() ));
                      else 
                          m.timer = maketimer(m.disable, func m._check_text( m.prop.getValue() ));
                  } else {
                      if (m.isnum)
                        m.timer = maketimer(m.disable, func m._check_num( m.function() ));
                      else
                        m.timer = maketimer(m.disable, func m._check_text( m.function() ));  
                  }
                  # delay the start of the timer so that timers are more evenly distributed over time
                  settimer(func m.timer.start();, TIMERDELAY);
                  TIMERDELAY += 0.02;
               }                     
            } else if (m.prop != nil) {
                  # use of listener needs no further check on property change
                  if (m.isnum)
                      m.li = setlistener(m.prop, func (u) m._check_num( u.getValue() ), startup=1, runtime=0);
                  else
                      m.li = setlistener(m.prop, func (u) m._check_text( u.getValue() ), startup=1, runtime=0);
            } 
                
            m.refresh();
            return m;
    },
            
    # check callback methods are kept as simple as possible to improve performance
    _check_num: func (x) {
              me.freq += 1;              
              if (math.abs(me.val-x) > me.thres) {              
                 me.val = x;
                 me.calls +=1;
                 me.mainfunction(x);
                 
                 foreach (var c; me.callbacks) {
                    if (c.a.active) { 
                        c.f(c.o, c.c);
                    }
                 }
              }
    },
                    
    _check_text: func (x) {
              # this method checks boolean and string data for changes
              me.freq += 1;
              if (me.val != x) {
                  me.val = x;
                  me.calls +=1;
                  me.mainfunction(x);
                      
                  foreach (var c; me.callbacks) {
                    if (c.a.active) { 
                        c.f(c.o, c.c);
                    }
                }
              }
    },
                    
    _check: func (x) {
              # force a refresh of all callback items,
              # should not be called too often
              
              me.val = x;
              me.freq += 1;
              me.calls +=1;
              me.mainfunction(x);
              
              foreach (var c; me.callbacks) {
                  c.f(c.o, c.c);
              }

    },            
                
    refresh: func () {
      if (me.function == nil) {
        me.val = me.prop.getValue();
      } else {
        me.val = me.function();
      }
      if (me.val == nil) {
        me.val = (me.istext) ? "" : 0;
      }
      me._check(me.val);
      
    },
    
    compile: func () {
    
      var lines=keys(me.mainfunctioncode);
      
      if (size(lines)>0) {
         var tempcode = "";
         
         #compose the code lines
         foreach (var condi; lines)
             tempcode ~= condi ~ " {" ~ me.mainfunctioncode[condi] ~ " }";
         
         #print(me.name,":  ",tempcode);
         #compile the mainfunction
         me.mainfunction = compile(tempcode);
      }
    },
    
    update: func () {
      var x = (me.function==nil) ? me.prop.getValue() : me.function();
      if (x == nil) 
        return;
      if (me.isnum)
        me._check_num(x);
      else  
        me._check_text(x);
    },
      
    _register_: func (p, o=nil) {
      p.a = o;
      append(me.callbacks, p);
      
      #call once to init object
      p.f(p.o,p.c);
    },
             
    _register_code: func (condi, c) {
      if (DEBUG) print(c);
      #append the new code parts to mainfunction
      
      if (contains(me.mainfunctioncode, condi) )
         me.mainfunctioncode[condi] ~= c;
      else
         me.mainfunctioncode[condi] = c;
      
      #call once to init object
      compile(c)(me.val);
    },
    
    get: func () {
       return me.val;
    },
    
    _del_: func () {
       if (me.timer != nil) 
          me.timer.stop();
       else if (me.li != nil) 
          removelistener(me.li);
    }
};
