# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================
#

var ALTFACTOR2 = (651-464)/400;  
var FPS2FPM = 60;
var SHIFT_THRES = 0.5;
var ROT_THRES = 0.1;    
var STBYALTPOS = [-3, -2, -1, 0, 1 ,2, 3, 4];

if (!defined("Rosenumerals"))
   io.include(HELIONIXPATH ~ "Nasal/fnd_func.nas");


page_setup["stbyai"] = func (i) {
  
  p = mfd[i].add_page("stbyai", HELIONIXPATH~"svg/stbyai.svg");
  
  # alt tape generation
  generateAltLadder(p, pitch=ALTFACTOR2*100, post500=0);
  
  # move speed and fli tapes, animate ai elements
  # ============================
  
  p.add_direct("horizon", adc.pitch, func(o,c) o.setTranslation(0, math.clamp(adc.pitch.val, -90, 90)*3.6*2));
  p.add_direct("horizon", adc.roll, func(o,c) o.setRotation(-adc.roll.val*D2R,c[0],c[1]) );
  
  p.add_direct("horizonNums", adc.pitch, func(o,c) o.setTranslation(0, math.clamp(adc.pitch.val, -90, 90)*3.6*2));
  p.add_direct("horizonNums", adc.roll, func(o,c) o.setRotation(-adc.roll.val*D2R,c[0],c[1]) );
  
  p.add_direct("Alt_Group", adc.alt, func(o,c) o.setTranslation(0, adc.alt.val*ALTFACTOR2*2));
  p.add_direct("speedtape", adc.ias, func(o,c) o.setTranslation(0, math.clamp(adc.ias.val, -20, 350) *3.19*2));
  p.add_direct("rollPointer", adc.roll, func(o,c) o.setRotation(-adc.roll.val*D2R,c[0],c[1]) );
  p.add_direct("slipSkid", adc.slipskid, func(o,c) o.setTranslation( adc.slipskid.val*-25, 0) );

  p.add_text("qnh", {sensor: adc.qnhDisplay });

}; # func 