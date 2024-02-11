# define some helper functions
# for VMD display
# ============================


var make_numeral = func( 
     sensor, 
     id=nil,
     dec=1,
     unit=" %%",
     _amber = nil,
     _red = nil) 
     {
     var fmt1 = (dec) ? "%3i." : "%3i";
     var fmt2 = (dec) ? "%1i"~unit : unit;
       
     vmd_canvas.add_text("numTen"~id, {"sensor": sensor, "format": fmt1, "min":0, "trunc":1});
     if (dec)
       vmd_canvas.add_text("numDec"~id,{"sensor": sensor, "format": fmt2, "mod":1.0, "scale":10, "min":0, "max":0.9} );
     else
       vmd_canvas.add_text("numDec"~id,{"offset": fmt2});
     
     if (_amber == nil) {
      vmd_canvas.add_cond("numAmber"~id, {"offset": 0});
     } else {
       if (_amber > 0)
          vmd_canvas.add_cond("numAmber"~id, {"function": func {sensor.get() > _amber}});
       else
         vmd_canvas.add_cond("numAmber"~id, {"function": func {sensor.get() < -_amber}});
    }
     
    if (_red == nil) {
      vmd_canvas.add_cond("numRed"~id, {"offset": 0});
     } else {
       if (_red > 0)
          vmd_canvas.add_cond("numRed"~id, {"function": func {sensor.get() > _red}});
       else
         vmd_canvas.add_cond("numRed"~id, {"function": func {sensor.get() < -_red}});
    }
};

var make_Gauge = func (
     sensor, 
     id=nil,
     _min=0,
     _max=100,
     name="N1")
     {
     var r = 180/(_max-_min);
     vmd_canvas.add_text("gaugeTitle"~id, {"offset": name});     
     vmd_canvas.add_trans("gaugeNeedle"~id, "rotation", {"sensor":sensor, "min":_min, "max":_max, "scale":r, "offset": -_min*r});
};

var make_TGauge = func (
     sensor, 
     id=nil,
     _min=0,
     _max=100,
     name="N1")
     {
     var r = 225/(_max-_min);
     vmd_canvas.add_text("TgaugeTitle"~id, {"offset": name}); 
     vmd_canvas.add_trans("TgaugeNeedle"~id, "rotation", {"sensor":sensor, "min":_min, "max":_max, "scale":r, "offset": -_min*r});
     vmd_canvas.add_cond("TgaugeCover1"~id, {"function": func {(sensor.get() - _min)*r < 45} });
     vmd_canvas.add_cond("TgaugeCover2"~id, {"function": func {(sensor.get() - _min)*r > 90} });
};

var make_u = func(x,n) { 
var u1 = substr(x,0,1);
var un = substr(x,n,1);

if (x == "°C" and n==0)
  return x;

if (x == "°C" and n>0)
  return "";

if (size(x) < n+1)
  return "";

if (u1 == nil)
  return "";

return un;
};

var make_LinGauge = func (
     sensor1,
     sensor2,
     id=nil,
     _min1=0,
     _max1=100,
     fmt1="%3.0f",
     unit1="",
     _min2=0,
     _max2=100,
     fmt2="%3.1f",
     unit2="",
     name="ENG OIL",
     l1=nil,
     h1=nil,
     l2=nil,
     h2=nil)
     {

     vmd_canvas.add_text("LinGaugeTitle"~id, {"offset": name}); 
     
     if (sensor1!=nil) {
        var r1 = 78.8/(_max1-_min1);
        vmd_canvas.add_text("LinGaugeLValue"~id, {"sensor": sensor1, "format": fmt1 });
        
        vmd_canvas.add_text("LinGaugeLU1"~id, {"offset": make_u(unit1,0)  });
        vmd_canvas.add_text("LinGaugeLU2"~id, {"offset": make_u(unit1,1) });
        vmd_canvas.add_text("LinGaugeLU3"~id, {"offset": make_u(unit1,2) });
        
        vmd_canvas.add_trans("LinGaugeLNeedle"~id, "y-shift", {"sensor":sensor1, "min":_min1, "max":_max1, "scale":-r1, "offset": _min1*r1});
     } else {
        vmd_canvas.add_text("LinGaugeLValue"~id, {"offset": "" });
        vmd_canvas.add_text("LinGaugeLU1"~id, {"offset": ""  });
        vmd_canvas.add_text("LinGaugeLU2"~id, {"offset": ""  });
        vmd_canvas.add_text("LinGaugeLU3"~id, {"offset": ""  });
        vmd_canvas.add_cond("LinGaugeLNeedle"~id, {"offset":0});
     } 
     
     if (sensor2!=nil) {
        var r2 = 78.8/(_max2-_min2);
        vmd_canvas.add_text("LinGaugeRValue"~id, {"sensor": sensor2, "format": fmt2 });
        
        vmd_canvas.add_text("LinGaugeRU1"~id, {"offset": make_u(unit2,0)});
        vmd_canvas.add_text("LinGaugeRU2"~id, {"offset": make_u(unit2,1)});
        vmd_canvas.add_text("LinGaugeRU3"~id, {"offset": make_u(unit2,2)});
        
        vmd_canvas.add_trans("LinGaugeRNeedle"~id, "y-shift", {"sensor":sensor2, "min":_min2, "max":_max2, "scale":-r2, "offset": _min2*r2});
     } else {
        vmd_canvas.add_text("LinGaugeRValue"~id, {"offset": "" });
        vmd_canvas.add_text("LinGaugeRU1"~id, {"offset": ""  });
        vmd_canvas.add_text("LinGaugeRU2"~id, {"offset": ""  });
        vmd_canvas.add_text("LinGaugeRU3"~id, {"offset": ""  });
        vmd_canvas.add_cond("LinGaugeRNeedle"~id, {"offset":0});
     } 
     
     if (l1 == nil) {
        vmd_canvas.add_cond("LinGaugeLlow"~id, {"offset":0});
     } else {
        vmd_canvas.add_cond("LinGaugeLlow"~id, {"offset":1});
        vmd_canvas.add_trans("LinGaugeLlow"~id, "y-scale", 
              {"function": func {
                if (sensor1.get() > l1)
                  return -0.1;
                else
                  return -2*(l1-_min1)/(_max1-_min1);              
              }   });
              
        vmd_canvas.add_trans("LinGaugeLlow"~id, "y-shift", 
              {"offset": -(l1-_min1)*r1});
     }

     if (h1 == nil) {
        vmd_canvas.add_cond("LinGaugeLhigh"~id, {"offset":0});
     } else {
        vmd_canvas.add_cond("LinGaugeLhigh"~id, {"offset":1});
        vmd_canvas.add_trans("LinGaugeLhigh"~id, "y-scale", 
              {"function": func {
                if (sensor1.get() < h1)
                  return -0.1;
                else
                  return -2*(_max1-h1)/(_max1-_min1);              
              }   });
              
        vmd_canvas.add_trans("LinGaugeLhigh"~id, "y-shift", 
              {"offset": (_max1-h1)*r1});
     }

     if (l2 == nil) {
        vmd_canvas.add_cond("LinGaugeRlow"~id, {"offset":0});
     } else {
        vmd_canvas.add_cond("LinGaugeRlow"~id, {"offset":1});
        vmd_canvas.add_trans("LinGaugeRlow"~id, "y-scale", 
              {"function": func {
                if (sensor2.get() > l2)
                  return -0.1;
                else
                  return -2*(l2-_min2)/(_max2-_min2);              
              }   });
              
        vmd_canvas.add_trans("LinGaugeRlow"~id, "y-shift", 
              {"offset": -(l2-_min2)*r2});
     }

     if (h2 == nil) {
        vmd_canvas.add_cond("LinGaugeRhigh"~id, {"offset":0});
     } else {
        vmd_canvas.add_cond("LinGaugeRhigh"~id, {"offset":1});
        vmd_canvas.add_trans("LinGaugeRhigh"~id, "y-scale", 
              {"function": func {
                if (sensor2.get() < h2)
                  return -0.1;
                else
                  return -2*(_max2-h2)/(_max2-_min2);              
              }   });
              
        vmd_canvas.add_trans("LinGaugeRhigh"~id, "y-shift", 
              {"offset": (_max2-h2)*r2});
     }
};