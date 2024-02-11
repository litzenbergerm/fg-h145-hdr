#
# Engine Control Panel Switches code:
# by litzi
#

# called from ec145-main-panel.xml model file
 
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
                    #reset starter-signal to 0 after 10 sec
                    interpolate("controls/engines/engine["~eng~"]/starter", 0, 10);
                    
                    setprop("controls/engines/engine["~eng~"]/ignition", 1);
                    #reset ignition signal to 0 after 10 sec
                    interpolate("controls/engines/engine["~eng~"]/ignition", 0, 12);
                    
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
              setprop("controls/engines/engine[0]/training", 1);
              setprop("/controls/switches/ecp/trainswitch",1);
              settimer( func { me.testtrain(); } ,1 );
              }
      } else {
              me.aborttrain(0);
      }  
    },
        
    train2idle: func () {
        # both engines main switches idle
        if (engswitch.get(0) == 2) engswitch.down(0);
        if (engswitch.get(1) == 2) engswitch.down(1);
        
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
          #setprop("controls/engines/engine[0]/flight", 1);
          setprop("controls/engines/engine[0]/training", 0);
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

# This is the model-specifc part of the auto-startup procedure object defined in bk117.nas

procedure["process"] = func(id) {
        id == me.loopid or return;

        # startup
        if (me.stage == 1) {
                print("", "1: rotor break .. release, fuel prime pumps .. both on, batt mstr .. on --> wait 10 sec for fuel pressure");
                interpolate("/controls/rotor/brake", 0, 1);
                # power on
                setprop("/controls/electric/battery-switch", 1);
                setprop("/controls/electric/stbyhor-switch", 1);
                
                fuel_pump_xfer.off(0);
                fuel_pump_xfer.off(1);       
                fuel_pump_prime.on(0);
                fuel_pump_prime.on(1);
                
                setprop("engines/startup_proc", 1);
                me.next(2);

        } elsif (me.stage == 2) {
                print("", "2: avio 1,2 switch .. on");
                setprop("controls/electric/avionics-switch1", 1);
                setprop("controls/electric/avionics-switch2", 1);
                me.next(5);
                
        } elsif (me.stage == 3) {
                print("", "3: engine #1 main sw .. idle");
                if (engswitch.get(0) == 0) engswitch.up(0);
                me.next(25);
    
        } elsif (me.stage == 4) {
                print("", "4: engine #2 main sw .. idle --> wait for N2~70%");
                if (engswitch.get(1) == 0) engswitch.up(1);
                me.next(25);

        } elsif (me.stage == 5) {
                print("", "5: engine #1 main sw .. flight");
                if (engswitch.get(0) == 1) engswitch.up(0);
                me.next(2);
    
        } elsif (me.stage == 6) {
                print("", "6: engine #2 main sw .. flight --> wait for NRO 100%");
                if (engswitch.get(1) == 1) engswitch.up(1);
                me.next(5);            
    
        } elsif (me.stage == 7) {
                print("", "7: fuel prime pumps .. both off, fuel xfer pumps .. both on");
                fuel_pump_prime.off(0);
                fuel_pump_prime.off(1);
                fuel_pump_xfer.on(0);
                fuel_pump_xfer.on(1);
                ### added by StuartC ###
                setprop("/controls/electric/engine/generator", 1);
                setprop("/controls/electric/engine[1]/generator", 1);

        # shutdown
        } elsif (me.stage == -1) {
              print("", "-1: engines main sw .. both idle --> cool engines");
              setprop("engines/shutdown_proc", 1);
              if (engswitch.get(0) == 2) engswitch.down(0);
              if (engswitch.get(1) == 2) engswitch.down(1);
              me.next(20);

        } elsif (me.stage == -2) {
              print("", "-2: engines main sw .. both off --> wait for NRO decay");
              if (engswitch.get(0) == 1) engswitch.down(0);
              if (engswitch.get(1) == 1) engswitch.down(1);
              me.next(2);

        } elsif (me.stage == -3) {
              print("", "-3: fuel xfer pumps .. both off");
              fuel_pump_xfer.off(0);
              fuel_pump_xfer.off(1);       
              me.next(30);
              
        } elsif (me.stage == -4) {
              print("", "-4: rotor brake .. apply");
              setprop("engines/shutdown_proc",0);
              interpolate("/controls/rotor/brake", 1, 2);
              me.next(20);

        } elsif (me.stage == -5) {
              print("", "-5: batt mstr.. off");
              setprop("controls/electric/avionics-switch1", 0);
              setprop("controls/electric/avionics-switch2", 0);
              
              setprop("/controls/electric/battery-switch", 0);
              
        }

};
