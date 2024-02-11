# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

var ROSER = 185;
var DMEFACTOR = 0.0005399;
var ALTFACTOR = (651-464)/400;  
var FPS2FPM = 60;
var SHIFT_THRES = 0.5;
var ROT_THRES = 0.1;    

# include some helper functions for the FND page if not already loaded
if (!defined("FND_FUNC_LOADED"))
   io.include(HELIONIXPATH ~ "Nasal/fnd_func.nas");

if ( contains(adc,"ralt_lut") == 0) {
  adc["ralt_lut"] = LUT.new([[0,0], [100,96], [1000,537.7], [2200,929.6], [2500,1500]]);
  adc["agllut"] = Sensor.new({"function": func {return adc.ralt_lut.get(adc.agl.val)} });
}

page_setup["pfd"] = func (i) {
  
  p = mfd[i].add_page("pfd", HELIONIXPATH~"svg/pfd.svg");
  
  generateAltLadder(p, pitch=ALTFACTOR*100);

  # alt tape elements animation
  # ============================
  var raltoffset = getprop("/instrumentation/efis/fnd/radar-alt-offset-ft");
  
  p.add_direct("altBug", adc.alt, func(o,c) o.setTranslation(0, -ALTFACTOR*(adc.aptargetAlt.val - adc.alt.val) ) );
  p.add_direct("altBack", adc.agl, func(o,c) o.setTranslation(0, math.clamp( adc.agl.val, -280, 280) *130/280 ) );
  p.add_direct("radarAlttape", adc.agllut, func(o,c) o.setTranslation(0, clamp(adc.agllut.val-raltoffset, 0, 1100)) );
  p.add_direct("aglBug", adc.agl, func(o,c) o.setTranslation(0, adc.agllut.val - adc.ralt_lut.get(getprop("/autopilot/settings/target-agl-ft") or 0) ));
  p.add_trans("Alt_Group", "y-shift", {sensor: adc.alt, scale: ALTFACTOR });

  # move speed and fli tapes, animate ai elements
  # ============================

  p.add_direct("iasBug", adc.ias, func(o,c) o.setTranslation(0, (adc.ias.val - adc.aptargetSpeed.val)*3.19));

  #TODO Experimental: testbench for property rule transformations
  #p.link2rule("speedtape", adc.ias.path, {type:"y-shift", scale:3.19, offset:0, max:350, min:-20, abs:0, mod:nil});
  #p.link2rule("Alt_Group", adc.alt.path, {type:"y-shift", scale: ALTFACTOR, offset:0, max:35000, min:-2000, abs:0, mod:nil });
  
  p.add_trans("speedtape", "y-shift", {sensor: adc.ias, scale: 3.19 });
  p.add_trans("speedTrend", "y-scale", {sensor: adc.iasTrend, scale: 1/40, max: 40, min:-40});
  p.add_trans("speedTrendBar", "y-shift", {sensor: adc.iasTrend, scale: -3.19, max: 40, min:-40});

  p.add_trans("horizon", "y-shift", {sensor: adc.pitch, scale: 3.6, max: 90 , min:-90});
  p.add_trans("horizon", "rotation", {sensor: adc.roll, scale: -1});

  p.add_trans("horizonNums", "y-shift", {sensor: adc.pitch, scale: 3.6, max: 90 , min:-90});
  p.add_trans("horizonNums", "rotation", {sensor: adc.roll, scale: -1});

  p.add_trans("rollPointer", "rotation", {sensor: adc.roll, scale: -1 });
  
  p.add_text("aglNum", {sensor: adc.agl, format: "%3.0f", offset:-raltoffset, trunc: "abs"});
  p.add_cond("aglNum", {sensor: adc.agl, lessthan: 1000 });

  # move vsi needle and numerical indication
  # ============================

  p.add_trans("vsi", "rotation", {sensor: adc.vs, scale:-1.2, max:35, min:-35});
  p.add_trans_grp(["vsi", "vsiNum"], "y-shift", {sensor: adc.vs, scale: -84/2000*FPS2FPM, max:35, min:-35 });
  p.add_trans("vsBug", "y-shift", {sensor: adc.aptargetRoc, scale: -84/2000*FPS2FPM, max:35, min:-35 });
  
  p.add_trans("vsiNum", "y-shift", {sensor: adc.vsiNumVis });
  p.add_text("vsiNum", {sensor: adc.vs, "trunc": "abs", scale: FPS2FPM/100, format: "%2.0f" });
  p.add_cond("vsiNum", {sensor: adc.vs, notin: [-3,3] });

  # Rose transformations
  # Bearing Needles
  # ============================

  p.add_trans("bear1Needle", "rotation", {sensor: adc.add( {function: func navSrcBear(adc.bearsrc0[i].val), timer:FAST}) });
  p.add_cond("bear1Needle", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc0[i].val), timer:SLOW}) });

  p.add_trans("bear2Needle", "rotation", {sensor: adc.add( {function: func navSrcBear(adc.bearsrc1[i].val), timer:FAST}) });
  p.add_cond("bear2Needle", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc1[i].val), timer:SLOW}) });


  # course and CDI 
  # ============================

  p.add_trans("hdgBug2", "x-shift", {sensor: adc.headbug, scale: 2.422222222222});
  p.add_trans("crsNeedle2", "x-shift", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:FAST}), scale: 2.422222222222 });
  p.add_trans("Compass_Group", "x-shift", {sensor: adc.heading, scale: -2.422222222222});
  p.add_trans("Rose_Group", "rotation", {sensor: adc.heading, scale: -1});

  p.add_trans("hdgBug", "rotation", {sensor: adc.headbug});

  p.add_trans_grp(["cdiNeedle", "cdiNeedle2"], "x-shift", {sensor: adc.add( {function: func navSrcDefl(adc.navsrc[i].val), timer:FAST }), scale: 7.5 });
  p.add_cond_grp(["cdiNeedle", "toFrom", "Compass_layer"], {sensor: adc.add( {function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW }) });
  p.add_trans("toFrom", "rotation", {sensor: adc.add( {function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0from.val : adc.nav1from.val }, timer: SLOW}), scale:180}); 
  p.add_trans("Cdi_Group", "rotation", {sensor: adc.add( {function: func navSrcCrs(adc.navsrc[i].val), timer:FAST}) });

  p.add_trans_grp(["gsNeedle", "gsNeedle2"], "y-shift", {sensor: adc.add({function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0gsdef.val : adc.nav1gsdef.val }, timer:FAST}), scale: -65});
  p.add_cond_grp(["gsNeedle", "gsScale", "gsNeedle2", "gsScale2"], {sensor: adc.add({function: func { (adc.navsrc[i].val == "NAV1") ? adc.nav0gsinrange.val : adc.nav1gsinrange.val}, timer:SLOW}) }); 

  #p.add_trans("speedTrend", "y-scale", {sensor: adc.iasTrend, scale: 0.02, max: 40, min:-40});


  # lots of text
  # for nav aids to update
  # ============================
  
  # if FMS show "GPS" else show Nav frequency
  p.add_text("navFrq", {sensor: adc.add({ function: func navSrcFrq(adc.navsrc[i].val), timer:SLOW, type: "STRING"}) });
  p.add_cond("navFrq", {sensor: adc.navsrc[i], notequal: "FMS" });
  
  p.add_text("navID",  {sensor: adc.add({function: func navSrcId(adc.navsrc[i].val), timer:SLOW, type:"STRING" }) });
  p.add_text("navSrc", {sensor: adc.add({function: func navSrcType(adc.navsrc[i].val), timer:SLOW, type:"STRING" }) });
  p.add_text("crs", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:SLOW, type:"STRING"}), format: "%3.0f"});
  p.add_text("hdgNum", {sensor: adc.headbug, format: "%3.0f"});
  p.add_text("gsNum", {sensor: adc.gs, format: "%3.0f"});

  p.add_text("navDME", {sensor: adc.add( {function: func navSrcDist(adc.navsrc[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("navDME", {sensor: adc.add( {function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW, type: "BOOL"}) });
  p.add_cond("navGPS", {sensor: adc.navsrc[i], equals: "FMS" });
  p.add_text("navTTG", {sensor: adc.add( {function: func navSrcTTG(adc.navsrc[i].val), timer: SLOW}), format: "%i" });
  p.add_cond("navTTG", {sensor: adc.add( {function: func { (navSrcTTG(adc.navsrc[i].val)>1 and navSrcTTG(adc.navsrc[i].val)<300)}, type:"BOOL", timer:SLOW}) });

  p.add_text("bearingSrc1", {sensor: adc.add( {function: func navSrcType(adc.bearsrc0[i].val), timer: SLOW, type: "STRING" }) });
  p.add_text("bearingSrc2", {sensor: adc.add( {function: func navSrcType(adc.bearsrc1[i].val), timer: SLOW, type: "STRING" }) });

#  p.add_text("bearingFrq1", {sensor: adc.add( {function: func navSrcFrq(adc.bearsrc0[i].val), timer: SLOW, type: "STRING" }) });
#  p.add_text("bearingFrq2", {sensor: adc.add( {function: func navSrcFrq(adc.bearsrc1[i].val), timer: SLOW, type: "STRING" }) });

  p.add_text("bearingDME1", {sensor: adc.add( {function: func navSrcDist(adc.bearsrc0[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("bearingDME1", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc0[i].val), timer: SLOW}) });

  p.add_text("bearingDME2", {sensor: adc.add( {function: func navSrcDist(adc.bearsrc1[i].val), timer: SLOW, type: "STRING" }) });
  p.add_cond("bearingDME2", {sensor: adc.add( {function: func navSrcInrange(adc.bearsrc1[i].val), timer: SLOW }) });

  p.add_cond("Mrk_Group", {sensor: adc.ilsmarker });
  p.add_text("MrkLabel", {sensor: adc.add( {function: func { ( adc.ilsin.val ? "I" : (adc.ilsmid.val ? "M" : (adc.ilsout.val ? "O" : "" )))}, timer: SLOW, type: "STRING" }) });
  
  # /instrumentation/nav[0]/has-gs  --> navSrc VOR1/ILS1

  p.add_text("qnh", {sensor: adc.qnhDisplay });


  # AP annunciators text items
  # 
  # ============================

  p.add_text("altTarget", {sensor: adc.aptargetAlt, format: "%5.0f"});        
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


  # translate rose numerals in circular orbit
  # around center of compass rose
  # ============================

  GenerateRosenumerals(p, ROSER);
  
  Generatewindbarb(p);
  
}; # func 
