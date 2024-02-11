
# load the Helionix MFD canvas framework if not already loaded
#
#

if ( !defined("HELIONIXPATH") ) {
    var HELIONIXPATH = "Aircraft/ec145/Models/instruments/EUcopter-mfd-c/";
    io.include(HELIONIXPATH ~ "Nasal/common.nas");
}

var GenerateGNSRadioMenu = func (n) {

  var gnsRadioVisible = props.globals.initNode("instrumentation/GNS430/device["~(n-1)~"]/radio-menu-visible", 0, type="DOUBLE");
  var gnsRadioMode = props.globals.initNode("instrumentation/GNS430/device["~(n-1)~"]/radio-menu-mode-comm", 0, type="BOOL");
  adc["gns430radioMode"~n] = Sensor.new({prop: "instrumentation/GNS430/device["~(n-1)~"]/radio-menu-mode-comm", type:"BOOL"});
  
  
  setlistener(gnsRadioVisible, func {
     if (gnsRadioVisible.getValue() == 1) {
       interpolate(gnsRadioVisible, 0, 5);
     }
  }
     
  );

  setlistener("sim/signals/fdm-initialized", func {
    
      print("Initializing GNS430 comm/nav"~n~" menu...");
      #new MFD
      var i = mfd_add([512,512], [512,512]);
      #place canvas on screen object
      mfd[i].display.addPlacement({"node": "screencom."~n});
      mfd[i].display.setColorBackground(0,0,0,0);

      #add a page (svg) to mfd
      var com1page = mfd[i].add_page("com", "Aircraft/ec145/Models/instruments/GNS430/gns430-radio/gns430-radio.svg");
      var nav = "nav" ~ (n-1);
      var comm = "comm" ~ (n-1);
      
      com1page.add_text("VlocAct", {sensor: adc[nav~"frq"], format: "%7.3f"});
      com1page.add_text("VlocStb", {sensor: adc[nav~"stb"], format: "%7.3f"});
      com1page.add_text("CommStb", {sensor: adc[comm~"stb"], format: "%7.3f"});
      com1page.add_text("CommAct", {sensor: adc[comm~"frq"], format: "%7.3f"});
      com1page.add_cond("CommSelect", {sensor: adc["gns430radioMode"~n] });
      com1page.add_cond("VlocSelect", {sensor: adc["gns430radioMode"~n], notequal:1 });
      
      com1page.show();
  });
  
};