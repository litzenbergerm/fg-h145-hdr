# headset animation 
#
#

# code for force calc. taken from aircrane

var headset = {
      init: func() {
          me.accel = props.globals.getNode("sim/model/bk117/headset/angle-damped-rad", 1);
          me.oscillation = props.globals.getNode("sim/model/bk117/headset/oscillation-norm", 1);
          
          me.ax = props.globals.getNode("/accelerations/pilot/x-accel-fps_sec");
          me.ay = props.globals.getNode("/accelerations/pilot/y-accel-fps_sec");
          me.az = props.globals.getNode("/accelerations/pilot/z-accel-fps_sec");
          
          me.oszil = 0; # osciallation phase
          me.Aoszil = aircraft.lowpass.new(6); # osciallation amplitude decays with some delay
          me.Aout = aircraft.lowpass.new(1);
        
          me.impulsold = 0;
        
      },
      update: func() {
          me.oszil += 0.3; # rad/s approx. 0.5 Hz
          
          var ay = me.ay.getValue() or 0;
          var az = me.az.getValue() or 0;
          
          # use pilot y body frame accelerations, use thresh. to suppress noise
          var angle = math.pi/2 + math.atan2(az, ay);
          var swing = me.Aout.filter( (math.abs(angle) > 0.003) ? -angle : 0 );

          me.accel.setValue(swing);
          me.Aoszil.filter(math.abs(swing) * 10);
          
          me.oscillation.setValue( math.cos(me.oszil) * min(me.Aoszil.filter(0), 1.0) / 1.5 );
      }
};

setlistener("/sim/signals/fdm-initialized", func { 
     headset.init();
     var headsettimer = maketimer(0.05, func headset.update(); );
     headsettimer.start();
});