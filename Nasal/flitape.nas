# Helionix flitape calculations

####Calculation into "FLI"###

## First Limit Indicator - FLI
## Originally adopted from ec130 VEMD.nas .

## However the ec135/ec130, VEMD FLI indication differs 
## from the H145 Helionix FND FLI tape:
## according to Neuhaus/Ockier - "Helionix Cockpit Concept" the 
## "FLI scale uses the collective lever position" 
## to display the "moving collective pitch scale".
## The moving markers on top of the FLI tape indicate at which 
## collective pitch the reaching of MCP, take-off- and transient-TO
## torque limits are expected.

var flitape = {
 init: func () {
      # define objects constants
      me.flimcp = 7.4;  # max. continuous 74% TRQ
      me.flitop = 9.5;  # take off power 95% TRQ for max. 30 mins
      me.flisync = 0.1;
      me.flittop = 10.4; # transient take off power 104% TRQ for max. 10 sec.
      me.trqf =  aircraft.lowpass.new(5); # slowly adapt the torque factor
      me.trqfac = 0;
      me.offset = 0;
      
      #set the calibration paramters
      if (!getprop("instrumentation/efis/fnd/fli-mcp-cal")) {
          setprop("instrumentation/efis/fnd/fli-mcp-cal",0.5);
          setprop("instrumentation/efis/fnd/fli-top-cal",0.3);
          setprop("instrumentation/efis/fnd/fli-ttop-cal",0.35);
          setprop("instrumentation/efis/fnd/fli-sync-cal",1);        
      }
      me.trqf.set(2.0); 
      setprop("instrumentation/efis/fnd/fli-tape", 0);
      setprop("instrumentation/efis/fnd/fli-mcp", 0);
      setprop("instrumentation/efis/fnd/fli-ttop", 0); 
      setprop("instrumentation/efis/fnd/fli-top", 0); 
      setprop("instrumentation/efis/fnd/fli-sync", 0);
      
      },

 update: func () {
      # for FLI all params normalized to 10     
      var coll = getprop("/controls/engines/engine/throttle") or 0;
      var trq = max( getprop("/engines/engine/torque-pct") or 0,
                getprop("/engines/engine[1]/torque-pct") or 0)/10;
      
      # FLI tape follows the collective pitch
      var flitape = (1.0 - coll) * 10.0; 
      if (flitape>1 and trq>1) me.trqf.filter(flitape/trq);
      # normalize to TRQ at medium TOW 2900 at 60kt (~2 --> 0)
      me.trqfac = clamp(me.trqf.get()-2, -1, 1);
      
      setprop("instrumentation/efis/fnd/fli-tape", flitape);
      
      # FLI marker positions relative to reference line:
      setprop("instrumentation/efis/fnd/fli-mcp", 
           (me.flimcp - trq)* me.trqf.get() *
           getprop("instrumentation/efis/fnd/fli-mcp-cal"));
           
      setprop("instrumentation/efis/fnd/fli-top", 
          (me.flitop - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-top-cal"));
           
      setprop("instrumentation/efis/fnd/fli-ttop", 
          (me.flittop - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-ttop-cal"));
      
      setprop("instrumentation/efis/fnd/fli-sync",
          (me.flisync - trq)* me.trqf.get() *
          getprop("instrumentation/efis/fnd/fli-sync-cal"));
      
  }
};

# main timer loop:
flitape.timer = maketimer(0.2, func flitape.update() );

setlistener("/sim/signals/fdm-initialized", func () {
  flitape.init();
  flitape.timer.start() }
);