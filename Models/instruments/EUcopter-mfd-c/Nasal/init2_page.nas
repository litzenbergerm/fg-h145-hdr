# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

var p=nil;

page_setup["init2"] = func (i) {
  
  p = mfd[i].add_page("init2", HELIONIXPATH~"svg/init2.svg");
  #p.add_text( "mfdID", {"sensor": adc.add( {"function": func sprintf("MFD%1i",i) , "timer": 1, "type": "STRING"}) });
  
  #var si = Sensor.new( { "prop": "instrumentation/mfd["~i~"]/initstep", "timer": SLOW});
  
  #p.add_cond( "Screen1", {"sensor": si, equals:1, "name":"screen1func"});
  #p.add_cond( "Screen2", {"sensor": si, equals:2, "name":"screen2func"});  
  #p.add_cond( "Screen3", {"sensor": si, equals:3, "name":"screen3func"});  
  
}; # func