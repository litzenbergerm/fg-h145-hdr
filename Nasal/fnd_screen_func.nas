# define some helper functions
# for the FND screen
# ============================

var ROSESC = 0.58;
var ROSEX = 180;
var ROSEY = ROSEX * ROSESC;
var DMEFACTOR = 0.0005399;
var ALTFACTOR = (651-464)/400;  
var FPS2FPM = 60;

var SHIFT_THRES = 0.5;
var ROT_THRES = 0.1;    

var rose_mark_x = func (w) math.sin((w*10 - adc.heading.get())*D2R)*ROSEX;
var rose_mark_y = func (w) -math.cos((w*10 - adc.heading.get())*D2R)*ROSEY;
var DME_format = func (p) { x = (getprop(p) or 0) * DMEFACTOR; return sprintf((x>10) ? "%3.0f NM" : "%4.1f NM", x); }; 

var altTs = func (n) {
    var a = (adc.alt.get() or 0) + n*100;
    var x = int(a/1000);
    if (a<0 and x==0) return "-0";
    return ""~x;
    };
    
var altHs = func (n) {
  var a = (adc.alt.get() or 0) + n*100;
  var x = abs( math.floor(math.fmod(a,1000)/100) );
  if (x==0) return "000";
  if (x==5) return "500";
  return "" ~ x;
};

var altMove = func (n) {
  var a=adc.alt.get() + n*100;    
  var x = int(a/1000);
  
  if (a<0 and x==0) return 7;
  return (x < 0 or x > 9) ? 12 : 1; 
};
