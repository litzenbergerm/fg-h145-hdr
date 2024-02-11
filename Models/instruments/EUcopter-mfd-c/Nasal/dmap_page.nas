# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# include some helper functions for the NAVD page if not already loaded
var ROSER=165;

# check if the function lib is already loaded
if (!defined("FND_FUNC_LOADED"))
  io.include(HELIONIXPATH ~ "Nasal/fnd_func.nas");

page_setup["dmap"] = func (i) {
  
  p = mfd[i].add_page("dmap", HELIONIXPATH~"svg/dmap.svg");
  
  # MFD top row button labels
  # ============================
  
  p.add_cond("fndBtn",  {offset: isin("fnd", mfd[i].pages) > -1 } );
  p.add_cond("vmdBtn",  {offset: isin("vmd", mfd[i].pages) > -1 } );
  p.add_cond("navdBtn", {offset: isin("navd", mfd[i].pages) > -1 } );
  p.add_cond("dmapBtn", {offset: 0 } );
  p.add_cond("miscBtn", {offset: isin("misc", mfd[i].pages) > -1 } );
  p.add_cond("efbBtn", {offset: isin("efb", mfd[i].pages) > -1 } );
  
  # lots of text
  # for nav aids to update
  # ============================

  p.add_text("navSrctop", {sensor: adc.add({function: func navSrcType(adc.navsrc[i].val), timer:SLOW, type:"STRING" }) });
  p.add_text("navDMEtop", {sensor: adc.add({function: func navSrcDist(adc.navsrc[i].val), timer: SLOW, type:"STRING" }) });
  p.add_text("navIDtop", {sensor: adc.add({function: func navSrcId(adc.navsrc[i].val), timer: SLOW, type:"STRING"}) });
  p.add_text("navBrgtop", {sensor: adc.add({function: func navSrcBear(adc.navsrc[i].val), timer: SLOW}), format: "%3.0f°" });
  p.add_text("crs", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:SLOW }), format: "%3.0f" });
  #p.add_text("rngNum", {sensor: adc.add({prop: rngprop }), format: "%3.0f" });
  
  p.add_cond_grp(["navDMEtop","navIDtop","navBrgtop"], {sensor: adc.add({function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW}) });
  
  # FMS col
  
  p.add_text("navSrc", {offset: "FMS"}); 
  p.add_text("navBrg", {sensor: adc.add( {function: func navSrcBear("FMS"), timer:SLOW }), format: "%3.0f°" });
  p.add_text("fmsToID",  {sensor: adc.fmstoid }); # for FMS from nav ID
  p.add_text("fmsFromID", {sensor: adc.fmsfromid  }); # for FMS to nav ID                       
  p.add_text("navTTG", {sensor: adc.fmsttg, scale: 1/60, format: "%i MIN"});
  p.add_cond("navTTG", {sensor: adc.fmsttg , between: [60, 10000]});
  
  p.add_text("navDME", {sensor: adc.add( {function: func navSrcDist("FMS"), timer: SLOW, type:"STRING" }) });
  p.add_cond("navDME", {sensor: adc.add( {function: func navSrcInrange("FMS"), timer: SLOW, type:"BOOL"}) });
  
  p.add_text("gsNum", {sensor: adc.gs, format: "%3.0i"});
  p.add_text("tasNum", {sensor: adc.tas, format: "%3.0i"});
  
  # NAV1 and NAV2 cols

  p.add_text("bearingSrc1", {sensor: adc.add( {function: func navSrcType("NAV1"), timer:SLOW, type:"STRING"}) });
  p.add_text("bearingSrc2", {sensor: adc.add( {function: func navSrcType("NAV2"), timer:SLOW, type:"STRING"}) });
  p.add_text("bearingFrq1", {sensor: adc.add( {function: func navSrcFrq("NAV1"), timer: SLOW, type:"STRING"}) });
  p.add_text("bearingFrq2", {sensor: adc.add( {function: func navSrcFrq("NAV2"), timer: SLOW, type:"STRING"}) });

  p.add_text("bearingDME1", {sensor: adc.add( {function: func DME_format(adc.nav0dist.val), timer: SLOW, type:"STRING"}) });
  p.add_cond("bearingDME1", {sensor: adc.nav0inrange });

  p.add_text("bearingDME2", {sensor: adc.add( {function: func DME_format(adc.nav1dist.val), timer: SLOW, type:"STRING"}) });
  p.add_cond("bearingDME2", {sensor: adc.nav1inrange });

  p.add_text("bearingTTG1", {sensor: adc.nav0ttg, scale: 1/60, format: "%i MIN" });
  p.add_text("bearingTTG2", {sensor: adc.nav1ttg, scale: 1/60, format: "%i MIN" });
  p.add_cond("bearingTTG1", {sensor: adc.nav0ttg, between: [60, 10000]});
  p.add_cond("bearingTTG2", {sensor: adc.nav1ttg, between: [60, 10000]});

  p.add_text("bearing1", {sensor: adc.nav0bear, format: "%3.0f°"});
  p.add_text("bearing2", {sensor: adc.nav1bear, format: "%3.0f°"});
  
  # /instrumentation/nav[0]/has-gs  --> navSrc VOR1/ILS1
  #p.add_cond("navETE", {offset:0}); # hide ETE
  
  # GPS
  # 
  # ======================================
  
  p.add_text("gpsLatNum", {sensor: adc.gpslat, trunc:"abs", format: "%8.4f°"});
  p.add_text("gpsLonNum", {sensor: adc.gpslon, trunc:"abs", format: "%08.4f°"});
  p.add_text("gpsLat", {sensor: adc.gpsLatNS});
  p.add_text("gpsLon", {sensor: adc.gpsLonWE});

  Generatewindbarb(p, s = "winddir");
  
}; # func 
