# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

var p=nil;

# include some helper functions for the VMD page
io.include(HELIONIXPATH ~ "Nasal/vmd_func.nas");

adc["fli0"] = Sensor.new({prop: "instrumentation/VEMD/FLI[0]/fli", timer: FAST, thres:0.01 });
adc["fli1"] = Sensor.new({prop: "instrumentation/VEMD/FLI[1]/fli", timer: FAST, thres:0.01 });
adc["fli0limit"] = Sensor.new({prop: "instrumentation/VEMD/FLI[0]/limit", timer: SLOW, type: "STRING"});
adc["fli1limit"] = Sensor.new({prop: "instrumentation/VEMD/FLI[1]/limit", timer: SLOW, type: "STRING"});

if (!contains(adc, "blink")) {    
    var CBARS = props.globals.getNode("instrumentation/efis/cad/cautionbars", 1); 
    var cbartimer = maketimer(0.75, func CBARS.setValue(!CBARS.getValue()) );
    cbartimer.start(); 
    adc["blink"] = Sensor.new({ prop: CBARS.getPath() });
}

page_setup["vemd"] = func (i) {
  
  p = mfd[i].add_page("vemd", HELIONIXPATH~"svg/vemd.svg");

  var DMEFACTOR = 0.0005399;
  var ALTFACTOR = (651-464)/400;  
  var FPS2FPM = 60;
  var SHIFT_THRES = 0.5;
  var ROT_THRES = 0.1;    

  # 
  # rotor and eng rmp
  # ============================

  p.add_text("trq1Num", {sensor: adc.trq_1, format: "%5.1f" });
  p.add_text("trq2Num", {sensor: adc.trq_2, format: "%5.1f" });
  p.add_text("tot1Num", {sensor: adc.tot_1, format: "%3.0f" });
  p.add_text("tot2Num", {sensor: adc.tot_2, format: "%3.0f" });
  p.add_text("n1-1Num", {sensor: adc.n1_1, format: "%5.1f" });
  p.add_text("n1-2Num", {sensor: adc.n1_2, format: "%5.1f" });

  # blinking eng. start annunciator
  p.add_cond("start1", {sensor: adc.add( {function: func { adc.start1.val > 0.01 and adc.blink.val==1 }}) });
  p.add_cond("start2", {sensor: adc.add( {function: func { adc.start2.val > 0.01 and adc.blink.val==1 }}) });
             
  p.add_cond("fail1", {sensor: adc.n1_1, lessthan: 50 });
  p.add_cond("fail2", {sensor: adc.n1_2, lessthan: 50 });

  # FLI Needles value 10 = 150 deg
  p.add_trans("fli1", "rotation", {sensor: adc.fli0, scale: 15.0, offset: -150.0 });
  p.add_trans("fli2", "rotation", {sensor: adc.fli1, scale: 15.0, offset: -150.0 });
  
  # FLI Limit indicators
  p.add_cond("trq1Lim", {sensor: adc.fli0limit, "equals": "TRQ" });
  p.add_cond("trq2Lim", {sensor: adc.fli1limit, "equals": "TRQ" });
  p.add_cond("tot1Lim", {sensor: adc.fli0limit, "equals": "TOT" });
  p.add_cond("tot2Lim", {sensor: adc.fli1limit, "equals": "TOT" });
  p.add_cond("n1_1Lim", {sensor: adc.fli0limit, "equals": "N1" });
  p.add_cond("n1_2Lim", {sensor: adc.fli1limit, "equals": "N1" });

  p.add_text("OAT", {sensor: adc.oat, format: "%4.1f" });

  p.add_text("GenVoltL", {sensor: adc.elecBus0, format: "%4.1f" });
  p.add_text("GenVoltR", {sensor: adc.elecBus1, format: "%4.1f" });
  
  #p.add_text("GenAmpL", {sensor: adc.elecAlt0, format: "%3.0f A" });
  #p.add_text("GenAmpR", {sensor: adc.elecAlt1, format: "%3.0f A" });
  #p.add_text("BattAmp", {sensor: adc.add( {function: func {
              #if (adc.batteryload.val > 0) 
                  #return adc.batteryload.val; 
              #else 
                  #return adc.batterycharge.val;
              #}, 
              #timer: SLOW
    #}), 
    #format: "%3.0f A", 
    #name: "batt" 
  #});


  p.copy_element("LinGauge_0","_1",[400,0]);
  p.copy_element("LinGauge_0","_2",[200,0]);

  make_LinGauge (
      adc.oil_t1, 
      adc.oil_p1, 
      _id="",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="°C",
      _min2=0,
      _max2=8.0,
      fmt2="%3.1f",     
      unit2="BAR",
      name="ENGOIL 1",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5,  
      _size=88
      );

  make_LinGauge (
      adc.oil_t2, 
      adc.oil_p2, 
      _id="_1",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="°C",
      _min2=0,
      _max2=8.0,
      fmt2="%3.1f",     
      unit2="BAR",
      name="ENGOIL 2",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5,  
      _size=88
      );

  make_LinGauge (
      adc.mgb_t, 
      adc.mgb_p, 
      _id="_2",
      _min1=-40,
      _max1=140,
      fmt1="%3.0f",
      unit1="°C",
      _min2=0,
      _max2=10,
      fmt2="%3.1f",     
      unit2="BAR",
      name="XMSNOIL",
      l1=0,
      h1=100,
      l2=1.7,
      h2=5,  
      _size=88  
      );
  
  # add the color ranges animation for changing VEMD caution and warning indicators
  # only 3 ranges are possible below minimum, nominal, above maximum
  
  var n1limits =  [
                    [60,  [1,1,0]],
                    [nil, [0,0,0]],
                    [95,  [1,0,0]]
                  ];
  p.add_color_range("n1_1Warn", adc.n1_1, n1limits);
  p.add_color_range("n1_2Warn", adc.n1_2, n1limits);

  var trqlimits =  [
                    [78,  [0,0,0]],
                    [nil, [1,1,0]],
                    [95,  [1,0,0]]
                  ];
  p.add_color_range("trq1Warn", adc.trq_1, trqlimits);
  p.add_color_range("trq2Warn", adc.trq_2, trqlimits);
  
  var totlimits =  [
                    [900,  [0,0,0]],
                    [nil,  [1,1,0]],
                    [1000, [1,0,0]]
                  ];
  p.add_color_range("tot1Warn", adc.tot_1, totlimits);
  p.add_color_range("tot2Warn", adc.tot_2, totlimits);
  
}; # func