# N2,NR tachimeter needles update, only used by ec145 model
#
#

var tachi = {
        init: func() {
            me.n2in = [props.globals.getNode("engines/engine[0]/n2-pct", 1), 
                       props.globals.getNode("engines/engine[1]/n2-pct", 1)];
            
            me.n2out = [props.globals.getNode("instrumentation/tachi/indicated-n2-pct[0]", 1), 
                        props.globals.getNode("instrumentation/tachi/indicated-n2-pct[1]", 1)];
          
            me.nRin = props.globals.getNode("rotors/main/rpm-pct", 1);
            me.nRout =  props.globals.getNode("instrumentation/tachi/indicated-nr-pct", 1);
            
            me.elec = props.globals.getNode("systems/electrical/outputs/tachimeter", 1);            
            me.elecOld = 0;
            me.wait = 0;
        },
        update: func() {
          var haspower = (me.elec.getValue() or 0) > 12;
          
          if (me.wait > 0) {
            me.wait += -1;
            return;
          }
          
          if ((me.elecOld == 0) and haspower) {
            # sim. tachi test on power up
            interpolate(me.n2out[0], 95, 1.0);
            interpolate(me.n2out[1], 100, 1.0);
            interpolate(me.nRout, 105, 1.0);
            # block update for some cycles to show the test
            me.wait = 12;
          } else {
            if (haspower) {
              var nR = me.nRin.getValue() or 0;
              var n2 = [(me.n2in[0].getValue() or 0), (me.n2in[1].getValue() or 0)];
            } else {
              var nR = 0;
              var n2 = [0,0];
            }            
            interpolate(me.n2out[0], n2[0], 1);
            interpolate(me.n2out[1], n2[1], 1);
            interpolate(me.nRout, nR, 1);
            
          }
          me.elecOld = haspower;
          
        }
};

setlistener("/sim/signals/fdm-initialized", func { 
     tachi.init();
     var tachitimer = maketimer(0.1, func tachi.update(); );
     tachitimer.start();
});