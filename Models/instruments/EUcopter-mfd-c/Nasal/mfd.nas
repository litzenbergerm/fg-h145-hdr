# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# This is a generic approach to canvas MFD's

# the property rule counter must be global
var proprulecounter = 0;

var Canvas_mfd = {
	new: func(id, sizepx, viewpx) 
	{
          var m = { parents: [Canvas_mfd] };
          
          m.display = canvas.new({
                    "name": "MFD"~id,
                    "size": sizepx,
                    "view": viewpx, 
                    "mipmapping": 1
          });
          
          m.id = id;
          return m;
    },
        
    add_page: func(_id, svg_filename) {
        me[_id] = Page.new(me.display, svg_filename);
        me[_id].pagename = _id;
        me[_id].mfd_id = me.id;
        me[_id].objectcontext = "helionix.mfd[" ~ me.id ~ "][\"" ~_id~ "\"]";
        me[_id].ifactive = "if (" ~ me[_id].objectcontext ~ ".active) ";
        
        # return a reference to the new page object
        return me[_id];
    }

};                  
	
var Page = {
        new: func(display, svg_filename) 
        {
                var m = { parents: [Page] };

                # keep a reference to main parent mfd object
                m.mfd = display;
                
                # create the new page in canvas as a new group
                m.page = display.createGroup();
                
                canvas.parsesvg(m.page, svg_filename, {'font-mapper': font_mapper});
                      
                m.ncopy = 0;
                m.active = 1;
                m.mystack = [];
                
                return m;        
	},
        
        hide: func()
        {          
          if (me.active) {
            me.page.set("visible", 0);
            me.active = 0;
          }
        },
        
        show: func()
        {
          if (!me.active) {
            if (DEBUG) print("page ... refresh");
            me.page.set("visible", 1);
            me.active = 1;
            
            # force refresh for all sensors
            adc._refresh_();            
          }
        },
          
        add_by_id: func(id) {
                if (!contains(me, id)) {                
                      me[id] = me.page.getElementById(id);

                      if (me[id] == nil) { 
                            print("WARNING: Non existing SVG ID ",id," !");
                            return nil;
                      }

                      # create a new unity tranform to use it for triggering the prop rule canvas update
                      me[id].nodepath = me[id]._node.getPath() ~ "/tf[1]/m";
                      me[id].nodepathval = getprop(me[id].nodepath);
                      me[id].objectcontext = me.objectcontext ~ "[\"" ~ id ~ "\"]";
                      
                      if (DEBUG) print("add: ",id, " -> ", me[id]._node.getPath());
                      
                      # search for a clipping element for this id (taken from F16 HUD code)
                      var theclip = me.page.getElementById(id~"_clip");
                      
                      if (theclip != nil) {
                         me.setClipByElement(id, theclip);
                         theclip.setVisible(0); #hide the clipping mask element
                      }
                      
                      return 1;
      
                }
                return 1;
        },
                      
        setClipByElement: func (id, cl) {
                cl.update();
                var bb = cl.getTightBoundingBox();                
                var clstr = sprintf("rect(%d,%d,%d,%d)", bb[1], bb[2], bb[3], bb[0]);
                me[id].set("clip", clstr);
                
                #setting clip-frame results in strange offset of clipped region! 
                #me[id].set("clip-frame", canvas.Element.PARENT);
                
                if (DEBUG) print("clipping: ",id," -> ", clstr);
        },
          
        add_direct: func(id, s, fu) {
                # for tranforms translation, rotation
                # svg element id is bound to sensor s. 
                # fu is the fuction that implements the
                # actual transformation. the function must
                # accept arguments f(o,c) with o the object 
                # and c the center of rotation (a two element vector)
                
                me.add_by_id(id);
                
                var c1 = me[id].getCenter();                
                var thisobj = me[id].createTransform();
                
                s._register_( {o: thisobj, c: c1, f: fu}, me );
                
        },
        
        add_directS: func(id, s, fu) {
                # for tranforms scale
                # svg element id is bound to sensor s. 
                # fu is the fuction that implements the
                # actual transformation. the function must
                # accept arguments f(o,c) with o the object 
                # and c the center (a two element vector)
                
                me.add_by_id(id);
                
                var c1 = me[id].getCenter();                
                me[id].createTransform().setTranslation(-c1[0],-c1[1]);
                var thisobj = me[id].createTransform();
                me[id].createTransform().setTranslation(c1[0],c1[1]);
                
                s._register_( {o: thisobj, c: c1, f: fu}, me );
                
        },

        add_directTV: func(id, s, fu, v=nil) {
                # for setText and setVisible
                # svg element id is bound to sensor s. 
                # fu is the fuction that implements the
                # actual method for the object. the function must
                # accept arguments f(o,c) with o the object 
                # and a second argument)
                
                me.add_by_id(id);
                s._register_( {o: me[id], c: v, f: fu}, me );
                
        },
        
        add_trans: func(id, type, params, disable_rules=0) {
                me.add_trans_grp([id,], type, params, disable_rules=0);
        },

        add_trans_grp: func(ids, type, params, disable_rules=0) { 
          
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.sensor==nil);
                
                if (is_const) {
                  foreach (var e; ids) {                   
                    me.add_by_id(e);
                    var c = me[e].getCenter();         
                    var x = me[e].createTransform();
                    # set the contant transformations for the elements  
                    if (DEBUG) 
                       print(e, " transf. is a constant");
                    if (type == "x-shift") 
                        me[e].createTransform().setTranslation(p.offset, 0);
                    elsif (type == "y-shift") 
                        me[e].createTransform().setTranslation(0, p.offset);
                    elsif (type == "rotation")
                        me[e].setRotation(p.offset*D2R,c[0],c[1]);
                    elsif (type == "x-scale") {
                        me[e].setTranslation(-c[0],-c[1]);
                        me[e].createTransform().setScale([p.offset, 1]);
                        me[e].createTransform().setTranslation(c[0],c[1]);
                    } elsif (type == "y-scale") {
                        me[e].setTranslation(-c[0],-c[1]);
                        me[e].createTransform().setScale([1, p.offset]);                  
                        me[e].createTransform().setTranslation(c[0],c[1]);
                    }
                   } 
                   return;
                
                } elsif (p.sensor == nil) {
                    print("canvas mfd: use of function DEPRECATED use a sensor instead. ");
                    debug.dump(ids);                    
                    return;
                  
                } else {
                    # if a sensor is already referenced, use this
                    s = p.sensor;
                }
              
                foreach (var e; ids) {
                    # avoid stack overflows, del self reference to sensor
                    p.sensor = nil;
                    me.add_by_id(e);
                                        
                    var myfilter = compile_filter_function(p);                   
                    var c = me[e].getCenter();         
                    
                    # compose of callback for sensor to the transform element                    
                    if (type == "x-shift") {        
                        s._register_code( me.ifactive, myfilter ~ me.newstack(e) ~ ".setTranslation(x, 0);" );
                        
                    } elsif (type == "y-shift") {
                        s._register_code( me.ifactive, myfilter ~ me.newstack(e) ~ ".setTranslation(0, x);" );
                        
                    } elsif (type == "rotation") {
                        s._register_code( me.ifactive, myfilter ~ me.newstack(e) ~".setRotation(x*D2R," ~c[0]~ "," ~c[1]~ ");" );
                        
                    } elsif (type == "x-scale") {
                        me[e].createTransform().setTranslation(-c[0],-c[1]);
                        s._register_code( me.ifactive, myfilter ~ me.newstack(e) ~ ".setScale( [x,1] );" );                    
                        me[e].createTransform().setTranslation(c[0],c[1]);
                        
                    } elsif (type == "y-scale") {
                        me[e].createTransform().setTranslation(-c[0],-c[1]);
                        s._register_code( me.ifactive, myfilter ~ me.newstack(e) ~ ".setScale( [1,x] );" );
                        me[e].createTransform().setTranslation(c[0],c[1]);
                        
                    }
                }
                
        },
        
        newstack: func(e) {
                # make new transform on stack and return reference
                append(me.mystack, me[e].createTransform());
                return me.objectcontext ~ ".mystack[" ~ (size(me.mystack)-1) ~ "]"
        },
        
        add_text: func(id, params) {
                me.add_text_grp([id,],params);
        },
        
        add_text_grp: func(ids, params) {
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.sensor==nil);
                
                if (is_const) {  
                 foreach (var i; ids) {
                     me.add_by_id(i);                   
                     me[i].setText(""~p.offset);
                 }
                 return;
                }
                    
                if (p.sensor == nil) {
                    print("canvas mfd: use of function DEPRECATED use a sensor instead.");
                    debug.dump(ids);                    
                    return;                  
                } else {
                    # if a sensor is already referenced, use this
                    var s = p.sensor;
                }
                
                foreach (var i; ids) {
                    me.add_by_id(i);
                    me[i].enableFast();
                                        
                    # register callback method for text update to the sensor s
                    #if (p.format == nil) {
                        # non-numeric value
                        #s._register_code( me.ifactive, me[i].objectcontext ~ ".setTextFast(arg[0]);" );
                    #} else {
                        var myfilter = compile_filter_function(p);
                        s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setTextFast(x);" );
                    #}
                }
        },                
        
        add_color_range: func(i, s, params, fill=0) {
          
            me.add_by_id(i);                   
            # color range is only possible via fixed slow timer
            # to avoid performace issues from callbacls
            
            if (!contains(me,"color_timer_data")) 
                 me.color_timer_data = {};
                 
            me.color_timer_data[i] = [s, params, fill];
                 
            if (!contains(me,"color_timer")) {
                  me.colortimer = maketimer(1/2, func {
                    foreach(var p; keys(me.color_timer_data) ) {
                        var sens = me.color_timer_data[p][0];
                        var c = me.color_timer_data[p][1];
                        var f = me.color_timer_data[p][2];
                        var v = sens.val or 0;
                        
                        if (v <= c[0][0]) 
                          if (f) me[p].setColorFill(c[0][1]); else me[p].setColor(c[0][1]);
                          
                        elsif (v >= c[2][0]) 
                          if (f) me[p].setColorFill(c[2][1]); else me[p].setColor(c[2][1]);   
                          
                        else 
                          if (f) me[p].setColorFill(c[1][1]); else me[p].setColor(c[1][1]);    
                    }
                }); 
                me.colortimer.start();
          }
        },
        
        add_cond: func(id, params) {
                me.add_cond_grp([id,], params);
        },       
        
        add_cond_grp: func(ids, params) {
                var elements = [];
                var p = {};
                me.init_params(p, params);
                
                var is_const = (p.sensor==nil);
                
                if (is_const) { 
                  foreach (var i; ids) {
                     me.add_by_id(i);
                     me[i].setVisible(p.offset);
                  }
                  return;
                }
                  
                if (p.sensor == nil) {
                    print("canvas mfd: use of function DEPRECATED use a sensor instead.");
                    debug.dump(ids);                    
                    return;                  
                } else {
                    # if a sensor is already referenced, use this
                    #p["type"] = "BOOL";
                    var s=p.sensor;
                }
                
                foreach (var i ; ids) {
                    me.add_by_id(i);
                    # register callback code to the element at the sensor s                    
                    var myfilter = compile_filter_function(p);                   

                    if (p.notequal != nil) {
                        #for string use no filter
                        #if (num(p.notequal) == nil) 
                            #s._register_code( me.ifactive, me[i].objectcontext ~ ".setVisible(arg[0] !=\"" ~ p.notequal ~  "\");" );
                        #else    
                            s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x !=\"" ~ p.notequal ~  "\");" );
                    } elsif (p.lessthan != nil) { 
                        s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x <" ~ p.lessthan ~  ");" );
                    } elsif (p.greaterthan != nil) {
                        s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x >" ~ p.greaterthan ~  ");" );
                    } elsif (p.between != nil) {
                        s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x >" ~ p.between[0] ~ " and x<" ~ p.between[1] ~");" );
                    } elsif (p.notin != nil) {
                        s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x <" ~ p.notin[0] ~ " or x>" ~ p.notin[1] ~");" );
                    } else {
                        #for string use no filter
                        #if (num(p.equals) == nil) 
                           #s._register_code( me.ifactive, me[i].objectcontext ~ ".setVisible(x ==\"" ~ p.equals ~  "\");" );
                        #else
                           s._register_code( me.ifactive, myfilter ~ me[i].objectcontext ~ ".setVisible(x ==\"" ~ p.equals ~  "\");" );
                    }    
                }
        },
        
        init_params: func(x, params) {
        
              # note: optional named arguments did not work, therefore a hash is used
              # init some transformation default parameters
              foreach (var a; keys(params)) {
                if (-1 == isin(a, ["sensor", "equals", "lessthan", "greaterthan", "notequal", "between", "name", "scale", 
                       "offset", "mod", "trunc", "max", "min", "format", "trunc", "abs", "notin", "funcof"])) {
                       #debug.dump(caller(0));
                       die("unknown parameter '"~a~"' in "~caller(0)[2]);
                }
              }
              
              # for the sensor:
              #x["function"] = contains(params, "function") ? params.function : nil;
              #x["prop"] = contains(params, "prop") ? params.prop : nil;
              x["sensor"] = contains(params, "sensor") ? params.sensor: nil;
              x["equals"] = contains(params, "equals") ? params.equals: 1;
              x["lessthan"] = contains(params, "lessthan") ? params.lessthan: nil;
              x["greaterthan"] = contains(params, "greaterthan") ? params.greaterthan: nil;
              x["notequal"] = contains(params, "notequal") ? params.notequal: nil;
              x["between"] = contains(params, "between") ? params.between: nil;
              x["notin"] = contains(params, "notin") ? params.notin: nil;
              
              x["name"] = contains(params, "name") ? params.name: nil;
              x["timer"] = contains(params, "timer") ? params.timer: 0;
              
              # for the filter:
              x["scale"] = contains(params, "scale") ? params.scale : 1.0;
              x["offset"] = contains(params, "offset") ? params.offset : 0.0;
              x["mod"] = contains(params, "mod") ? params.mod : nil;
              x["max"] = contains(params, "max") ? params.max : 1e20;
              x["min"] = contains(params, "min") ? params.min : -1e20;
              x["format"] = contains(params, "format") ? params.format: nil;
              x["trunc"] = contains(params, "trunc") ? ((params.trunc == "int") ? 1 : 0) : 0;
              x["abs"] = contains(params, "trunc") ? ((params.trunc == "abs") ? 1 : 0) : 0;
              x["funcof"] = contains(params, "funcof") ? params.funcof : nil;
              
        },
        
        copy_element: func(svgid, post, dx=nil) {
              var newid = svgid~post;
              
              if (contains(me, newid)) {
                  die("canvas_MFD.copy_element: newid already exists");
              }
                
              dx = (dx==nil) ? [0,0] : dx;
              
              if (!contains(me, svgid)) {
                  me.add_by_id(svgid);
              }
              
              var basenode = me[svgid]._node.getPath();
              var srcnode = props.globals.getNode(basenode);
              var xnode = substr(basenode, 0, find("group", basenode));
              
              var dest = splitpath(basenode,0,-2) ~ "group[99]/group["~ me.ncopy ~"]";
              var destnode = props.globals.initNode(dest);
              
              # copy the element
              props.copy(srcnode, destnode, 1);
              # set the new ids
              change_all_ids(destnode, post);
              #setprop(dest~"/id", newid);
              
              if (!contains(me, newid)) {
                  me.add_by_id(newid);
              }

              me[newid].setTranslation(dx);
              me.ncopy += 1;
        },

        link2rule: func(svgid, propIn, x) {
          
              # === EXPERIMENTAL ! ===
              
              # make calculation of transform in a property rule
              # to reduce Nasal overhead
              # the output is aliased to the correct tranformation
              # matrix.
              #
              # however, the aliased property does not trigger an automatic
              # update of the canvas. Therefore an update by a timer is needed
              # which makes the pos. effect on performance relatively minor
              
             
              if (proprulecounter > 199)
                die("canvas mfd: max. number of property rules (200) exceeded");
                
              if (!contains(me, svgid))
                  me.add_by_id(svgid);
                  
              if (!contains(me[svgid],"xmfdtimer")) {
                  # add a timer to periodically trigger the transform. only ONE timer per svg element is needed
                  me[svgid].xmfdtimer = maketimer(1/30, func setprop(me[svgid].nodepath, me[svgid].nodepathval)); 
                  me[svgid].xmfdtimer.start();
              }
              
              var proproot = "canvas/rules/rule[" ~ proprulecounter ~ "]/";              
              #print (svgid," ", me[trans.id].a.getPath());
                            
              props.globals.getNode(proproot~"active", 1).setBoolValue(1);
              props.globals.getNode(proproot~"r-active", 1).setBoolValue(0);
              
              setprop(proproot~"name", svgid);             
              setprop(proproot~"offset", (x.scale==0) ? -x.offset : -x.offset/x.scale);
              setprop(proproot~"scale", x.scale);
              setprop(proproot~"min", x.min);
              setprop(proproot~"max", x.max);
              setprop(proproot~"periodmin", (x.mod==nil) ? -10000000000000000000 : 0);
              setprop(proproot~"periodmax", (x.mod==nil) ? 10000000000000000000 : x.mod);
              setprop(proproot~"abs", x.abs);
              
              var nodeIn = nil;
              var propOut = proproot~"out";
              
              # alias the input node:           
              nodeIn = props.globals.getNode(proproot~"in");
              
              if (nodeIn==nil)
                die("canvas mfd: Cannot alias transform to property rule. Is the property rule file loaded?")
              else  
                nodeIn.alias(propIn);
              
              # alias the correct output node/transform matrix element:
              #tfm : {x-scale:"a", y-scale:"d", x-shift:"e",y-shift:"f"},
              
              var T = me[svgid].createTransform();
              
              if  (x.type == "x-shift")
                  #x-shift
                  T.e.alias(propOut);
              elsif (x.type == "y-shift")
                  #y-shift
                  T.f.alias(propOut);
              elsif (x.type == "x-scale") 
                  #x-scale
                  T.a.alias(propOut);
              elsif (x.type == "y-scale") 
                  #y-scale
                  T.d.alias(propOut);
              elsif (x.type == "rotation") {
                  # setup the rotation matrix                  
                  T.a.alias(proproot~"cos");
                  T.b.alias(proproot~"sin");
                  T.c.alias(proproot~"m-sin");
                  T.d.alias(proproot~"cos");
                  props.globals.getNode(proproot~"r-active", 1).setBoolValue(1);
              }

              proprulecounter += 1;
              return 1;
        },
         
        del: func () {
             foreach(var x; me.sensors)
                x._del_();
                
             print("mfd ... del");
        }
        
};
