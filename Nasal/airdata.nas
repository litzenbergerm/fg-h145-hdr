# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# add sensor elements. to avoid repeated readout of the same 
# property values we define sensors (originally seen in Thorstens Zivko Edge)
# =========================

# air data computer
adc = {};
  
# properties that change very frequently will be polled to avoid overhead (disable_listener)
adc["roll"] = Sensor.new({"prop":"orientation/roll-deg", "disable_listener": FAST, "thres":0.1 });
adc["pitch"] = Sensor.new({"prop": "orientation/pitch-deg", "disable_listener": FAST, "thres":0.1});
adc["ias"] = Sensor.new({"prop": "instrumentation/airspeed-indicator/indicated-speed-kt", "disable_listener":FAST, "thres":0.1});
adc["alt"] = Sensor.new({"prop": "instrumentation/altimeter/indicated-altitude-ft", "disable_listener":FAST, "thres":0.5});
adc["vs"] = Sensor.new({"prop": "velocities/vertical-speed-fps", "disable_listener":FAST, "thres":0.1});
adc["agl"] = Sensor.new({"prop": "position/altitude-agl-ft", "disable_listener":FAST, "thres":0.1});
adc["heading"] = Sensor.new({"prop": "orientation/heading-magnetic-deg", "disable_listener":FAST, "thres":0.1});

adc["ralt_lut"] = LUT.new([[0,0], [100,123.8], [1000,678.5], [2200,1173.5], [2500,1500]]);
adc["agllut"] = Sensor.new({"function": func {return adc.ralt_lut.get(adc.agl.get())} });

adc["nr"] = Sensor.new({"prop": "rotors/main/rpm-pct", "disable_listener":FAST, "thres":0.1});
adc["n2_1"] = Sensor.new({"prop": "engines/engine[0]/n2-pct", "disable_listener":FAST, "thres":0.1});
adc["n2_2"] = Sensor.new({"prop": "engines/engine[1]/n2-pct", "disable_listener":FAST, "thres":0.1});
adc["n1_1"] = Sensor.new({"prop": "engines/engine[0]/n1-pct", "disable_listener":FAST, "thres":0.1});
adc["n1_2"] = Sensor.new({"prop": "engines/engine[1]/n1-pct", "disable_listener":FAST, "thres":0.1});
adc["trq_1"] = Sensor.new({"prop": "engines/engine[0]/torque-pct", "disable_listener":FAST, "thres":0.1});
adc["trq_2"] = Sensor.new({"prop": "engines/engine[1]/torque-pct", "disable_listener":FAST, "thres":0.1});
adc["tot_1"] = Sensor.new({"prop": "engines/engine[0]/tot-degc", "disable_listener":FAST, "thres":1});
adc["tot_2"] = Sensor.new({"prop": "engines/engine[1]/tot-degc", "disable_listener":FAST, "thres":1});

adc["nr_lut"] = LUT.new([[0,0], [80,90], [100,180], [120,270]]);
#adc["nrlut"] = Sensor.new({"function": func {return adc.nr_lut.get(adc.nr.get())} });

adc["oil_t1"] = Sensor.new({"prop": "engines/engine/oil-temperature-degc", "disable_listener":FAST, "thres":1});
adc["oil_t2"] = Sensor.new({"prop": "engines/engine[1]/oil-temperature-degc", "disable_listener":FAST, "thres":1});
adc["oil_p1"] = Sensor.new({"prop": "engines/engine/oil-pressure-bar", "disable_listener":FAST, "thres":0.01});
adc["oil_p2"] = Sensor.new({"prop": "engines/engine[1]/oil-pressure-bar", "disable_listener":FAST, "thres":0.01});
adc["mgb_p"] = Sensor.new({"prop": "rotors/gear/mgb-oil-pressure-bar", "disable_listener":FAST, "thres":0.01});
#adc["mgb_t"] = Sensor.new({"prop": "engines/engine[1]/oil-pressure-bar", "disable_listener":FAST, "thres":0.01});

adc["nav0dmeinrange"] = Sensor.new({"prop": "instrumentation/nav[0]/dme-in-range", "type":"BOOL"});
adc["nav1dmeinrange"] = Sensor.new({"prop": "instrumentation/nav[1]/dme-in-range", "type":"BOOL"});
adc["nav0inrange"] = Sensor.new({"prop": "instrumentation/nav[0]/in-range", "type":"BOOL"});
adc["nav1inrange"] = Sensor.new({"prop": "instrumentation/nav[1]/in-range", "type":"BOOL"});
adc["adf0inrange"] = Sensor.new({"prop":"instrumentation/adf[0]/in-range", "type":"BOOL"});
adc["nav0hasgs"] = Sensor.new({"prop": "instrumentation/nav[0]/has-gs", "type":"BOOL"});
adc["nav1hasgs"] = Sensor.new({"prop": "instrumentation/nav[1]/has-gs", "type":"BOOL"});
adc["nav0gsinrange"] = Sensor.new({"prop": "instrumentation/nav[0]/gs-in-range", "type":"BOOL"});

adc["nav0crs"] = Sensor.new({"prop": "instrumentation/nav[0]/radials/selected-deg" });
adc["qnh"] = Sensor.new({"prop": "instrumentation/altimeter/setting-inhg"});
adc["fli"] = Sensor.new({"prop": "instrumentation/efis/fnd/fli-tape"});
adc["slipskid"] = Sensor.new({"prop": "instrumentation/slip-skid-ball/indicated-slip-skid"});
adc["nav1bear"] = Sensor.new({"prop": "instrumentation/nav[1]/rel-bearing-deg"}); 
adc["adf0bear"] = Sensor.new({"prop": "instrumentation/adf[0]/indicated-bearing-deg"});
adc["headbug"] = Sensor.new({"prop": "autopilot/settings/heading-bug-deg"});
adc["nav0defl"] = Sensor.new({"prop": "instrumentation/nav[0]/heading-needle-deflection"});

adc["aproll"] = Sensor.new({"prop": "autopilot/locks/heading", "type": "STRING" });
adc["apalt"] = Sensor.new({"prop": "autopilot/locks/altitude", "type": "STRING" });
adc["aprollarm"] = Sensor.new({"prop": "autopilot/locks/heading-arm", "type": "STRING"});
adc["apaltarm"] = Sensor.new({"prop": "autopilot/locks/altitude-arm", "type": "STRING"});

adc["apspeed"] = Sensor.new({"prop": "autopilot/locks/speed", "type": "STRING"});
adc["apcoll"] = Sensor.new({"prop": "autopilot/internal/use-collective-for-alt"});

adc["tank0"] = Sensor.new({"prop": "consumables/fuel/tank[0]/level-norm", "disable_listener": SLOW} );
adc["tank1"] =Sensor.new({"prop": "consumables/fuel/tank[1]/level-norm", "disable_listener": SLOW} );
adc["tank2"] =Sensor.new({"prop": "consumables/fuel/tank[2]/level-norm", "disable_listener": SLOW} );

adc["tank_total"] = Sensor.new({"prop":  "consumables/fuel/total-fuel-lbs", "disable_listener": SLOW, "thres":1} );

adc["tank0lbs"] = Sensor.new({"prop":  "/consumables/fuel/tank[0]/level-lbs", "disable_listener": SLOW, "thres":1} );
adc["tank1lbs"] = Sensor.new({"prop":  "/consumables/fuel/tank[1]/level-lbs", "disable_listener": SLOW, "thres":1} );
adc["tank2lbs"] = Sensor.new({"prop":  "/consumables/fuel/tank[2]/level-lbs", "disable_listener": SLOW, "thres":1} );
adc["endurance"] = Sensor.new({"prop": "/consumables/fuel/endurance-sec", "disable_listener": SLOW, "thres":60} );
adc["ff_1"] = Sensor.new({"prop": "/engines/engine/fuel-flow_pph", "disable_listener": SLOW, "thres":1 } );
adc["ff_2"] = Sensor.new({"prop": "/engines/engine[1]/fuel-flow_pph", "disable_listener": SLOW, "thres":1 } );

adc["grossweight"] = Sensor.new({"prop": "/yasim/gross-weight-lbs", "disable_listener": SLOW, "thres":1} );

adc["winddir"] = Sensor.new({"prop": "/environment/wind-from-heading-deg", "disable_listener": SLOW, "thres":1} );
adc["windspeed"] = Sensor.new({"prop": "/environment/wind-speed-kt", "disable_listener": SLOW, "thres":1} );


adc.del = func () {
  print("del ... adc");
  var k = keys(me);
  foreach (var x; k) 
     if (x != "del") me[x].del();          
};