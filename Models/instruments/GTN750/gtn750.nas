
# load the Helionix MFD canvas framework if not already loaded
#
#

if ( !defined("HELIONIXPATH") ) {
    var HELIONIXPATH = "Aircraft/ec145/Models/instruments/EUcopter-mfd-c/";
    io.include(HELIONIXPATH ~ "Nasal/common.nas");
}

var GenerateGTNRadioMenu = func (n) {
  # text colors for the nav/comm frq. numeral when selected
  var navcolors =  [[0,  [0,0,0]], [nil, [1,1,1]], [4,  [1,1,1]] ];
  var comcolors =  [[0,  [1,1,1]], [nil, [0,0,0]], [4,  [0,0,0]] ];
  
  var gnsRadioMode = props.globals.initNode("instrumentation/GTN750/device["~(n-1)~"]/radio-menu-mode-comm", 0, type="BOOL");
  adc["gtn750radioMode"~n] = Sensor.new({prop: "instrumentation/GTN750/device["~(n-1)~"]/radio-menu-mode-comm", type:"BOOL"});
  adc["xpndrid"] = Sensor.new({prop: "instrumentation/transponder/transmitted-id"});

  setlistener("sim/signals/fdm-initialized", func {
    
      print("Initializing GTN750 comm/nav"~n~" menu...");
      #new MFD
      var i = mfd_add([1024,1024], [512,512]);
      #place canvas on screen object
      mfd[i].display.addPlacement({"node": "screencom."~n});
      #make canvas background transparent
      mfd[i].display.setColorBackground(0,0,0,0);

      #add a page (svg) to mfd
      var com1page = mfd[i].add_page("com", "Aircraft/ec145/Models/instruments/GTN750/gtn750.svg");
      var nav = "nav" ~ (n-1);
      var comm = "comm" ~ (n-1);
      
      com1page.add_trans("HeliSymbol", "rotation", {sensor: adc["heading"] });
      com1page.add_text("Gs", {sensor: adc["gpsgs"], format: "%03.0f"});
      com1page.add_text("Trk", {sensor: adc["gpstrk"], format: "%03.0f°"});
      com1page.add_text("VlocAct", {sensor: adc[nav~"frq"], format: "%6.2f"});
      com1page.add_text("VlocStb", {sensor: adc[nav~"stb"], format: "%6.2f"});
      com1page.add_text("CommStb", {sensor: adc[comm~"stb"], format: "%6.2f"});
      com1page.add_text("CommAct", {sensor: adc[comm~"frq"], format: "%6.2f"});
      com1page.add_text("Xpndr", {sensor: adc["xpndrid"], format: "%04.0f"});
      com1page.add_cond("CommSelect", {sensor: adc["gtn750radioMode"~n] });
      com1page.add_cond("VlocSelect", {sensor: adc["gtn750radioMode"~n], notequal:1 });

      com1page.add_color_range("VlocStb", adc["gtn750radioMode"~n] , navcolors);    
      com1page.add_color_range("CommStb", adc["gtn750radioMode"~n] , comcolors);    
      
      com1page.show();
  });
  
};