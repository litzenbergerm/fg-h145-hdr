# Sensor class to avoid repeated readout of properties.
#
# Each sensor object holds a list callbacks to other objects (usually filters or canvas elements) that
# it calls to update in case of sensor value change
# (original concept seen in Thorstens Zivko Edge)

# set a default value for timer loop updates,
# if none is defined

if (!defined("FAST"))
   var FAST = 1/20;

var Sensor = {
    new: func(param) {
            var m = { parents: [Sensor] };            
            m.prop = contains(param, "prop") ? param.prop : nil;
            m.function = contains(param, "function") ? param.function : nil;
            m.thres = contains(param, "thres") ? param.thres : 0;
            m.disable = contains(param, "disable_listener") ? param.disable_listener : 0;
            m.istext = contains(param, "type") ? (param.type == "STRING") : 0;
            m.isbool = contains(param, "type") ? (param.type == "BOOL") : 0;
            m.isnum = contains(param, "type") ? (param.type == "FLOAT") : 1;
            m.val = nil;
            m.callbacks = [];
            m.timer = nil;
            m.li = nil;
            m.th = nil;
            
            setlistener("sim/signals/fdm-initialized", func() { 
              if (m.function == nil) 
                  m._check(getprop(m.prop));
              else 
                  m._check(m.function());
            });
            
            if (m.disable>0 or m.function != nil) {
                if (ENABLE_THREADS) {
                  
                        thread.newthread( func {
                            if (m.function == nil) {
                              m.timer = maketimer(m.disable, func m._check( getprop(m.prop) ));
                            } else {
                              m.disable = (m.disable==0) ? FAST : m.disable;
                              m.timer = maketimer(m.disable, func m._check( m.function() ));
                            }
                            m.timer.start();
                        });
                } else {
                  
                        if (m.function == nil) {
                          m.timer = maketimer(m.disable, func m._check( getprop(m.prop) ));
                        } else {
                          m.disable = (m.disable==0) ? FAST : m.disable;
                          m.timer = maketimer(m.disable, func m._check( m.function() ));
                        }
                        m.timer.start();
                }
                        
            } elsif (m.prop != nil) {
                if (ENABLE_THREADS) 
                    thread.newthread( func m.li = setlistener(m.prop , func m._check( getprop(m.prop) ) ));
                else
                    m.li = setlistener(m.prop , func m._check( getprop(m.prop)));
                
            } else {
                # a constant value
                die("Sensor.new(): must give either 'function' or 'prop' argument!")
            }            
            return m;
    },
    _check: func (x) {
       if (x == nil) 
           return;
         
       if (me.val == nil) {
           me.val = (me.isbool) ? (!!x) : x;
           foreach(var cb; me.callbacks) {
             cb[2][cb[3]] = me.val;
             call(cb[1], cb[2], cb[0]);
           }
           return;
       }
       
       if (me.isnum) {
          if (abs(me.val-x) > me.thres) {              
              me.val = x;
              foreach(var cb; me.callbacks) {
                cb[2][cb[3]] = me.val;
                call(cb[1], cb[2], cb[0]);
              }
          }
       } elsif (me.istext) {
          if (cmp(""~me.val, ""~x) != 0) {
              me.val = x;
              foreach(var cb; me.callbacks) {
                cb[2][cb[3]] = me.val;
                call(cb[1], cb[2], cb[0]);
              }
          }
       } else {
          if (me.val != !!x) {
              me.val = !!x;
              foreach(var cb; me.callbacks) {
                cb[2][cb[3]] = me.val;
                call(cb[1], cb[2], cb[0]);
              }
              
          }          
       }
    },
    register: func (ob, fu, y=0 ) {
       append(me.callbacks, [ob, fu, [0,y], 0]);
    },
    register_y: func (ob, fu, x=0 ) {
       append(me.callbacks, [ob, fu, [x,0], 1]);
    },
    get: func () {
       return me.val;
    },
    del: func () {
       if (me.timer != nil) 
          me.timer.stop();
       if (me.li != nil) 
          removelistener(me.li);
    }
};