#
# Engine Control Panel Switches code:
# by litzi
#

# called from ec145-ecp.xml model file
 
var engswitch = {
    swpos: [0, 0],
    startdelay: [0.1, 0.1],
    
    init: func {
                me.get(0);
                me.get(1);
                },
                
    vent: func(eng) {
        curr = me.get(eng);
        if (curr == 0 ) {
             # ventilate engine for 20s
             setprop("/controls/switches/ecp/vent["~eng~"]",1);
             setprop("controls/engines/engine["~eng~"]/starter", 1);
             interpolate("controls/engines/engine["~eng~"]/starter", 0, 20);
        }   
      
    },
    up: func(eng) {
        #i.e. a left mouse button press
        curr = me.get(eng);
        
        if (curr == 0 or curr == 2) {
            var delay=0.1;
            # if other engine is starting delay all steps by 11 sec
            if (curr==0 and getprop("controls/engines/engine["~!eng~"]/starter")>0) 
               me.startdelay[eng] = 11;
            me.set(eng, 1.0);
            
            if (curr==0) {
                settimer(func {
                    # from off to idle: init startup sequence
                    setprop("controls/engines/engine["~eng~"]/starter", 1);
                    interpolate("controls/engines/engine["~eng~"]/starter", 0, 10);
                    
                    setprop("controls/engines/engine["~eng~"]/ignition", 1);
                    interpolate("controls/engines/engine["~eng~"]/ignition", 0, 10);
                    
                    setprop("controls/engines/engine["~eng~"]/flight", 0);
                    setprop("controls/engines/engine["~eng~"]/cutoff", 0);
                }, me.startdelay[eng] );
                    
                    
                    
              } else {
                #from flight to idle
                setprop("controls/engines/engine["~eng~"]/flight", 0);              
              }      
        } else {
            me.set(eng,2.0);
            setprop("controls/engines/engine["~eng~"]/flight", 1);
            
        }
    
    },
        
    down: func(eng) {
        #i.e. mid mouse button press
        curr = me.get(eng);
        
        if (curr == 2) {
            me.set(eng,1.0);
            #from flight to idle
            setprop("controls/engines/engine["~eng~"]/flight", 0);
        } elsif (curr == 1) {
            me.set(eng,0.0);
            #from idle to off
            setprop("controls/engines/engine["~eng~"]/ignition", 0);
            setprop("controls/engines/engine["~eng~"]/flight", 0);
            setprop("controls/engines/engine["~eng~"]/cutoff", 1);
        }

    },

    train: func () {
      pos = getprop("/controls/switches/ecp/trainswitch") or 0;
      if (pos == 0) {
        if (me.swpos[0]==2 and me.swpos[1]==2) {
              setprop("controls/engines/engine[0]/flight", 0);
              setprop("/controls/switches/ecp/trainswitch",1);
              settimer( func { me.testtrain(); } ,1 );
              }
      } else {
              me.aborttrain(0);
      }  
    },
        
    get: func(eng) {
        me.swpos[eng]=getprop("controls/switches/ecp/pos["~eng~"]") or 0;
        return me.swpos[eng]; 
    },
    
    set: func(eng, p) {
        interpolate("controls/switches/ecp/pos["~eng~"]", p, 0.2);
        me.swpos[eng] = p;
    },
    
    aborttrain: func(m) {
          setprop("controls/engines/engine[0]/flight", 1);
          setprop("/controls/switches/ecp/trainswitch", 0);
          setprop("/instrumentation/efis/vmd/training-aborted", m);
          if (m) { 
            settimer(func {setprop("/instrumentation/efis/vmd/training-aborted", 0);} ,10 );
            }
    },
    
    testtrain: func() {
          #if rotor rpm drops below 92% abort training mode automatically
          
          if ( getprop("/rotors/main/rpm") < 383*0.92 ) {
            me.aborttrain(1);            
          } else {
            settimer( func { me.testtrain(); } ,1 );
          }
    }  

};  

engswitch.init();
