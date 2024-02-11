# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

var ROSESC = 0.58;
var ROSEX = 180;
var ROSEY = ROSEX * ROSESC;
var DMEFACTOR = 0.0005399;
var ALTFACTOR = (651-464)/400;  
var FPS2FPM = 60;
var SHIFT_THRES = 0.5;
var ROT_THRES = 0.1;    

# include some helper functions for the FND page if not already loaded
if (!defined("FND_FUNC_LOADED"))
   io.include(HELIONIXPATH ~ "Nasal/fnd_func.nas");

# add some specific sensors for the Helionix displays of h145 (bk117-D2),
# if not already defined

if ( contains(adc,"ralt_lut") == 0) {
    
    adc["ralt_lut"] = LUT.new([[0,0], [100,123.8], [1000,678.5], [2200,1173.5], [2500,1500]]);
    adc["agllut"] = Sensor.new({"function": func {return adc.ralt_lut.get(adc.agl.val)} });

    for (var li=0; li<7; li+=1) {
        foreach (var j; [0,1,2]) {      
          adc["masterlist_"~li~"_"~j] = Sensor.new({
                prop: "instrumentation/efis/fnd/masterlist["~li~"]/msg["~j~"]", 
                type: "STRING"
                });
        }
        adc["masterlist_"~li~"_level"] = Sensor.new({
              prop: "instrumentation/efis/fnd/masterlist["~li~"]/level", 
              type: "FLOAT"
              });
    }
}    

page_setup["fnd"] = func (i) {
  
  p = mfd[i].add_page("fnd", HELIONIXPATH~"svg/fnd.svg");
  
  generateAltLadder(p, pitch=ALTFACTOR*100);

  # MFD top row button labels
  # ============================
  
  p.add_cond("fndBtn",  {offset: 0 } );
  p.add_cond("vmdBtn",  {offset: isin("vmd", mfd[i].pages) > -1 } );
  p.add_cond("navdBtn", {offset: isin("navd", mfd[i].pages) > -1 } );
  p.add_cond("dmapBtn", {offset: isin("dmap", mfd[i].pages) > -1 } );
  p.add_cond("miscBtn", {offset: isin("misc", mfd[i].pages) > -1 } );
  p.add_cond("efbBtn", {offset: isin("efb", mfd[i].pages) > -1 } );

  # alt tape elements animation
  # ============================
  var raltoffset = getprop("/instrumentation/efis/fnd/radar-alt-offset-ft");
  
  p.add_direct("altBug", adc.alt, func(o,c) o.setTranslation(0, -ALTFACTOR*(adc.aptargetAlt.val - adc.alt.val) ) );
  p.add_trans("altBack", "y-shift", {sensor: adc.agl, min: -280, max: 280, scale: 130/280} );
  p.add_direct("aglBug", adc.agl, func(o,c) o.setTranslation(0, adc.agllut.val - adc.ralt_lut.get(getprop("/autopilot/settings/target-agl-ft") or 0) ));
  p.add_trans("radarAlttape", "y-shift", {sensor: adc.agllut, offset: -raltoffset});

  # move speed and fli tapes, animate ai elements
  # ============================

  p.add_direct("iasBug", adc.ias, func(o,c) o.setTranslation(0, (adc.ias.val - adc.aptargetSpeed.val)*3.19));
  p.add_trans("flitape", "y-shift", {sensor: adc.fli, scale: 90.3, offset: 0, max: 10, min: 0 });
  p.add_trans("speedtape", "y-shift", {sensor: adc.ias, max:350, min:-20, scale: 3.19});
  
  p.add_trans("Alt_Group", "y-shift", {sensor: adc.alt, scale: ALTFACTOR });

  #TODO Experimental: testbench for property rule transformations
  #p.link2rule("flitape", "instrumentation/efis/fnd/fli-tape", {type:"y-shift", scale:90.3, offset:0, max:10, min:0, abs:0, mod:nil});
  #p.link2rule("speedtape", "velocities/airspeed-kt", {type:"y-shift", scale:3.19, offset:0, max:350, min:-20, abs:0, mod:nil});
  
  p.add_trans("fli_sync", "y-shift", {sensor: adc.fliSync, scale: -90.3, offset: 0, max: 10, min: -10 });
  p.add_trans("fli_ttop", "y-shift", {sensor: adc.fliTtop, scale: -90.3, offset: 0, max: 10, min: -10 });
  p.add_trans("fli_mcp", "y-scale", {sensor: adc.add( { function: func {getprop("instrumentation/efis/fnd/fli-top") - getprop("instrumentation/efis/fnd/fli-mcp") }}) });
  p.add_trans("fli_mcp", "y-shift", {sensor: adc.fliMcp, scale: -90.3, offset: 0, max: 10, min: -10 });

  p.add_trans("horizon", "y-shift", {sensor: adc.pitch, scale: 3.6, max: 90 , min:-90});
  p.add_trans("horizon", "rotation", {sensor: adc.roll, scale: -1});

  p.add_trans("horizonNums", "y-shift", {sensor: adc.pitch, scale: 3.6, max: 90 , min:-90});
  p.add_trans("horizonNums", "rotation", {sensor: adc.roll, scale: -1});

  p.add_trans("rollPointer", "rotation", {sensor: adc.roll, scale: -1 });
  p.add_trans("slipSkid", "x-shift", {sensor: adc.slipskid, scale: -25 });
  
  p.add_text("aglNum", {sensor: adc.agl, format: "%d", offset: -raltoffset, trunc: "abs"});
  p.add_cond("aglNum", {sensor: adc.agl, lessthan: 1000 });

  # move vsi needle and numerical indication
  # ============================

  p.add_trans("vsi", "rotation", {sensor: adc.vs, scale:-1.2, max:35, min:-35});
  p.add_trans_grp(["vsi", "vsiNum"], "y-shift", {sensor: adc.vs, scale: -84/2000*FPS2FPM, max:35, min:-35 });
  p.add_trans("vsBug", "y-shift", {sensor: adc.aptargetRoc, scale: -84/2000*FPS2FPM, max:35, min:-35 });
  
  p.add_trans("vsiNum", "y-shift", {sensor: adc.vsiNumVis });
  p.add_text("vsiNum", {sensor: adc.vs, trunc: "abs", scale: FPS2FPM/100, format: "%2.0f" });
  p.add_cond("vsiNum", {sensor: adc.vs, notin: [-3,3] });

  # Rose transformations
  # Bearing Needles
  # ============================

  p.add_trans("bear1Needle", "rotation", {sensor: adc.add({function: func navSrcBear(adc.bearsrc0[i].val), timer: FAST}) });
  p.add_cond("bear1Needle", {sensor: adc.add({function: func navSrcInrange(adc.bearsrc0[i].val), timer: SLOW}) });

  p.add_trans("bear2Needle", "rotation", {sensor: adc.add({function: func navSrcBear(adc.bearsrc1[i].val), timer: FAST}) });
  p.add_cond("bear2Needle", {sensor: adc.add({function: func navSrcInrange(adc.bearsrc1[i].val), timer: SLOW}) });
  
  # course and CDI 
  # ============================

  p.add_trans("Rose_Group", "rotation", {sensor: adc.heading, scale: -1});
  p.add_trans("hdgBug", "rotation", {sensor: adc.headbug});

  p.add_trans("cdiNeedle", "x-shift", {sensor: adc.add( {function: func navSrcDefl(adc.navsrc[i].val), timer:FAST }), scale: 7.5 });
  p.add_cond_grp(["cdiNeedle", "toFrom"], {sensor: adc.add( {function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW }) });

  p.add_trans("toFrom", "rotation", {sensor: adc.add( {function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0from.val : adc.nav1from.val }, timer: SLOW}), scale:180}); 
  p.add_trans("Cdi_Group", "rotation", {sensor: adc.add( {function: func navSrcCrs(adc.navsrc[i].val), timer:FAST}) });

  p.add_trans("Rose_Group", "y-scale", {offset: ROSESC});

  p.add_trans("gsNeedle", "y-shift", {sensor: adc.add({function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0gsdef.val : adc.nav1gsdef.val }, timer:FAST}), scale: -65});
  p.add_cond_grp(["gsNeedle", "gsScale"], {sensor: adc.add({function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0gsinrange.val : adc.nav1gsinrange.val}, timer:SLOW}) }); 

  p.add_trans("speedTrend", "y-scale", {sensor: adc.iasTrend, scale: 0.02, max: 40, min:-40});

  p.add_cond("Mrk_Group", {sensor: adc.ilsmarker });
  p.add_text("MrkLabel", {sensor: adc.add( {function: func { ( adc.ilsin.val ? "I" : (adc.ilsmid.val ? "M" : (adc.ilsout.val ? "O" : "" )))}, timer: SLOW, type: "STRING" }) });
  
  # lots of text
  # for nav aids to update
  # ============================
  
  # if FMS show "GPS" else show Nav frequency
  p.add_text("navFrq", {sensor: adc.navsrc[i], funcof: "navSrcFrq" });
  p.add_cond("navFrq", {sensor: adc.navsrc[i], notequal: "FMS" });
  p.add_text("navID",  {sensor: adc.navsrc[i], funcof:"navSrcId" });
  p.add_text("navSrc", {sensor: adc.navsrc[i], funcof: "navSrcType" });
  p.add_text("crs", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:SLOW, type:"STRING"}), format: "%3.0f"});
  p.add_text("navDME", {sensor: adc.add( {function: func navSrcDist(adc.navsrc[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("navDME", {sensor: adc.add( {function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW, type: "BOOL"}) });
  p.add_cond("navGPS", {sensor: adc.navsrc[i], equals: "FMS" });
  
  adc["navTTG"~i] = Sensor.new({function: func navSrcTTG(adc.navsrc[i].val), timer: SLOW});
  
  p.add_text("navTTG", {sensor: adc["navTTG"~i], format: "%i mn" });
  p.add_cond("navTTG", {sensor: adc["navTTG"~i], between: [1, 120] });
  p.add_text("bearingSrc1", {sensor: adc.bearsrc0[i], funcof: "navSrcType" });
  p.add_text("bearingSrc2", {sensor: adc.bearsrc1[i], funcof: "navSrcType" });
  p.add_text("bearingFrq1", {sensor: adc.bearsrc0[i], funcof: "navSrcFrq" });
  p.add_text("bearingFrq2", {sensor: adc.bearsrc1[i], funcof: "navSrcFrq" });
  p.add_text("bearingDME1", {sensor: adc.add( {function: func navSrcDist(adc.bearsrc0[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("bearingDME1", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc0[i].val), timer: SLOW, type: "STRING" }) });
  p.add_text("bearingDME2", {sensor: adc.add( {function: func navSrcDist(adc.bearsrc1[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("bearingDME2", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc1[i].val), timer: SLOW, type: "STRING" }) });
  
  # /instrumentation/nav[0]/has-gs  --> navSrc VOR1/ILS1

  # fuel indicators 
  # and rotor and eng rmp
  # ============================

  p.add_trans("fuelTotal", "y-scale", {sensor: adc.tank0 });
  p.add_trans("fuelL", "y-scale", {sensor: adc.tank1 });
  p.add_trans("fuelR", "y-scale", {sensor: adc.tank2 });
  p.add_text("fuelNum", {sensor: adc.tank_total, scale: LB2KG, format: "%3.0f Kg" });
  p.add_text("nrNum", {sensor: adc.nr, format: "%d"});
  p.add_trans_grp(["nrNeedle1", "nrNeedle2"], "rotation", {sensor: adc.nr, min: 80 , max:120, scale: 180/40, offset: -360});
  p.add_trans("n2_1Needle", "rotation", {sensor: adc.n2_1, min: 80 , max:120, scale: 180/40, offset: -360});
  p.add_trans("n2_2Needle", "rotation", {sensor: adc.n2_2, min: 80 , max:120, scale: 180/40, offset: -360});

  # note: this works also 
  # p.add_text("fuelNum", {function:  func sprintf("%3.0fKg", getprop("consumables/fuel/tank[0]/level-norm")*500)  });

  p.add_text("OAT", {sensor: adc.oat, format: "%3.0f°C" });
  p.add_text("qnh", {sensor: adc.qnhDisplay });

  # AP annunciators text items
  # 
  # ============================

  p.add_text("altTarget", {sensor: adc.aptargetAlt, format: "%d"});        
  p.add_cond_grp(["altTarget", "altBug"], {sensor: adc.altTargetVis });

  p.add_text("aglTarget", {sensor: adc.aptargetAgl, format: "%3.0f"});
  p.add_cond_grp(["aglTarget", "aglBug"], {sensor: adc.aglTargetVis});

  p.add_cond("iasBug", {sensor: adc.apspeed, equals: "speed-with-pitch-trim" });     
  p.add_cond("vsBug", {sensor: adc.vsBugVis });

  p.add_text("apLockRoll", {sensor: adc.apLockRoll });
  p.add_text("apArmRoll", {sensor: adc.apArmRoll });
  p.add_text("apLockPitch", {sensor: adc.apLockPitch });
  p.add_text("apArmPitch", {sensor: adc.apArmPitch });
  p.add_text("apLockColl", {sensor: adc.apLockColl });
  p.add_text("apArmColl", {sensor: adc.apArmColl });

  # master list text items
  # and color animation
  # ============================

  var masterlistcolors =  [
                    [2,  [0,1,0]],
                    [nil, [1,0.75,0]],
                    [4,  [1,0,0]]
                  ];
  
  for (var li=0; li<7; li+=1) {
    foreach (var j; [0,1,2]) {
      p.add_text("ml_"~li~"_"~j, {sensor: adc["masterlist_" ~ li ~ "_" ~ j]}); 
      p.add_color_range("ml_"~li~"_"~j, adc["masterlist_"~li~"_level"], masterlistcolors);    
    }  
  }
    

  # translate rose numerals in elliptic orbit
  # around center of compass rose
  # ============================

  var HdgNums = Rosenumerals.new(p, ROSEX, ROSEY);

  Generatewindbarb(p);
  
}; # func 
