
# vemd.nas taken from ec130 model, 
# original authors Michael Habarta and HHS81
# adaptations for ec145 by litzi

#######VEMD######

####FLI = FirstLimitIndicator####
###Calculation into "FLI"###

var Flicalc = {
  new: func (engnum) {
    var m = { parents: [Flicalc] };
    m.n1 = props.globals.initNode("/engines/engine["~engnum~"]/n1-pct",1);
    m.tot = props.globals.initNode("/engines/engine["~engnum~"]/tot-degc",1);
    m.trq = props.globals.initNode("/engines/engine["~engnum~"]/torque-pct",1);
    m.val = props.globals.initNode("instrumentation/VEMD/FLI["~engnum~"]/fli",1);
    m.limit = props.globals.initNode("instrumentation/VEMD/FLI["~engnum~"]/limit",1,type="STRING");

    m.n1filter = aircraft.lowpass.new(2);
    m.totfilter = aircraft.lowpass.new(2);
    m.trqfilter = aircraft.lowpass.new(2);

    return m;

  },
  init: func () {

    me.n1old = me.n1.getValue()/10 or 0;
    me.totold = me.tot.getValue()/100 or 0;
    me.trqold = me.trq.getValue()/7.5 or 0;

    me.val.setValue(0);
    me.limit.setValue("TOT");

  },
  update: func () {
    var tconst = 1;
    # all FLI limits are normalized to 10
    var fliN1 = me.n1.getValue()/10;    # 100 % max N1
    var fliTOT = me.tot.getValue()/100; # 1000 C max TOT
    var fliTRQ = me.trq.getValue()/8.0; # ~80 % max trq

    # check the value with highest rate of change
    
    var d_N1 = me.n1filter.filter(fliN1-me.n1old);
    var d_TOT = me.totfilter.filter(fliTOT-me.totold);
    var d_TRQ = me.trqfilter.filter(fliTRQ-me.trqold);

    if (d_N1 > d_TRQ) {
      if (d_N1 > d_TOT){
        interpolate (me.val, fliN1, tconst);
        me.limit.setValue("N1");
      } else {
        interpolate (me.val, fliTOT, tconst);
        me.limit.setValue("TOT");
      }
    } else {
      if (d_TRQ > d_TOT) {
        interpolate (me.val, fliTRQ, tconst);
        me.limit.setValue("TRQ");
      } else {
        interpolate (me.val, fliTOT, tconst);
        me.limit.setValue("TOT");
      }
    }

    me.n1old = fliN1;
    me.totold = fliTOT;
    me.trqold = fliTRQ;
  }
};

var fli0 = Flicalc.new(0);
var fli1 = Flicalc.new(1);

var vemd_timer = maketimer(0.5, func () {fli0.update(); fli1.update(); });

setlistener("/sim/signals/fdm-initialized", 
  func () {
   fli0.init();
   fli1.init();
   vemd_timer.start();
  }
);