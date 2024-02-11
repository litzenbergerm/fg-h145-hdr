# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

var p=nil;

adc["battsym"] = Sensor.new({prop: "/instrumentation/efis/vmd/battery-symbol-color"});
adc["gen1sym"] = Sensor.new({prop: "/instrumentation/efis/vmd/gen1-symbol-color"});
adc["gen2sym"] = Sensor.new({prop: "/instrumentation/efis/vmd/gen2-symbol-color"});
adc["eng1sym"] = Sensor.new({prop: "/instrumentation/efis/vmd/eng1-symbol-color"});
adc["eng2sym"] = Sensor.new({prop: "/instrumentation/efis/vmd/eng2-symbol-color"});
adc["trainsw"] = Sensor.new({prop: "/controls/switches/ecp/trainswitch"});


adc["eng1stat"] = Sensor.new({function: 
             func { if ( adc.eng1sym.val == 2) return "FAIL"; 
                    if ( adc.eng1sym.val == 1 and adc.n1_1.val>50) 
                       return "IDLE"; 
                       else return "START";},
              timer: SLOW, type: "STRING" });

adc["eng2stat"] = Sensor.new({function: 
             func { if ( adc.eng2sym.val == 2) return "FAIL"; 
                    if ( adc.eng2sym.val == 1 and adc.n1_2.val>50) 
                       return "IDLE"; 
                       else return "START";},
              timer: SLOW, type: "STRING" });

# include some helper functions for the VMD page
if (!defined("VMD_FUNC_LOADED"))
  io.include(HELIONIXPATH ~ "Nasal/vmd_func.nas");


page_setup["vmd"] = func (i) {
  
  p = mfd[i].add_page("vmd", HELIONIXPATH~"svg/vmd.svg");

  var DMEFACTOR = 0.0005399;
  var ALTFACTOR = (651-464)/400;  
  var FPS2FPM = 60;
  var SHIFT_THRES = 0.5;
  var ROT_THRES = 0.1;    

  # MFD top row button labels
  # ============================
  
  p.add_cond("fndBtn",  {offset: isin("fnd", mfd[i].pages) > -1 } );
  p.add_cond("vmdBtn",  {offset: 0 } );
  p.add_cond("navdBtn", {offset: isin("navd", mfd[i].pages) > -1 } );
  p.add_cond("dmapBtn", {offset: isin("dmap", mfd[i].pages) > -1 } );
  p.add_cond("miscBtn", {offset: isin("misc", mfd[i].pages) > -1 } );
  p.add_cond("efbBtn", {offset: isin("efb", mfd[i].pages) > -1 } );
  
  # fuel indicators 
  # and rotor and eng rmp
  # ============================

  p.add_trans("fuelTotal", "y-scale", {sensor: adc.tank0 });
  p.add_trans("fuelL", "y-scale", {sensor: adc.tank1 });
  p.add_trans("fuelR", "y-scale", {sensor: adc.tank2 });

  p.add_text("fuelNum", {sensor: adc.tank0lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelNum1", {sensor: adc.tank1lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelNum2", {sensor: adc.tank2lbs, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelFlowL", {sensor: adc.ff_1, scale: LB2KG, format: "%3.0f" });
  p.add_text("fuelFlowR", {sensor: adc.ff_2, scale: LB2KG, format: "%3.0f" });
  p.add_text("Text2", {sensor: adc.grossweight, scale: LB2KG, format: "%4.0f Kg" });
  
  p.add_text("Text3", {offset: "" });
  p.add_text("Text4", {offset: "" });
  p.add_text("Text5", {offset: "" });
  p.add_text("Text6", {offset: "" });

  #Fuel endurance time
  p.add_text("enduH", {sensor: adc.endurance, scale: 1/3600, "trunc":1, format: "%1i h" });
  p.add_text("enduMin", {sensor: adc.endurance, scale: 1/60, "mod":3600, format: "%02i" });


  p.add_cond("trainSym", {sensor: adc.trainsw });
  p.add_cond("num_grp", {sensor: adc.vmdnum });
  
  p.add_text("GenVoltL", {sensor: adc.elecBus0, format: "%4.1f V" });
  p.add_text("GenVoltR", {sensor: adc.elecBus1, format: "%4.1f V" });
  p.add_text("GenAmpL", {sensor: adc.elecAlt0, format: "%3.0f A" });
  p.add_text("GenAmpR", {sensor: adc.elecAlt1, format: "%3.0f A" });
  p.add_text("BattAmp", {sensor: adc.add( {function: func {
              if (adc.batteryload.val > 0) 
                  return adc.batteryload.val; 
              else 
                  return adc.batterycharge.val;
              }, 
              timer: SLOW
    }), 
    format: "%3.0f A", 
    name: "batt" 
  });

  p.copy_element("gauge_0","_1",[450,0]);
  p.copy_element("gauge_0","_2",[130,45]);
  p.copy_element("gauge_0","_3",[305,45]);

  # Engines TOT Gauges
  make_Gauge (
      adc.tot_1, 
      _id="",
      _min=100,
      _max=900,
      name="TOT",
  );

  make_Gauge (
      adc.tot_2, 
      _id="_1",
      _min=100,
      _max=900,
      name="TOT",
  );

  # Engine 1 N1 Gauge
  make_Gauge (
      adc.n1_1, 
      _id="_2",
      _min=75,
      _max=115,
      name="N1",
  );

  # Engine 2 N1 Gauge
  make_Gauge (
      adc.n1_2, 
      _id="_3",
      _min=75,
      _max=115,
      name="N1",
  );

  p.copy_element("TGauge_0","_1",[190,0]);

  # Engine 1 TRQ Gauge
  make_TGauge (
      adc.trq_1, 
      _id="",
      _min=0,
      _max=125,
      name="TRQ",
  );

  make_TGauge (
      adc.trq_2, 
      _id="_1",
      _min=0,
      _max=125,
      name="TRQ",
  );

  # look-up-table nr_lut is defined in airdata
  p.add_trans("NRgaugeNeedle", "rotation", {sensor: adc.add( {function: func adc.nr_lut.get((adc.nr.val or 0)) }) });
  p.add_trans("n2_1Needle", "rotation", {sensor: adc.add( {function: func adc.nr_lut.get( adc.n2_1.val ) }) });
  p.add_trans("n2_2Needle", "rotation", {sensor: adc.add( {function: func adc.nr_lut.get( adc.n2_2.val ) }) });

  p.add_cond("NRgaugeCover1", {sensor: adc.nr, lessthan: 80});
  p.add_cond("NRgaugeCover2", {sensor: adc.nr, greaterthan: 85 });

  p.copy_element("LinGauge_0","_1",[150,0]);
  p.copy_element("LinGauge_0","_2",[305,0]);
  p.copy_element("LinGauge_0","_3",[-125,0]);
  
  
      
  make_LinGauge (
      adc.oil_t1, 
      adc.oil_p1, 
      _id="",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="gC",
      _min2=0,
      _max2=8.0,
      fmt2="%3.1f",     
      unit2="BAR",
      name="ENG OIL",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5  
      );

  make_LinGauge (
      adc.oil_t2, 
      adc.oil_p2, 
      _id="_1",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="gC",
      _min2=0,
      _max2=8.0,
      fmt2="%3.1f",     
      unit2="BAR",
      name="ENG OIL",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5  
      );

  make_LinGauge (
      adc.mgb_t, 
      adc.mgb_p, 
      _id="_2",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="gC",
      _min2=0,
      _max2=10,
      fmt2="%3.1f",     
      unit2="BAR",
      name="MGB OIL",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5  
      );

  make_LinGauge (
      adc.hydr1, 
      adc.hydr2, 
      _id="_3",
      _min1=0,
      _max1=140,
      fmt1="%3.0f",
      unit1="BAR",
      _min2=0,
      _max2=140,
      fmt2="%3.0f",     
      unit2="BAR",
      name="HYD",
      l1=70,
      h1=120,
      l2=70,
      h2=120  
      );
      
      
  p.copy_element("numeral","_1",[450,0]);
  p.copy_element("numeral","_2",[130,45]);
  p.copy_element("numeral","_3",[305,45]);

  make_numeral (
      adc.tot_1, 
      _id="",
      dec=0,
      unit="°C",
      _amber=845,
      _red=900
  );

  make_numeral (
      adc.tot_2, 
      _id="_1",
      dec=0,
      unit="°C",
      _amber=845,
      _red=900
  );

  make_numeral (
      adc.n1_1, 
      _id="_2",
      dec=1,
      unit="%",
      _amber=95,
      _red=104
  );

  make_numeral (
      adc.n1_2, 
      _id="_3",
      dec=1,
      unit="%",
      _amber=95,
      _red=104
  );

  p.copy_element("numeral","_4",[150,-80]);
  p.copy_element("numeral","_5",[150+190,-80]);

  make_numeral (
      adc.trq_1, 
      _id="_4",
      dec=1,
      unit="%",
      _amber=74,
      _red=95
  );

  make_numeral (
      adc.trq_2, 
      _id="_5",
      dec=1,
      unit="%",
      _amber=74,
      _red=95
  );

  p.copy_element("numeral","_6",[461-55,609-183]);

  make_numeral (
      adc.nr, 
      _id="_6",
      dec=1,
      unit=""
  );

  p.copy_element("numeral","_7",[400-77, 609-183+107]);
  p.copy_element("numeral","_8",[400+57, 609-183+107]);

  make_numeral (
      adc.n2_1, 
      _id="_7",
      dec=1,
      unit="%",
      _amber=-96,
      _red=-85
  );

  make_numeral (
      adc.n2_2, 
      _id="_8",
      dec=1,
      unit="%",
      _amber=-96,
      _red=-85
  );
  
  # battery symbology red: overheat, green:connected, amber: disconnected
                  
  p.add_color_range("battSymb", adc.battsym,
                  [
                    [0,  [0,1,0]],
                    [1,  [1,0.75,0]],
                    [2,  [1,0,0]]
                  ]
  );
  
  # batt Amp indication color, hidden if connected
  
  p.add_color_range("BattAmpC", adc.battsym, 
                  [
                    [0,  [0,0,0]],
                    [1,  [0.5,0.35,0]],
                    [2,  [1,0,0]]
                  ]
  , fill=1);
  
  # generator symbology green:connected, amber: disconnected&eng runn. , gray:disconnected&eng off 
  
  var gensym =  [
                    [0,  [0,1,0]],
                    [1,  [0.6,0.6,0.6]],
                    [2,  [1,0.75,0]]
                  ];
                  
  p.add_color_range("gen1Symb", adc.gen1sym, gensym);
  p.add_color_range("gen2Symb", adc.gen2sym, gensym);
  
  var gensym2 =  [
                    [0,  [0,0,0]],
                    [1,  [0.6,0.6,0.6]],
                    [2,  [0.5,0.35,0]]
                  ];
                  
  p.add_color_range("genAmpLc", adc.gen1sym, gensym2, fill=1);
  p.add_color_range("genAmpRc", adc.gen2sym, gensym2, fill=1);
  
  var engsym =  [
                    [0,  [0,0,0]],
                    [1,  [1,0.75,0]],
                    [2,  [1,0,0]]
                  ];
                  
  p.add_color_range("statusL", adc.eng1sym, engsym);
  p.add_color_range("statusR", adc.eng2sym, engsym);

  p.add_text("txtStatusR", {sensor: adc.eng2stat });
  p.add_text("txtStatusL", {sensor: adc.eng1stat });
  
}; # func
