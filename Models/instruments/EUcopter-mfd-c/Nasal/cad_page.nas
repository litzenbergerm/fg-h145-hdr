# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# blinking caution bars in case of low N1, or low fuel
# just a guess, unknown which conditions in RL trigger the
# caution indication

if (!contains(adc, "blink")) {
    var CBARS = props.globals.getNode("instrumentation/efis/cad/cautionbars", 1); 
    var cbartimer = maketimer(0.75, func CBARS.setValue(!CBARS.getValue()) );
    cbartimer.start(); 
    adc["blink"] = Sensor.new({ prop: CBARS.getPath() });
}

var p=nil;
if (contains(adc,"rotorb") == 0) {
  # add some more sensors in air data computer, for engine and fuel system
  foreach (var e; [1,2]) {
    adc["start"~e] = Sensor.new({prop: "/engines/engine["~(e-1)~"]/starter"});
    adc["engfuel"~e] = Sensor.new({prop: "/engines/engine["~(e-1)~"]/out-of-fuel"});  
    adc["bustie"~e] = Sensor.new({prop: "/controls/electric/engine["~(e-1)~"]/bus-tie"});
    adc["primepump"~e] = Sensor.new({prop: "/controls/fuel/tank["~e~"]/prime-pump"});
    adc["generator"~e] = Sensor.new({prop: "/controls/electric/engine["~(e-1)~"]/generator"});
    adc["tgrip"~e] = Sensor.new({prop: "/controls/engines/engine["~(e-1)~"]/twist-grip"} );
  }

  adc["battsw"] = Sensor.new({prop: "/controls/electric/battery-switch"});
  adc["fpumpfwd"] = Sensor.new({prop: "/controls/switches/fuel/transfer-pump[0]"});
  adc["fpumpaft"] = Sensor.new({prop: "/controls/switches/fuel/transfer-pump[1]"});
  adc["rotorb"] = Sensor.new({prop: "/controls/rotor/brake"});
}

page_setup["cad"] = func (i) {
  
  p = mfd[i].add_page("cad", HELIONIXPATH~"svg/cad.svg");

  # fuel indicators 
  # ============================

  p.add_trans("fuelTotal", "y-scale", {sensor: adc.tank0 });
  p.add_trans("fuelL", "y-scale", {sensor: adc.tank1 });
  p.add_trans("fuelR", "y-scale", {sensor: adc.tank2 });

  p.add_text("fuelNum", {sensor: adc.tank0lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelNum1", {sensor: adc.tank1lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelNum2", {sensor: adc.tank2lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelFlowL", {sensor: adc.ff_1, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelFlowR", {sensor: adc.ff_2, scale: LB2KG, format: "%3.0f" });

  #Fuel endurance time
  p.add_text("enduH", {sensor: adc.endurance, scale: 1/3600, "trunc":1, format: "%1i" });
  p.add_text("enduMin", {sensor: adc.endurance, scale: 1/60, "mod":3600, format: "%2i" });

  #Messages Engines 
  foreach (var e; [1,2]) {
    p.add_cond("msg"~e~"_engfail",{sensor: adc["n1_"~e], lessthan: 60});
    p.add_cond("msg"~e~"_engidle",{sensor: adc["n1_"~e], between: [60,70]});
    p.add_cond("msg"~e~"_starter",{sensor: adc["start"~e], greaterthan: 0.01 });
    p.add_cond("msg"~e~"_fuelpress",{sensor: adc["engfuel"~e] });
    p.add_cond("msg"~e~"_engoilp",{sensor: adc["oil_p"~e], lessthan: 1.5 });
    p.add_cond("msg"~e~"_bustieopn",{sensor: adc["bustie"~e], notequal: 1 });
    p.add_cond("msg"~e~"_primepump",{sensor: adc["primepump"~e] });
    p.add_cond("msg"~e~"_gendiscon",{sensor: adc["generator"~e], notequal: 1 });
    
    # indicate twist grip only if starter is off
    # couple to any periodic sensor on this page
    p.add_directTV("msg"~e~"_twistgrip", adc.blink, func(o,c) {o.setVisible( (adc["tgrip"~c].val<10) and (adc["start"~c].val<0.01) ) }, v=e);
    
    p.add_directTV("cautionbars"~e, adc.blink, func(o,c) { o.setVisible ( adc.blink.val and
                                  ( (adc["n1_"~c].val < 60) or
                                    (adc["oil_p"~c].val<1.5) or
                                    (adc["engfuel"~c].val==1) or
                                    (adc["tgrip"~c].val<10)
                                   )
                                  ); 
                              }, v=e);
  }  
  
  p.add_directTV("cautionbars", adc.blink, func(o,c) {o.setVisible( adc.blink.val and
                                  ( 
                                    (adc.tank1lbs.val*LB2KG < 24) or 
                                    (adc.tank2lbs.val*LB2KG < 24) or
                                    ( (adc["fpumpaft"].val==0) and (adc["fpumpfwd"].val==0) )
                                   )
                                  ); 
                              }
  );
                                  
  p.add_cond("msg_battdisch", {sensor: adc["batteryload"], greaterthan: 0.01 });
  p.add_cond("msg_battdiscon", {sensor: adc["battsw"], notequal: 1 });
  p.add_cond("msg_fpumpaft", {sensor: adc["fpumpaft"], notequal: 1 });
  p.add_cond("msg_fpumpfwd", {sensor: adc["fpumpfwd"], notequal: 1 });
  p.add_cond("msg_fuel", {sensor: adc.add({ function: func () {return (adc.tank1lbs.val*LB2KG) < 24 or (adc.tank2lbs.val*LB2KG) < 24; } }) });
  p.add_cond("msg_rotorbrake", {sensor: adc["rotorb"], notequal: 0 });
  
  p.add_cond("msg_doors", {sensor: adc.add({ function: func () {
    return getprop("/sim/model/bk117/door-positions/leftBackDoor/position-norm") or
    getprop("/sim/model/bk117/door-positions/leftFrontDoor/position-norm") or
    getprop("/sim/model/bk117/door-positions/rightBackDoor/position-norm") or
    getprop("/sim/model/bk117/door-positions/rightFrontDoor/position-norm") or
    getprop("/sim/model/bk117/door-positions/rightRearDoor/position-norm") or
    getprop("/sim/model/bk117/door-positions/leftRearDoor/position-norm");
    } 
   }) 
  });
   
  
}; # func