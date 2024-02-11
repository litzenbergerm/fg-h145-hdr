#
# Engine Control Panel Switches and Twist Grip code:
# by litzi
#

# called from EC145C2-main-panel.xml model file

# in the EC145 the main engine switch is only for starting the engine
# the switch resets autmatically to off after n1 ~ 50% is reached
var engswitch = {
    swpos: [0, 0],
    startdelay: [0.1, 0.1],
    
    init: func {
                me.get(0);
                me.get(1);
                setlistener("/controls/switches/ecp/pos[0]", func() me.up(0) );
                setlistener("/controls/switches/ecp/pos[1]", func() me.up(1) );               
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
        var curr = me.get(eng);
        
        if (curr == 1) {
            var delay=0.1;
            # if other engine is starting delay all steps by 11 sec
            if (curr==1 and getprop("controls/engines/engine["~!eng~"]/starter") >0 ) 
               me.startdelay[eng] = 11;
            
            #me.set(eng, 1.0);
            
            if (curr == 1) {
                settimer(func {
                    # from off to idle: init startup sequence
                    setprop("controls/engines/engine["~eng~"]/starter", 1);
                    interpolate("controls/engines/engine["~eng~"]/starter", 0, 10);
                    
                    #setprop("controls/engines/engine["~eng~"]/flight", 0);
                    setprop("controls/engines/engine["~eng~"]/cutoff", 0);
                    
                    # switch returns automatically to off
                    settimer(func me.set(eng, 0) ,10);

                }, me.startdelay[eng] );                    
              }      
        } else {
            # abort engine start
            setprop("controls/engines/engine["~eng~"]/starter", 0);
            
        }
    
    },        

    train2idle: func () {
        # roll back both twist grips to idle position
        interpolate("controls/engines/engine[0]/twist-grip", 5, 1);
        interpolate("controls/engines/engine[1]/twist-grip", 5, 1);      
    },
        
    get: func(eng) {
        me.swpos[eng]=getprop("controls/switches/ecp/pos["~eng~"]") or 0;
        return me.swpos[eng]; 
    },
    
    set: func(eng, p) {
        #interpolate("controls/switches/ecp/pos["~eng~"]", p, 0.2);
        setprop("controls/switches/ecp/pos["~eng~"]", p);
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
 
var twistgrip = {
    grippos: [0, 0],
    
    init: func {
                me.get(0);
                me.get(1);
                setlistener("/controls/engines/engine[0]/twist-grip", func() me.update(0) );
                setlistener("/controls/engines/engine[1]/twist-grip", func() me.update(1) );               
                },
                
    update: func(eng) {
        # update engine controls upon twist grip action
        var curr = me.get(eng);
        
        if (curr == 0) {
            setprop("controls/engines/engine["~eng~"]/ignition", 0);
            setprop("controls/engines/engine["~eng~"]/cutoff", 1);
            setprop("controls/engines/engine["~eng~"]/flight", 0);
        } elsif (curr < 4) {
            setprop("controls/engines/engine["~eng~"]/ignition", 1);
            setprop("controls/engines/engine["~eng~"]/flight", 0);
            setprop("controls/engines/engine["~eng~"]/cutoff", 0);
            bk117.propulsion.engine[eng].adjust_power( (curr-5)/100 );
        } elsif (curr <= 9) {
            setprop("controls/engines/engine["~eng~"]/ignition", 0);
            setprop("controls/engines/engine["~eng~"]/flight", 0);
            setprop("controls/engines/engine["~eng~"]/cutoff", 0);
            bk117.propulsion.engine[eng].adjust_power( (curr-5)/100 );
            
        } elsif (curr > 9) {
            setprop("controls/engines/engine["~eng~"]/ignition", 0);
            setprop("controls/engines/engine["~eng~"]/flight", 1);
            setprop("controls/engines/engine["~eng~"]/cutoff", 0);
        }
    },
        
    get: func(eng) {
        me.grippos[eng]=getprop("/controls/engines/engine["~eng~"]/twist-grip") or 0;
        return me.grippos[eng]; 
    },
    
    set: func(eng, p) {
        interpolate("/controls/engines/engine["~eng~"]/twist-grip", p, 0.2);
        me.grippos[eng] = p;       
    }

};  

twistgrip.init();

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
                me.next(2);
                
        } elsif (me.stage == 3) {
                print("", "3: twist grip .. set both to 20%");
                twistgrip.set(0, 2); 
                twistgrip.set(1, 2); 
                
                me.next(3);
                
        } elsif (me.stage == 4) {
                print("", "4: engine #1 start sw .. engage");
                if (engswitch.get(0) == 0) engswitch.set(0,1);
                me.next(25);
    
        } elsif (me.stage == 5) {
                print("", "5: twist grip eng #1 .. adjust to 70% N1");
                twistgrip.set(0, 4); 
                me.next(2);
                
        } elsif (me.stage == 6) {
                print("", "6: engine #2 start sw .. engage");
                if (engswitch.get(1) == 0) engswitch.set(1,1);
                me.next(25);

        } elsif (me.stage == 7) {
                print("", "7: twist grip eng #2 .. adjust to 70% N1");
                twistgrip.set(1,4); 
                me.next(5);

        } elsif (me.stage == 8) {
                print("", "8: twist grip .. set both to flight");
                twistgrip.set(0, 10); 
                twistgrip.set(1, 10); 
                me.next(5);
    
        } elsif (me.stage == 9) {
                print("", "9: fuel prime pumps .. both off, fuel xfer pumps .. both on");
                fuel_pump_prime.off(0);
                fuel_pump_prime.off(1);
                fuel_pump_xfer.on(0);
                fuel_pump_xfer.on(1);    
                setprop("/controls/electric/engine/generator", 1);
                setprop("/controls/electric/engine[1]/generator", 1);

        # shutdown
        } elsif (me.stage == -1) {
              print("", "-1: twist grip .. set both to idle to cool engines");
              interpolate("controls/engines/engine[0]/twist-grip", 5, 1);
              interpolate("controls/engines/engine[1]/twist-grip", 5, 1);
              setprop("engines/shutdown_proc",1);
              twistgrip.set(0,4); 
              twistgrip.set(1,4); 
              me.next(20);

        } elsif (me.stage == -2) {
              print("", "-2: twist grip .. set both to 0%");
              twistgrip.set(0,0); 
              twistgrip.set(1,0); 
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