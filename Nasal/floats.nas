
# toggle floats (inflate/repack)
# mhab 20131104
toggle_floats = func () {

 # if ( getprop("/sim/model/floats/emergencyfloats") ) {
    if ( getprop("/controls/gear/floats-inflat") ) {
      if ( getprop("gear/gear[0]/wow") or getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow") or getprop("gear/gear[3]/wow") ) {
        setprop("/controls/gear/floats-inflat",0);
        setprop("/controls/gear/floats-armed",0);
      } else {
        gui.popupTip("Repack only possible on ground",1);
      }
    } else {
      if ( getprop("/controls/gear/floats-armed") ) {
        setprop("/controls/gear/floats-inflat",1);
      } else {
        gui.popupTip("Floats are not armed",1);
      }
    }
  #}
}
