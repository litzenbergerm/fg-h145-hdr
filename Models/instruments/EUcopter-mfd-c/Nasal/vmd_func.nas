# define some helper functions
# for VMD display
# ============================

var VMD_FUNC_LOADED=1;

             
var make_numeral = func( 
     sensor, 
     _id=nil,
     dec=1,
     unit="%",
     _amber = nil,
     _red = nil) 
     {
     var fmt1 = (dec) ? "%3i." : "%3i";
     var fmt2 = "%1i";
     
     p.add_text("numUnit"~_id,{"offset": unit});
       
     p.add_text("numTen"~_id, {"sensor": sensor, "format": fmt1, "min":0, "trunc":1});
     if (dec)
       p.add_text("numDec"~_id,{"sensor": sensor, "format": fmt2, "mod":1.0, "scale":10, "min":0, "max":0.9} );
     else
       p.add_text("numDec"~_id,{"offset": ""});
     
     if (_amber == nil) {
      p.add_cond("numAmber"~_id, {"offset": 0});
     } else {
       if (_amber > 0)
          p.add_cond("numAmber"~_id, {"sensor": sensor, "greaterthan": _amber});
       else
         p.add_cond("numAmber"~_id, {"sensor": sensor, "lessthan": -_amber });
    }
     
    if (_red == nil) {
      p.add_cond("numRed"~_id, {"offset": 0});
     } else {
       if (_red > 0)
          p.add_cond("numRed"~_id, {"sensor": sensor, "greaterthan": _red });
       else
         p.add_cond("numRed"~_id, {"sensor": sensor, "lessthan": -_red });
    }
};

var make_Gauge = func (
     sensor, 
     _id=nil,
     _min=0,
     _max=100,
     name="N1")
     {
     var r = 180/(_max-_min);
     p.add_text("gaugeTitle"~_id, {"offset": name});     
     p.add_trans("gaugeNeedle"~_id, "rotation", {"sensor":sensor, "min":_min, "max":_max, "scale":r, "offset": -_min*r});
};

var make_TGauge = func (
     sensor, 
     _id=nil,
     _min=0,
     _max=100,
     name="N1")
     {
     var r = 225/(_max-_min);
     p.add_text("TgaugeTitle"~_id, {"offset": name}); 
     p.add_trans("TgaugeNeedle"~_id, "rotation", {"sensor":sensor, "min":_min, "max":_max, "scale":r, "offset": -_min*r});
     p.add_cond("TgaugeCover1"~_id, {"sensor": sensor, "offset": _min*r, "scale": r, "lessthan": 45 });
     p.add_cond("TgaugeCover2"~_id, {"sensor": sensor, "offset": _min*r, "scale": r, "greaterthan": 90 });
};

var make_u = func(x,n) { 
    var u1 = substr(x,0,1);
    var un = substr(x,n,1);

    #handel degree celsius
    if (x == "gC" and n==0)
      return "°C";

    if (x == "gC" and n>0)
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
     _id=nil,
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
     h2=nil,
     _size=78.8)
     {

     p.add_text("LinGaugeTitle"~_id, {"offset": name}); 
     
     if (sensor1!=nil) {
        var r1 = _size/(_max1-_min1);
        p.add_text("LinGaugeLValue"~_id, {"sensor": sensor1, "format": fmt1 });
        p.add_cond("LinGaugeLValue"~_id, {sensor: adc.vmdnum });
        
        p.add_text("LinGaugeLU1"~_id, {"offset": make_u(unit1,0)  });
        p.add_text("LinGaugeLU2"~_id, {"offset": make_u(unit1,1) });
        p.add_text("LinGaugeLU3"~_id, {"offset": make_u(unit1,2) });
        
        p.add_trans("LinGaugeLNeedle"~_id, "y-shift", {"sensor":sensor1, "min":_min1, "max":_max1, "scale":-r1, "offset": _min1*r1});
     } else {
        p.add_text("LinGaugeLValue"~_id, {"offset": "" });
        p.add_text("LinGaugeLU1"~_id, {"offset": ""  });
        p.add_text("LinGaugeLU2"~_id, {"offset": ""  });
        p.add_text("LinGaugeLU3"~_id, {"offset": ""  });
        p.add_cond("LinGaugeLNeedle"~_id, {"offset":0});
     } 
     
     if (sensor2!=nil) {
        var r2 = _size/(_max2-_min2);
        p.add_text("LinGaugeRValue"~_id, {"sensor": sensor2, "format": fmt2 });
        p.add_cond("LinGaugeRValue"~_id, {sensor: adc.vmdnum });
        
        p.add_text("LinGaugeRU1"~_id, {"offset": make_u(unit2,0)});
        p.add_text("LinGaugeRU2"~_id, {"offset": make_u(unit2,1)});
        p.add_text("LinGaugeRU3"~_id, {"offset": make_u(unit2,2)});
        
        p.add_trans("LinGaugeRNeedle"~_id, "y-shift", {"sensor":sensor2, "min":_min2, "max":_max2, "scale":-r2, "offset": _min2*r2});
     } else {
        p.add_text("LinGaugeRValue"~_id, {"offset": "" });
        p.add_text("LinGaugeRU1"~_id, {"offset": ""  });
        p.add_text("LinGaugeRU2"~_id, {"offset": ""  });
        p.add_text("LinGaugeRU3"~_id, {"offset": ""  });
        p.add_cond("LinGaugeRNeedle"~_id, {"offset":0});
     } 
     
     if (l1 == nil or sensor1 == nil) {
        p.add_cond("LinGaugeLlow"~_id, {"offset":0});
     } else {
        p.add_cond("LinGaugeLlow"~_id, {"offset":1});
        p.add_trans("LinGaugeLlow"~_id, "y-scale", 
              {sensor: adc.add( {"function": func {
                if (sensor1.val > l1)
                  return -0.1;
                else
                  return -2*(l1-_min1)/(_max1-_min1);              
              }   }) 
        });
              
        p.add_trans("LinGaugeLlow"~_id, "y-shift", 
              {"offset": -(l1-_min1)*r1});
     }

     if (h1 == nil or sensor1 == nil) {
        p.add_cond("LinGaugeLhigh"~_id, {"offset":0});
     } else {
        p.add_cond("LinGaugeLhigh"~_id, {"offset":1});
        p.add_trans("LinGaugeLhigh"~_id, "y-scale", 
              {sensor: adc.add( {"function": func {
                if (sensor1.val < h1)
                  return -0.1;
                else
                  return -2*(_max1-h1)/(_max1-_min1);              
              }   })
        });
              
        p.add_trans("LinGaugeLhigh"~_id, "y-shift", 
              {"offset": (_max1-h1)*r1});
     }

     if (l2 == nil or sensor2 == nil) {
        p.add_cond("LinGaugeRlow"~_id, {"offset":0});
     } else {
        p.add_cond("LinGaugeRlow"~_id, {"offset":1});
        p.add_trans("LinGaugeRlow"~_id, "y-scale", 
              {sensor: adc.add( {"function": func {
                if (sensor2.val > l2)
                  return -0.1;
                else
                  return -2*(l2-_min2)/(_max2-_min2);              
              }   })
        });
              
        p.add_trans("LinGaugeRlow"~_id, "y-shift", 
              {"offset": -(l2-_min2)*r2});
     }

     if (h2 == nil or sensor2 == nil) {
        p.add_cond("LinGaugeRhigh"~_id, {"offset":0});
     } else {
        p.add_cond("LinGaugeRhigh"~_id, {"offset":1});
        p.add_trans("LinGaugeRhigh"~_id, "y-scale", 
              {sensor: adc.add( {"function": func {
                if (sensor2.val < h2)
                  return -0.1;
                else
                  return -2*(_max2-h2)/(_max2-_min2);              
              }   })
        });
              
        p.add_trans("LinGaugeRhigh"~_id, "y-shift", 
              {"offset": (_max2-h2)*r2});
     }
};
