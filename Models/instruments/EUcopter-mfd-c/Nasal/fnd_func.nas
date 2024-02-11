# called back from sensor to update all numerals on alttape
# using this object, just one callback is needed for all 20 numerals
# of the alttape
# ============================

var FND_FUNC_LOADED = 1;
var ALTPOS = [ -3, -2, -1, 0, 1 ,2, 3, 4];
var ROSENUMS = {"markN":0, "markE":90, "markW":270, "markS":180, "mark03":30, "mark06":60, "mark12":120, "mark15":150, "mark21":210, "mark24":240, "mark30":300, "mark33":330};

# define some helper functions
# for the FND page
# ============================

var DME_format = func (x) { x *= DMEFACTOR; return sprintf((x>10) ? "%3.0fNM" : "%4.1fNM", x); }; 

var navSrcLetter = func(hasgs, k, l=1) {
  if (hasgs)
     return substr("ILS",k-1,l);
  else 
     return substr("VOR",k-1,l);
};

var navSrcFrq = func (x) {
  if (x == "NAV1")
     return sprintf("%6.2f", adc.nav0frq.val);
  if (x == "NAV2")
     return sprintf("%6.2f", adc.nav1frq.val);
  if (x == "ADF1")
     return sprintf("%3.0f", adc.adf0frq.val);
  if (x == "FMS")
     return adc.fmstoid.val;
   
  return 0; 
};

var navSrcCrs = func (x) {
  if (x == "NAV1")
     return adc.nav0crs.val;
  if (x == "NAV2")
     return adc.nav1crs.val;
  if (x == "FMS")
     return adc.fmscrs.val;
  if (x == "ADF1")
     return 0;
  return 0; 
};

var navSrcType = func (x) {
  if (x == "NAV1")
     return (adc.nav0hasgs.val ? "ILS1" : "VOR1");
  if (x == "NAV2")
     return (adc.nav1hasgs.val ? "ILS2" : "VOR2");
  return x; 
};

var navSrcDist = func (x) {
  if (x == "NAV1")
     return (DME_format(adc.nav0dist.val));
  if (x == "NAV2")
     return (DME_format(adc.nav1dist.val));
  if (x == "ADF1")
     return "";
  if (x == "FMS")
     return (DME_format(adc.fmsdist.val/DMEFACTOR));;
  return ""; 
};

var navSrcTTG = func (x) {
  
  if (adc.gpsgs.val < 10) 
     return 999;
   
  if (x == "NAV1")
     return adc.nav0ttg.val/60;
  if (x == "NAV2")
     return adc.nav1ttg.val/60;
  if (x == "FMS")
     return adc.fmsttg.val/60;
  return 0; 
};

var navSrcBear = func (x) {
  if (x == "NAV1")
     return adc.nav0bear.val;
  if (x == "NAV2")
     return adc.nav1bear.val;
  if (x == "ADF1")
     return adc.adf0bear.val;
  if (x == "FMS")
     return adc.fmsbear.val;
  return 0; 
};

var navSrcDefl = func (x) {
  # note: FMS course error 5nm = 10 -> full deflection 
  if (x == "NAV1")
     return adc.nav0defl.val;
  if (x == "NAV2")
     return adc.nav1defl.val;
  if (x == "FMS")  
     return adc.fmsdefl.val*2;
  return 0; 
};

var navSrcId = func (x) {
  if (x == "NAV1")
     return adc.nav0id.val;
  if (x == "NAV2")
     return adc.nav1id.val;
  if (x == "FMS")
     return adc.fmstoid.val;
  return ""; 
};

var navSrcInrange = func (x) {
  if (x == "NAV1")
     return adc.nav0inrange.val;
  if (x == "NAV2")
     return adc.nav1inrange.val;
  if (x == "ADF1")
     return adc.adf0inrange.val;
  if (x == "FMS")
     return adc.fmsinrange.val;
  return 0; 
};


var makeHnum = func(a,n) {  
    var numT = sprintf("%+04i", a + n);
    var numH = substr(numT,3,1);
    var p = "";
    if  (a+n < 0)    p ~= "  ";
    if  (abs(int((a + n)/10)) > 9) p ~= "   ";

    return p ~ numH ~ ( (numH == "0" or numH == "5") ? "00" : "");
};

# New approach to Alt tape, copy a template element multiple times 
# and creating the full size tape 20 kft

var generateAltLadder = func (p, pitch=46.5, post500=1) {
    var _id = "";
	
	#generate positive labels up to 20kft
    for (var i=1;  i<200; i+=1) {
      _id = "_"~i;
      p.copy_element("AltElement_0",_id,[0, -pitch*i]);
      p.add_by_id("Hnum0" ~ _id);
      p.add_by_id("altNum0" ~ _id);
      
      # change the label of this ladder element
      p["Hnum0"~_id].setText("" ~ math.mod(i,10) ~ ( (math.mod(i,5)==0 and post500) ? "00" : "" ));
      p["altNum0"~_id].setText("" ~ int(i/10));
      if (i>99) p["Hnum0"~_id].setTranslation(13,0);
    }
	#generate neg. labels down to - 1000 ft
    for (var i=1;  i<11; i+=1) {
      _id = "_m"~i;
      p.copy_element("AltElement_0",_id,[0, pitch*i]);
      p.add_by_id("Hnum0" ~ _id);
      p.add_by_id("altNum0" ~ _id);
      # change the label of this ladder element
      p["Hnum0"~_id].setText("" ~ math.mod(i,10) ~ ( (math.mod(i,5)==0 and post500) ? "00" : "" ));
      p["altNum0"~_id].setText("-" ~ int(i/10));
      p["Hnum0"~_id].setTranslation(13,0);
	}
};

  
var Rosenumerals = {
   new: func(pg,x1,y1) 
   {
      var m = { parents: [Rosenumerals] };
      m.obj = pg;
      m.xsize=x1;
      m.ysize=y1;      

      foreach (var n; keys(ROSENUMS))
           pg.add_by_id(n);
      
      # register the heading numerals update with the heading sensor object
      #adc.heading.register(m, m.update, y=0, pg);
      adc.heading._register_({o: pg[ "markN" ], c: [0,0], f: func(a,b) m.update(adc.heading.val)}, pg);
      
      return m;
  },
   
  update: func (hdg) {
      foreach (var n; keys(ROSENUMS) ) {
         me.obj[n].setTranslation( 
                math.sin((ROSENUMS[n] - hdg)*D2R)*me.xsize , 
                -math.cos((ROSENUMS[n] - hdg)*D2R)*me.ysize);
      }
  }
};

var GenerateRosenumerals = func(pg, r) {
      var c = [];
      
      foreach (var n; keys(ROSENUMS))
           pg.add_by_id(n);
      
      foreach (var n; keys(ROSENUMS)) {
           # shift numerals to their respective places
           pg[n].setTranslation( 
                math.sin(ROSENUMS[n]*D2R)*r,
                -math.cos(ROSENUMS[n]*D2R)*r);
           
           # set a new center for rotation
           c = pg[n].getCenter();
           
           pg[n].setCenter( 
                c[0] + math.sin(ROSENUMS[n]*D2R)*r,
                c[1] - math.cos(ROSENUMS[n]*D2R)*r);
           
           # rotate in opposite direction to compensate for rose group rot.
           pg.add_trans(n, "rotation", {sensor:adc.heading, scale: 1})
     }
   
};
         
# just a single callback to windspeed for all windbarb elements
# to reduce overhead

var Generatewindbarb = func (page, s = "relwinddir") {
  
  p.add_trans("windBarb", "rotation", {sensor: adc[s], offset: 180 });
  
  page.add_by_id("windBarb1");
  page.add_by_id("windBarb2");
  page.add_by_id("windBarb3");
  page.add_by_id("windBarb4");

  adc.windspeed._register_( 
                {o: page, 
                 c: [0,0], 
                 f: func(x,c) {
                        if (adc.windspeed.val > 2) {
                          x.windBarb.setVisible(1); 
                          x.windBarb1.setVisible(adc.windspeed.val>8); 
                          x.windBarb2.setVisible(adc.windspeed.val>18);
                          x.windBarb3.setVisible(adc.windspeed.val>28);
                          x.windBarb4.setVisible(adc.windspeed.val>38);
                        } else {
                          x.windBarb.setVisible(0);
                        }                          
                    }
                  },
                  page
  );
};
                        
