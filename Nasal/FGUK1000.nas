# moving map using FG1000

var disablefg1000 = getprop("sim/disable-fg1000") or 0;

if (!disablefg1000) {
  var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
  io.load_nasal(nasal_dir ~ 'FG1000.nas', "fg1000");

  # Create the FG1000
  var fg1000system = fg1000.FG1000.getOrCreateInstance();

  # use in Garmin GNS430 (Screen1,Screen4) and the Helionix DMAP (Screen4)
    
  # Create a MFD as device 1 for the Garmin GNS430-1
  fg1000system.addMFD(1);
  # Map the devices to placement objects Screen{i}, in this case 'Screen1'
  fg1000system.display(1);
  # Show the device
  fg1000system.show(1);

  # if you intend to use a second GNS430 for COMM2/NAV2 uncomment the following code
  #
  #
  
  # Create a MFD as device 2 for the Garmin GNS430-2
  fg1000system.addMFD(2);
  # Map the devices to placement objects Screen{i}, in this case 'Screen1'
  fg1000system.display(2);
  # Show the device
  fg1000system.show(2);
  
  var aircraft = getprop("sim/aircraft");
  if (aircraft=="h145m") {
    
    # Create a MFD as device 4 for the Helionix MAPD on H145M
    fg1000system.addMFD(4);
    fg1000system.display(4);
    fg1000system.show(4);
  }

  var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
  io.load_nasal(nasal_dir ~ 'Interfaces/GenericInterfaceController.nas', "fg1000");

  var interfaceController = fg1000.GenericInterfaceController.getOrCreateInstance();
  interfaceController.start();
};