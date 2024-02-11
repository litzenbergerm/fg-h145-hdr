# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

# include some helper functions for the NAVD page if not already loaded
var ROSER=175;

# check if the function lib is already loaded
if (!defined("ROSENUMS"))
  io.include(HELIONIXPATH ~ "Nasal/fnd_func.nas");

adc["symfilter"] = Sensor.new({prop: datafltr});
  
page_setup["navd"] = func (i) {
  
  p = mfd[i].add_page("navd", HELIONIXPATH~"svg/navd.svg");

  # MFD top row button labels
  # ============================
  
  p.add_cond("fndBtn",  {offset: isin("fnd", mfd[i].pages) > -1 } );
  p.add_cond("vmdBtn",  {offset: isin("vmd", mfd[i].pages) > -1 } );
  p.add_cond("navdBtn", {offset: 0 } );
  p.add_cond("dmapBtn", {offset: isin("dmap", mfd[i].pages) > -1 } );
  p.add_cond("miscBtn", {offset: isin("misc", mfd[i].pages) > -1 } );
  p.add_cond("efbBtn", {offset: isin("efb", mfd[i].pages) > -1 } );

  # Rose transformations
  # Bearing Needles for NAV1 and NAV2
  # ============================

  p.add_trans("bear1Needle", "rotation", {sensor: adc.add({function: func navSrcBear(adc.bearsrc0[i].val), timer: FAST}) });
  p.add_cond("bear1Needle", {sensor: adc.add({function: func navSrcInrange(adc.bearsrc0[i].val), timer: SLOW}) });

  p.add_trans("bear2Needle", "rotation", {sensor: adc.add({function: func navSrcBear(adc.bearsrc1[i].val), timer: FAST}) });
  p.add_cond("bear2Needle", {sensor: adc.add({function: func navSrcInrange(adc.bearsrc1[i].val), timer: SLOW}) });

  # course and CDI 
  # ============================

  p.add_trans("hdgBug", "rotation", {sensor: adc.headbug});
  p.add_trans("Cdi_Group", "rotation", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:FAST}) });
  p.add_trans("Rose_Group", "rotation", {sensor: adc.heading, scale: -1});
  p.add_cond_grp(["cdiNeedle", "toFrom", "cdiScale"], {offset:0}); # CDI not used in NAVD 
  
  #p.add_trans("cdiNeedle", "x-shift", {function: func {return (adc.navsrc[i].val == "NAV1") ? adc.nav0defl.val : adc.nav1defl.val }, scale: 8, timer:FAST});
  #p.add_trans("toFrom", "rotation", {function: func {return (adc.navsrc[i].val == "NAV1") ? adc.nav0from.val : adc.nav1from.val }, scale: 180, timer:SLOW});

  # lots of text
  # for nav aids to update
  # ============================

  p.add_text("navSrctop", {sensor: adc.add({function: func navSrcType(adc.navsrc[i].val), timer:SLOW, type:"STRING" }) });
  p.add_text("navDMEtop", {sensor: adc.add({function: func navSrcDist(adc.navsrc[i].val), timer: SLOW, type:"STRING" }) });
  p.add_text("navIDtop", {sensor: adc.add({function: func navSrcId(adc.navsrc[i].val), timer: SLOW, type:"STRING"}) });
  p.add_text("navBrgtop", {sensor: adc.add({function: func navSrcBear(adc.navsrc[i].val), timer: SLOW}), format: "%3.0f°" });
  p.add_text("crs", {sensor: adc.add({function: func navSrcCrs(adc.navsrc[i].val), timer:SLOW }), format: "%3.0f" });
  p.add_text("rngNum", {sensor: adc.add({prop: rngprop }), format: "%3.0f" });
  
  p.add_cond_grp(["navDMEtop","navIDtop","navBrgtop"], {sensor: adc.add({function: func navSrcInrange(adc.navsrc[i].val), timer: SLOW}) });
  
  # FMS col
  
  p.add_text("navSrc", {offset: "FMS"}); 
  p.add_text("navBrg", {sensor: adc.add( {function: func navSrcBear("FMS"), timer:SLOW }), format: "%3.0f°" });
  p.add_text("fmsToID",  {sensor: adc.fmstoid }); # for FMS from nav ID
  p.add_text("fmsFromID", {sensor: adc.fmsfromid  }); # for FMS to nav ID                       
  p.add_text("navTTG", {sensor: adc.fmsttg, scale: 1/60, format: "%i min"});
  p.add_cond("navTTG", {sensor: adc.fmsttg, between: [60,10000] });
  
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

  p.add_text("bearingTTG1", {sensor: adc.nav0ttg, scale: 1/60, format: "%i min" });
  p.add_text("bearingTTG2", {sensor: adc.nav1ttg, scale: 1/60, format: "%i min" });
  p.add_cond("bearingTTG1", {sensor: adc.nav0ttg, between: [60, 10000]});
  p.add_cond("bearingTTG2", {sensor: adc.nav1ttg, between: [60, 10000]});

  p.add_cond("txtNav", {sensor: adc.symfilter, equals: 1 });
  p.add_cond("txtAirp", {sensor: adc.symfilter, equals: 3 });
  p.add_cond("txtRte", {sensor: adc.symfilter, equals: 2 });

  p.add_text("bearing1", {sensor: adc.nav0bear, format: "%3.0f°"});
  p.add_text("brg1Id1", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc0[i].val ),0,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg1Id2", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc0[i].val ),1,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg1Id3", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc0[i].val ),2,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg1Id4", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc0[i].val ),3,1), timer:SLOW, type:"STRING"}) });
  
  p.add_text("bearing2", {sensor: adc.nav1bear, format: "%3.0f°"});
  p.add_text("brg2Id1", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc1[i].val ),0,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg2Id2", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc1[i].val ),1,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg2Id3", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc1[i].val ),2,1), timer:SLOW, type:"STRING"}) });
  p.add_text("brg2Id4", {sensor: adc.add({function: func substr(navSrcType( adc.bearsrc1[i].val ),3,1), timer:SLOW, type:"STRING"}) });
  
  # /instrumentation/nav[0]/has-gs  --> navSrc VOR1/ILS1
  #p.add_cond("navETE", {offset:0}); # hide ETE
  
  # GPS
  # 
  # ======================================
  
  p.add_text("gpsLatNum", {sensor: adc.gpslat, trunc:"abs", format: "%8.4f°"});
  p.add_text("gpsLonNum", {sensor: adc.gpslon, trunc:"abs", format: "%08.4f°"});
  p.add_text("gpsLat", {sensor: adc.gpsLatNS});
  p.add_text("gpsLon", {sensor: adc.gpsLonWE});

  # translate rose numerals in round orbit
  # around center of compass rose
  # ======================================

  GenerateRosenumerals(p, ROSER);

  Generatewindbarb(p);

  # setup the navigation symbols
  # animations
  # ======================================
  for (var sym=0; sym<20; sym += 1) {
      adc["navsym_id"~sym] = Sensor.new({prop: mfdroot~"navd/sym[" ~ sym ~ "]/id", "type": "STRING" } );      
      adc["navsym_sym"~sym] = Sensor.new({prop: mfdroot ~ "navd/sym[" ~ sym ~ "]/sym", "timer": SLOW });
      adc["navsym_dst"~sym] = Sensor.new({prop: mfdroot ~ "navd/sym[" ~ sym ~ "]/distance-norm" });
      adc["navsym_brg"~sym] = Sensor.new({prop: mfdroot ~ "navd/sym[" ~ sym ~ "]/rel-bearing" });      
  };
  
  for (var sym=0; sym<20; sym += 1) {
      
      var thissym = "symbol_"~sym;
      p.copy_element("symbol","_"~sym);
      p[thissym].show();
      
      p.add_trans(thissym, "rotation", {sensor: adc.add({prop: mfdroot~"navd/sym[" ~ sym ~ "]/rel-bearing" }), scale:-1 });
      p.add_trans(thissym, "y-shift", {sensor: adc.add( {prop: mfdroot~"navd/sym[" ~ sym ~ "]/distance-norm"}), scale: -330/2 });
      p.add_trans(thissym, "rotation", {sensor: adc.add({prop: mfdroot~"navd/sym[" ~ sym ~ "]/rel-bearing" }) });
      
      p.add_by_id("symbol_vor_"~sym);
      p.add_by_id("symbol_wayp_"~sym);
      p.add_by_id("symbol_ndb_"~sym);
      p.add_by_id("symbol_airp_"~sym);
      p.add_by_id("symbol_nextwayp_"~sym);
      p.add_by_id("symbol_fix_"~sym);
      
      # use only a single callback function for all nav symbol types to reduce 
      # callback overhead. pass the page object and the symbol number
      
      adc["navsym_sym"~sym]._register_( 
                {o: p, 
                  c: sym, 
                  f: func(x,c) {
                        if (adc["navsym_sym"~c].val > -1) {
                          x["symbol_"~c].setVisible(1); 
                          x["symbol_vor_"~c].setVisible( adc["navsym_sym"~c].val == 0 ); 
                          x["symbol_wayp_"~c].setVisible( adc["navsym_sym"~c].val == 1 ); 
                          x["symbol_ndb_"~c].setVisible( adc["navsym_sym"~c].val == 2 ); 
                          x["symbol_airp_"~c].setVisible( adc["navsym_sym"~c].val == 3 ); 
                          x["symbol_nextwayp_"~c].setVisible( adc["navsym_sym"~c].val == 4 ); 
                          x["symbol_fix_"~c].setVisible( adc["navsym_sym"~c].val == 6 ); 
                        } else {
                          x["symbol_"~c].setVisible(0); 
                        }                          
                    }
                  },
                  p
      );
      
      p.add_text("symbol_id_"~sym, {sensor: adc["navsym_id"~sym] });
  }               

  # hide the template symbol
  p["symbol"].hide();
  
}; # func 
