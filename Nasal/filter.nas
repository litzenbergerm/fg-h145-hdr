# Filter class to make linear transforms for element animation and callback of element animation.
# the filter object holds a list callbacks of other objects (usually svg transforms) that
# it calls to update those elements for any filter updates.

var Filter = {
    new: func(param) {
          var m = { parents: [Filter] };

          m.callbacks=[];
          m["scale"] = contains(param, "scale") ? param.scale : 1.0;
          m["offset"] = contains(param, "offset") ? param.offset : 0.0;
          m["mod"] = contains(param, "mod") ? param.mod : nil;
          m["max"] = contains(param, "max") ? param.max : 10000000000000000000;
          m["min"] = contains(param, "min") ? param.min : -10000000000000000000;
          m["format"] = contains(param, "format") ? param.format: nil;
          m["trunc"] = contains(param, "trunc") ? ((param.trunc == 1) ? 1 : 0) : 0;
          m["abs"] = contains(param, "abs") ? ((param.abs == 1) ? 1 : 0) : 0;
          m["val"] = nil;
          return m;    
    },      
    update: func (y) {
    
            if (me.mod)
                var y = math.mod(y or 0, me.mod);
            
            var p = math.clamp(y or 0, me.min, me.max);
            
            var out = p * me.scale + me.offset;
            if (me.trunc) out = int(out);
            if (me.abs) out = abs(out);
            
            # check if we need a string output
            me.val = (me.format == nil) ? out : sprintf(me.format, out);
                      
            foreach(var cb; me.callbacks) {
              cb[2][cb[3]] = me.val;
              call(cb[1], cb[2], cb[0]);
            }
    },
    register: func (ob, fu, y=0 ) {
       # this works (surprisingly) also for methods that take a single argument
       append(me.callbacks, [ob, fu, [0,y], 0]);
    },
    register_y: func (ob, fu, x=0 ) {
       append(me.callbacks, [ob, fu, [x,0], 1]);
    },
    get: func() {
       return me.val;
    },
    rescale_params: func(x) {
          me.scale *= x;
          me.offset *= x;
    }  
};
