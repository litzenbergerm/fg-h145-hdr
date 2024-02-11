# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

vmd_display = canvas.new({
        "name": "VMD",
        "size": [1024, 1024],
        "view": [1050, 1000],
        "mipmapping": 1
});

var group = vmd_display.createGroup();
vmd_canvas = canvas_MFD.new(group, helionixpath ~ "svg/vmd.svg");

var DMEFACTOR = 0.0005399;
var ALTFACTOR = (651-464)/400;  
var FPS2FPM = 60;

var SHIFT_THRES = 0.5;
var ROT_THRES = 0.1;    

# fuel indicators 
# and rotor and eng rmp
# ============================

vmd_canvas.add_trans("fuelTotal", "y-scale", {"sensor": adc.tank0 });
vmd_canvas.add_trans("fuelL", "y-scale", {"sensor": adc.tank1 });
vmd_canvas.add_trans("fuelR", "y-scale", {"sensor": adc.tank2 });

vmd_canvas.add_text("fuelNum", {"sensor": adc.tank0lbs, "scale": LB2KG, "format": "%3.0f" });
vmd_canvas.add_text("fuelNum1", {"sensor": adc.tank1lbs, "scale": LB2KG, "format": "%3.0f" });
vmd_canvas.add_text("fuelNum2", {"sensor": adc.tank2lbs, "scale": LB2KG, "format": "%3.0f" });
vmd_canvas.add_text("fuelFlowL", {"sensor": adc.ff_1, "scale": LB2KG, "format": "%3.0f" });
vmd_canvas.add_text("fuelFlowR", {"sensor": adc.ff_2, "scale": LB2KG, "format": "%3.0f" });
vmd_canvas.add_text("Text2", {"sensor": adc.grossweight, "scale": LB2KG, "format": "%4.0f Kg" });

#Fuel endurance time
vmd_canvas.add_text("enduH", {"sensor": adc.endurance, "scale": 1/3600, "trunc":1, "format": "%1i h" });
vmd_canvas.add_text("enduMin", {"sensor": adc.endurance, "scale": 1/60, "mod":3600, "format": "%2i min" });

#Engine Idle and Fail
vmd_canvas.add_cond("failL", {"function": func {return (adc.n1_1.get() or 0) < 50;}, "disable_listener": SLOW });
vmd_canvas.add_cond("idleL", {"function": func {return (adc.n1_1.get() or 0) > 50 and (adc.n1_1.get() or 0) < 65;}, "disable_listener": SLOW });
vmd_canvas.add_cond("failR", {"function": func {return (adc.n1_2.get() or 0) < 50;}, "disable_listener": SLOW });
vmd_canvas.add_cond("idleR", {"function": func {return (adc.n1_2.get() or 0) > 50 and (adc.n1_2.get() or 0) < 65;}, "disable_listener": SLOW });

vmd_canvas.copy_element("gauge_0","_1",[450,0]);
vmd_canvas.copy_element("gauge_0","_2",[130,45]);
vmd_canvas.copy_element("gauge_0","_3",[305,45]);

# Engines TOT Gauges
make_Gauge (
     adc.tot_1, 
     id="",
     _min=100,
     _max=900,
     name="TOT",
);

make_Gauge (
     adc.tot_2, 
     id="_1",
     _min=100,
     _max=900,
     name="TOT",
);

# Engine 1 N1 Gauge
make_Gauge (
     adc.n1_1, 
     id="_2",
     _min=75,
     _max=115,
     name="N1",
);

# Engine 2 N1 Gauge
make_Gauge (
     adc.n1_2, 
     id="_3",
     _min=75,
     _max=115,
     name="N1",
);

vmd_canvas.copy_element("TGauge_0","_1",[190,0]);

# Engine 1 TRQ Gauge
make_TGauge (
     adc.trq_1, 
     id="",
     _min=0,
     _max=125,
     name="TRQ",
);

make_TGauge (
     adc.trq_2, 
     id="_1",
     _min=0,
     _max=125,
     name="TRQ",
);

# look-up-table nr_lut is defined in airdata
vmd_canvas.add_trans("NRgaugeNeedle", "rotation", {"function": func {return adc.nr_lut.get( (adc.nr.get() or 0) )} });
vmd_canvas.add_trans("n2_1Needle", "rotation", {"function": func {return adc.nr_lut.get( adc.n2_1.get() )} });
vmd_canvas.add_trans("n2_2Needle", "rotation", {"function": func {return adc.nr_lut.get( adc.n2_2.get() )} });

vmd_canvas.add_cond("NRgaugeCover1", {"function": func {return (adc.nr.get() or 0) < 80;}  });
vmd_canvas.add_cond("NRgaugeCover2", {"function": func {return (adc.nr.get() or 0) > 85;}  });

vmd_canvas.copy_element("LinGauge_0","_1",[150,0]);
vmd_canvas.copy_element("LinGauge_0","_2",[305,0]);

make_LinGauge (
     adc.oil_t1, 
     adc.oil_p1, 
     id="",
     _min1=-40,
     _max1=140,
     fmt1="%3.0f",
     unit1="°C",
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
     id="_1",
     _min1=-40,
     _max1=140,
     fmt1="%3.0f",
     unit1="°C",
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
     nil, 
     adc.mgb_p, 
     id="_2",
     _min1=0,
     _max1=8,
     fmt1="",
     unit1="",
     _min2=0,
     _max2=10,
     fmt2="%3.1f",     
     unit2="BAR",
     name="MGB OIL",
     l1=nil,
     h1=nil,
     l2=1.7,
     h2=5  
     );

vmd_canvas.copy_element("numeral","_1",[450,0]);
vmd_canvas.copy_element("numeral","_2",[130,45]);
vmd_canvas.copy_element("numeral","_3",[305,45]);

make_numeral (
     adc.tot_1, 
     id="",
     dec=0,
     unit=" °C",
     _amber=845,
     _red=900
);

make_numeral (
     adc.tot_2, 
     id="_1",
     dec=0,
     unit=" °C",
     _amber=845,
     _red=900
);

make_numeral (
     adc.n1_1, 
     id="_2",
     dec=1,
     unit=" %%",
     _amber=95,
     _red=104
);

make_numeral (
     adc.n1_2, 
     id="_3",
     dec=1,
     unit=" %%",
     _amber=95,
     _red=104
);

vmd_canvas.copy_element("numeral","_4",[140,-80]);
vmd_canvas.copy_element("numeral","_5",[140+190,-80]);

make_numeral (
     adc.trq_1, 
     id="_4",
     dec=1,
     unit=" %%",
     _amber=74,
     _red=95
);

make_numeral (
     adc.trq_2, 
     id="_5",
     dec=1,
     unit=" %%",
     _amber=74,
     _red=95
);

vmd_canvas.copy_element("numeral","_6",[461-81,609-183]);

make_numeral (
     adc.nr, 
     id="_6",
     dec=1,
     unit=""
);

vmd_canvas.copy_element("numeral","_7",[461-81-70,609-183+107]);
vmd_canvas.copy_element("numeral","_8",[461-81+50,609-183+107]);

make_numeral (
     adc.n2_1, 
     id="_7",
     dec=1,
     unit=" %%",
     _amber=-96,
     _red=-85
);

make_numeral (
     adc.n2_2, 
     id="_8",
     dec=1,
     unit=" %%",
     _amber=-96,
     _red=-85
);

vmd_canvas.newMFD();