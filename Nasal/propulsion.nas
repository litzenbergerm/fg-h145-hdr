# Propulsion system for YASIM helicopters
# needs aircraft/Systems/propulsion.xml for configuration
# needs aircraft/Systems/propulsion-rules.xml for time critical components, PID-controller
# of turbines and transmission
# litzi 

# based on b117.nas by Melchior FRANZ, < mfranz # aon : at >

# 

io.include("/Aircraft/ec145/Nasal/lut-lib.nas");

# these need to be accessible in the global scope

var RPM2RADS = 0.104719755;
var STARVED  = -1;
var OFF      = 0;
var START    = 1;
var IDLE     = 2;
var FLIGHT   = 3;
var TRAIN    = 4;

# fuel ==============================================================

# density = 6.682 lb/gal [Flight Manual Section 9.2]
# avtur/JET A-1/JP-8

var FUEL_DENSITY = getprop("/consumables/fuel/tank/density-ppg"); # pound per gallon
var GAL2LB = FUEL_DENSITY;
var LB2GAL = 1 / GAL2LB;
var KG2GAL = KG2LB * LB2GAL;
var GAL2KG = 1 / KG2GAL;

var fuelsystem = props.globals.getNode("/consumables/fuel");
var configroot = "/fdm/yasim/";

var pow = func(v, w) math.exp(math.ln(v) * w);
var clamp = func(v, min = 0, max = 1) v < min ? min : v > max ? max : v;
var max = func(a, b) a > b ? a : b;
var min = func(a, b) a < b ? a : b;

# a class that damps spool-up realistically by 
# limiting the rpm acceleration rate, but
# uses a lowpass for the rpm decay.

var DampRPM = {
  new: func (maxacc, decaytime) {
    var m = { parents: [DampRPM] };
    m.decay = 0;
    m.maxacc = maxacc;
    # instantanous acceleration
    m.acc = 0;
    
    # lowpass for rpm decay
    m.rpm = aircraft.lowpass.new(decaytime);
    m.rpm.set(0);
    m.delta_time = props.globals.getNode("/sim/time/elapsed-sec");
    m.t = m.delta_time.getValue();
    
    return m;
  },
  
  filter: func (targetrpm) {
     var val = me.rpm.get();
     var dt = me.delta_time.getValue() - me.t;
     
     var diff = targetrpm-val;
     
     # is the rpm decaying?
     me.decay = (diff<0);
     
     if (me.decay or diff<0.02) {
       # use the lowpass for decay of rmp 
       # or when close to target
       me.rpm.filter(targetrpm);
       
       # reset acceleration
       me.acc = 0;
     } else {
       # smoothly ramp up acceleration to maxacc within 2 sec
       #me.acc = min(me.acc + me.maxacc/10*dt, me.maxacc);
       me.acc=             me.maxacc;
       
       # increase rpm up to target 
       val = min(val + me.acc*dt, targetrpm);
       
       # for later decay we need to start at this point
       me.rpm.set(val);
     }
     
     me.t = me.delta_time.getValue();
     return me.rpm.get();
  },
  
  set: func (x) 
     return me.rpm.set(x),
     
  get: func 
     return me.rpm.get()
};



var Tank = {
  new: func(n) {
      var m = { parents: [Tank] };
      m.node = fuelsystem.getNode("tank["~n~"]");
      m.emptyp = m.node.getNode("empty");
      m.level_lbN = m.node.getNode("level-lbs");
      m.prime = props.globals.initNode("/systems/electrical/outputs/fuelpump-prime["~n~"]");
      return m;
  },
  init: func() {
      me.capacity = me.node.getNode("capacity-gal_us").getValue();
      me.level_galN = me.node.initNode("level-gal_us", me.capacity);
      me.consume(0);
  },
  level: func {
      return me.level_galN.getValue();
  },
  consume: func(amount) { # US gal (neg. values for feeding)
      var level = me.level();
      if (amount > level)
              amount = level;
      level -= amount;
      if (level > me.capacity)
              level = me.capacity;
      me.level_galN.setValue(level);
      me.level_lbN.setValue(level * GAL2LB);
      me.empty = me.emptyp.getValue(); #(level <= 0);
      return amount;
  }
};

# Turbine class ==============================================================
# the fuelsystem must have a Tank object as a member "supply[id]" 

var Turbine = {
  new: func(n, super) {
    var m = { parents: [Turbine] };
    m.n = n;
    
    m.table = super.table; # references into to super class propulsion
    m.rotor_rpm = super.rotor_rpm;
    m.torque = super.torque;
    m.collective = super.collective;
    m.target_rel_rpm = super.target_rel_rpm;
    m.max_rel_torque = super.max_rel_torque;
    m.oatnode = super.oatnode;
    m.iasnode = super.iasnode;
    
    var path = "/engines/engine[" ~ m.n ~ "]/";
    var cpath = "/controls/engines/engine[" ~ m.n ~ "]/";
    
    m.timeconst = 1;
    m.electric_prop="";

    # engine control props
    m.powerIn = props.globals.initNode(cpath ~ "power",1);
    m.ignitionIn = props.globals.initNode(cpath ~ "ignition", 1, "BOOL");
    
    # engine output props
    m.starterOut = props.globals.initNode(path ~ "starter", 1);
    m.runningOut= props.globals.initNode(path ~ "running", 1, "BOOL");
    m.outOfFuelOut= props.globals.initNode(path ~ "out-of-fuel", 1, "BOOL");
    m.freewheelOut = props.globals.initNode(path ~ "freewheel", 1);
    m.powerOut = props.globals.initNode(path ~ "power-pct",1);
    m.powerOutWatt = props.globals.initNode(path ~ "power-watts",1);
    m.maxRelTrqOut = props.globals.initNode(path ~ "max-rel-torque",1);
    
    m.n1pct = props.globals.initNode(path ~ "n1-pct", 1);
    m.n2pct = props.globals.initNode(path ~ "n2-pct", 1);
    m.n1rpm = props.globals.initNode(path ~ "n1-rpm", 1);      # gas generator rpm
    m.n2rpm = props.globals.initNode(path ~ "n2-rpm", 1);      # free power turbine rpm
    m.rpm = props.globals.initNode(path ~ "rpm", 1);           # shaft output rpm
    m.trqpct = props.globals.initNode(path ~ "torque-pct",1);
    m.trqnm = props.globals.initNode(path ~ "torque-Nm",1);   
    m.tot = props.globals.initNode(path ~ "tot-degc",1);
    m.ff = props.globals.initNode(path ~ "fuel-flow_pph",1);
    m.oilt = props.globals.initNode(path ~ "oil-temperature-degc",1);
    m.oilp = props.globals.initNode(path ~ "oil-pressure-bar",1);

    # engine parameters read from propulsion.xml
    m.starter = 0;
    m.decay = 0;
    m.state = OFF;
    m.maxreltorque = 0;  # power setting , i.e. the target n1 value
    m.freewheeling = 0;
  
    m.n1=0;   # current n1 normalized to 0..1
    m.n2=0;   # current n2 normalized to 0..1
    m.n2old=0;
    m.trq=0;  # torque normalized to 0..1
    m.dn1=0;
    m.n1old=0;
    m.fuelflow_kgh=0;
    m.power=0;
    m.power_max=0;
 
    m.n2set = 0;  # the n2 target value
    m.n1set = 0;  # the n1 target value
     
    m.fuelpump = nil;
    m.fuelpress = 0;
    
    m.model_name="";
    m.data_source="";
    m.starter_max=0;
    m.starter_is_running=0;
    m.starter_time_s=0;
    m.starter_spooltime_s=0;
    
    m.n1_min=0;
    m.n1_fuelpress=0;
    m.n1_idle=0;
    m.pwr_flight=0;
    m.n1_rpm_max=0;
    
    m.n2_idle=0;
    m.n2_train=0;
    m.n2_no_trq=0;
    m.n2_rpm_max=0;
    m.shaft_rpm_max=0;
    m.trq_max_Nm=0;
    m.pwr_idle=0;
    m.pwr_start=0;    
    m.fuelflow_idle_kgh=0;
    m.fuelflow_max_kgh=0;
    
    m.spooltime_idle_s=0;
    m.decaytime_s=0;
    m.tot_ignite_deg=0;
    m.tot_timeconst_s=0;
    m.tot_cooltime_s=0;
    m.tot_dn1dt_factor=0;
    
    m.oiltemp_nominal_degc=0;
    m.oiltemp_cooltime_s=0;
    m.oilpress_nominal_bar=0;
    
    m.supply_tank=0;
    m.starter_prop="";
    m.train_prop="";
    m.flight_prop="";
    m.cutoff_prop="";
    m.ignition_prop="";
    m.starter_prop="";
    m.primer_prop="";
    m.timer = aircraft.timer.new("/sim/time/hobbs/turbines[" ~ n ~ "]", 10);

    return m;
  },  
  init: func () {    
    me.starterIn = props.globals.initNode(me.starter_prop, 0);
    me.cutoffIn = props.globals.initNode(me.cutoff_prop, 0, type="BOOL");
    me.flightIn = props.globals.initNode(me.flight_prop, 0, type="BOOL");
    me.trainIn = props.globals.initNode(me.train_prop, 0, type="BOOL");
    me.ignitionIn = props.globals.initNode(me.ignition_prop, 0, type="BOOL");  
    me.fuelpump = props.globals.initNode(me.primer_prop, 0);  
    me.supply=Tank.new(me.supply_tank);
    me.supply.init();
    
    me.n1LP = DampRPM.new(me.n1_idle/me.spooltime_idle_s, me.decaytime_s);
    me.n2LP = DampRPM.new(me.n2_idle/me.spooltime_idle_s, me.decaytime_s);
    me.pwrLP = DampRPM.new(me.spooltime_idle_s, 0.1);
    
    me.trqLP = aircraft.lowpass.new(1);
    me.fwLP = aircraft.lowpass.new(1);
    me.totLP = aircraft.lowpass.new(1);
    me.oiltLP = aircraft.lowpass.new(me.oiltemp_cooltime_s);
    me.oilpLP = aircraft.lowpass.new(5);
    
    me.n1LP.set(0);
    me.n2LP.set(0);
    me.trqLP.set(0);
    me.fwLP.set(0);
    me.oilpLP.set(0);
    
    var oat = me.oatnode.getValue() or 0;
    me.totLP.set(oat);
    me.oiltLP.set(oat);

    me.n1=0;
    me.n2=0;
    me.n2set=0;
    me.trq=0;
    me.decay=0;
    me.starterOut.setValue(0);
    me.ignitionIn.setValue(0);
    me.cutoffIn.setValue(0);
    me.flightIn.setValue(0);
    me.powerIn.setValue(0);
    me.state=OFF;
    me.freewheeling=0;
    me.power_max=me.shaft_rpm_max*me.trq_max_Nm*RPM2RADS;
    me.spoolup=1;
    me.pwr_adjust = 0;
        
    # if starter motor is activated start spoolup
    me.starterListener = setlistener(me.starterIn, func {me._check_start()} );
    me.flightListener = setlistener(me.flightIn, func {me._check_flight()} );
    me.cutoffListener = setlistener(me.cutoffIn, func {me._check_off()} );
    me.trainListener = setlistener(me.trainIn, func {me._check_train()} );
    
    me.timer.start();
  },
  _check_start: func () {
    if (me.starterIn.getValue() > 0) {
      if (me.starter_is_running) # do not restart while starter is running
        return;
      me.starter_is_running = 1;
      #starter motor spoolup
      interpolate(me.starterOut, me.starter_max , me.starter_spooltime_s);
    } else {     
      #no more power on starter -> starter motor spooldown time 3s
      interpolate(me.starterOut, 0, 3);
      me.starter_is_running = 0;
    }    
  },
  _check_flight: func () {
    # flight flag toggles between flight and idle
    if (me.flightIn.getValue() == 1) { 
      if (me.state == IDLE)    
        me.flight();
    } else {
      if (me.state == FLIGHT)
        me.idle();
    }
  },
  _check_train: func () {
    # flight flag toggles between flight and training mode
    if (me.trainIn.getValue() == 1) { 
      if (me.state == FLIGHT)    
        me.train();
    } else {
      if (me.state == TRAIN)
        me.flight();
    }
  },    
  _check_off: func () {
    if (me.state == OFF)
      return;
    
    if (me.cutoffIn.getValue() == 1) 
      me.off();
  }, 
  start: func () {
    if (me.state != OFF) {
       print("engine is running ", me.n);
       return;
    }
    
    print("starting engine ", me.n);
    me.state=START;
    me.decay=0;
    
  },
  idle: func () {
    print("idle engine ", me.n);
    # fast decay from FLIGHT to IDLE rpm
    me.decay=(me.state == FLIGHT);
    me.state=IDLE;
    
  },  
  flight: func () {
    print("flight engine ", me.n);
    me.state=FLIGHT;
    me.decay=0;
    me.spoolup=1;
    
  },
  train: func () {
    print("training engine ", me.n);
    me.state=TRAIN;
    me.decay=1;
    me.spoolup=0;    
  },
  
  off: func () {
    print("stopping engine ", me.n);
    me.state=OFF;
    me.decay=1;
    
  },
  quickstart: func () {
    me.state=FLIGHT;
    me.decay=0;
    me.n1_fuelpress = 0;
    me.n1=1;
    me.n1set=1;
    me.maxreltorque = 1;

  },
  update_n1: func (dt) {
    # check fuelpress from pump, n1, fuel tank
    me.fuelpress = ((me.n1 > me.n1_fuelpress and !me.starterIn.getValue()) or me.fuelpump.getValue()) and !me.supply.empty;    
    me.outOfFuelOut.setValue(!me.fuelpress);
    
    var starterrpm = me.starterOut.getValue();
    var ias = me.iasnode.getValue() or 0;
    var oat = me.oatnode.getValue() or 0;
    
    if (me.fuelpress==0) {
      if (me.state!=OFF) 
         print("no fuel pressure engine ", me.n);
      me.state=OFF;
    }
    
    if (me.state==OFF) {
      # off, simulate n1,n2 spooldown
      me.pwrLP.filter(0.0);
      me.n2set    = 0.0;
      me.n1set    = 0.0;
      
      # check if starting conditions are met
      if ( me.starterIn.getValue() and me.ignitionIn.getValue() and me.fuelpress ) {
         me.state = START;
         me.pwrLP.set( me.pwr_start );
      }
    }
    
    if (me.state==START) {
      # while starting, n1 must follow starter rpm  
      me.n1set    = starterrpm;
      me.n2set    = 0.05; # try to reach max. 5% rotor rpm during startup, otherwise rotor will not move at all during fist seconds
      
      # starting, check starter and ignition
      if (me.n1 > me.n1_min and me.ignitionIn.getValue() ) {
         # switch to idle running engine if conditions are ok n1>idle
         me.state = IDLE;
      }
    }
    
    if (me.state==IDLE and me.n1 > me.n1_min) {      
      # idle, hold idle n1, n2 datums,
      # in idle power can be adjusted from external modules
      
      me.n1set = me.n1_idle + me.pwr_adjust;
      me.n2set = me.n2_idle + me.pwr_adjust;
      me.pwrLP.filter( me.pwr_idle + me.pwr_adjust);
      
      # decay only until idle rpm is reached
      if (me.decay and me.n2<=me.n2_idle) 
         me.decay=0;
      
    }
    
    if (me.state==FLIGHT and me.n1 > me.n1_min) {
      me.n2set = me.table["ias-vs-nr"].get(ias);
      
      if (me.n2 < 0.95 and me.spoolup) {
         # during spool-up
         me.pwrLP.filter( me.pwr_flight );      
      } else {
         # in flight mode power is set to full power and directly controlled via (YASIM) governor!
         me.pwrLP.set( 1.0 );
         me.spoolup=0;
      }
      # n1 is fed back from yasim via trq
      me.n1set = me.table["pwr-vs-n1"].get(clamp(me.power));    
    }
  
    if (me.state==TRAIN and me.n1 > me.n1_min) {
      me.n2set = me.n2_train;
      me.pwrLP.filter( me.pwr_flight );      
      me.n1set = me.n1_idle;    
        
    }    
        
    # while starting, n1 must follow starter rpm  
    if (me.state==START) {
      me.n1 = me.n1LP.set(me.n1set);
    } else {
      me.n1 = me.n1LP.filter(me.n1set);
    }
    
    #
    # max. available engine power 
    # from engine state
    #
    
    me.maxreltorque = me.pwrLP.get();
    
    #
    # update engine temperature TOT
    # depends on table data of n1, d(n1)/dt and TOT at ignition value
    #
    
    var targetT = (me.table["n1-vs-tot"].get(me.n1)-oat) * (me.state>=IDLE) * (1.0+((me.dn1/dt)>0.01)*me.tot_dn1dt_factor) +
           (me.tot_ignite_deg-oat) * (me.state==START) * me.ignitionIn.getValue() +
           oat;
    
    #
    # TOT time constant: decay slowly when OFF but fast if engine running
    #
    
    if (me.state==OFF and me.n1<0.1) 
       me.totLP.coeff = me.tot_cooltime_s;
    else 
       me.totLP.coeff = me.tot_timeconst_s;

    me.tot.setValue( me.totLP.filter(targetT) );
    
    #
    # update fuel flow per hour, FF follows n1
    #
    
    var FF_kg = 0;
    
    if (me.state <= IDLE)
      FF_kg = (me.n1/me.n1_idle) * me.fuelflow_idle_kgh;
    else  
      FF_kg = me.n1 * me.fuelflow_max_kgh;
    
    # LB/h
    me.ff.setValue(FF_kg * me.fuelpress * KG2LB);  
    
    # consume fuel from supply tank in Gal. (FF is per hour):
    me.supply.consume(FF_kg * me.fuelpress * KG2GAL * dt / 3600);    
    
    #
    # Oiltemperature: assume a weighted mix of engine TOT temp and n1
    # At TOT=700 deg C and at n1=100% the oiltemp reaches its nominal value
    #

    var targetOilT = clamp(0.5*me.totLP.get()/700 + 0.5*me.n1) * (me.state>=IDLE);
    me.oilt.setValue(me.oiltLP.filter(oat + targetOilT*(me.oiltemp_nominal_degc-oat)));

    #
    # Oilpressure :
    #
    
    var targetOilP = (me.n1 > me.n1_min)*me.oilpress_nominal_bar;
    me.oilp.setValue(me.oilpLP.filter(targetOilP));
    
    #
    # write to properties :
    #
    
    me.n1pct.setValue(me.n1*100);
    me.n1rpm.setValue(me.n1*me.n1_rpm_max);
    me.runningOut.setValue(me.state > START);
    me.powerIn.setValue(me.pwrLP.get());
    me.maxRelTrqOut.setValue(me.maxreltorque);
    
    me.dn1 = me.n1-me.n1old;
    me.n1old = me.n1;
    
    me.n2LP.filter( me.n2set );
    
  },
  update_n2: func (shaft) { 
    
    # n2, freewheel and torque calc.
    
    #NEW: freewheeling state computation replaced by a prop-rule
    me.freewheeling = me.freewheelOut.getValue();
    
    # engine powers and follows rotor
    # torque normalized from power and rpm
    # (power must be devided by rpm to yield torque, 
    # but this seems to strongly over estimate torque at low rpms)
    
    me.n2old = me.n2;
    
    # abs. shaft speed and pwr normalized
    var rpmN = shaft.rpm / me.shaft_rpm_max;
    var trq_Nm = 0;
    me.power = shaft.trq / me.power_max;
    
    # n2 cannot be faster than the rotor, force rotor speed 
    # if in spoolup and if engine is loaded
    
    if (me.state==FLIGHT and me.freewheeling < 0.5)
       me.n2 = min(rpmN, me.n2LP.get());
    else
       me.n2 = clamp(me.n2LP.get(), 0, rpmN); 
    
    # update trq from n2 relative to the rotor rpm
    # trq needs special treatment because of divison
    # by rpm
        
    if (rpmN>0.001)
        var trq_Nm = shaft.trq / (shaft.rpm * RPM2RADS) * (1-me.freewheeling);
      
    #
    # write trq, n2 and shaft speed properties
    #
    
    me.powerOutWatt.setValue(shaft.trq);
    me.powerOut.setValue(me.power*100);
    
    me.trqnm.setValue(me.trqLP.filter(trq_Nm * (rpmN>me.n2_no_trq)));
    me.trqpct.setValue(me.trqLP.get()/me.trq_max_Nm*100);
    
    me.n2pct.setValue(me.n2*100);
    me.n2rpm.setValue(me.n2*me.n2_rpm_max);
    me.rpm.setValue(me.n2*me.shaft_rpm_max);
    
  },
  adjust_power: func(p) { 
      me.pwr_adjust = p; 
  }
};


# Transmission class ==============================================================
# connects the turbine(s) to the FDM via rotor rpm, torque and max_rel_torque 

var Transmission = {
  new: func (super) {
    var m = { parents: [Transmission] };
    #m.rotorN = param.rpm;
    m.gearratio = [1,1];
    m.totaltrq=0;
    m.rpm=0;
    m.numeng=0;
    m.power=0;
    m.yasim_rotor_rpm=0;
    m.mgb_oiltemp_nominal_degc=0;
    m.mgb_oiltemp_trq_influence=0;
    m.mgb_oilpress_nominal_bar=0;
    m.mgb_oilpress_min_nr=0;
    m.mgb_oiltemp_cooltime_s=0;
    m.kp = 17;
    m.kd = 900;
    
    # yasim needs engine 0 magneto on for start
    m.magneto = props.globals.initNode("/controls/engines/engine[0]/magnetos", 1, "INT");
    m.oilt = props.globals.initNode("/rotors/gear/mgb-oil-temperature-degc",1);
    m.oilp = props.globals.initNode("/rotors/gear/mgb-oil-pressure-bar",1);

    m.rotor_rpm = super.rotor_rpm;
    m.torque = super.torque;
    m.target_rel_rpm = super.target_rel_rpm;
    m.max_rel_torque = super.max_rel_torque;
    m.oatnode = super.oatnode;
    m.iasnode = super.iasnode;
    m.table = super.table;
    m.engine = super.engine;

    return m;
  },
  init: func (n, shaftrpm) {
    me.numeng = n;
    me.power = 0;
    # yasim needs engine 0 magneto on for start
    me.magneto.setValue(1);
    me.oiltLP = aircraft.lowpass.new(me.mgb_oiltemp_cooltime_s);
    me.oilpLP = aircraft.lowpass.new(5);
     
    foreach (var i; [0,1]) 
       me.gearratio[i] = me.yasim_rotor_rpm/shaftrpm[i];
     
  },
  update: func (dt, shaft) {
  
    # distribute power between engines 
    
    var rpm = (me.rotor_rpm.getValue() or 0)/me.yasim_rotor_rpm;
    var torqueIn = me.torque.getValue() or 0;
    var oat = me.oatnode.getValue() or 0;
    var ias = me.iasnode.getValue() or 0;
    
    # difference to Nr datum:
    var rpmdiff = me.table["ias-vs-nr"].get(ias) - rpm;
    
    #
    # power split calc between engines
    # from engines freewheeling states
    #
    
    var trq = [0,0];
    var f = [0,0];
    var fw = [0,0]; # power per engine weighted by n2 diff
    me.power = 0;    
           
    # sync based on engine freewheel states     
    fw[1]=1-me.engine[1].freewheeling;
    fw[0]=1-me.engine[0].freewheeling;
    me.power = shaft[0].pw*fw[0] + shaft[1].pw*fw[1];
    
    if (me.power>0) {
       # get power returned (consumed) by Yasim
       me.totaltrq = clamp(torqueIn, 0, 1e10);
    } else {
       # prevent division by zero
       me.power=0.00001;
       me.totaltrq = 0;
    }
        
    #NEW: max. power limit from sum of both engines        
    #setprop("controls/rotor/gov/maxrelpower", me.power/me.numeng);
    
    #alternatively, using YASIMs internal PD-controller
    setprop("controls/rotor/maxreltorque", me.power/me.numeng);
    
    # distribute yasim trq between engines,
    # relative between the two engines.    
    
    var ratio = fw[0]/( fw[1]+fw[0] );
    if (debug.isnan(ratio)) {
        ratio = 0.5;
    }
    f[0]=ratio;
    f[1]=1-ratio;
    
     # distribute torque, return absolute rpm on shaft
     foreach (var i; [0,1])
       trq[i] = {rpm: rpm*me.yasim_rotor_rpm/me.gearratio[i], 
                 trq: me.totaltrq * f[i]};

    # MGB oil pressure
    var targetOilP = (rpm > me.mgb_oilpress_min_nr) * me.mgb_oilpress_nominal_bar;
    me.oilp.setValue( me.oilpLP.filter(targetOilP));
    
    # MGB oil temperature (trq scaling is arbitrary: 100 kW)
    var targetOilT = oat + rpm * (me.mgb_oiltemp_nominal_degc-oat) * (1 - me.mgb_oiltemp_trq_influence) + 
                    torqueIn/1e5 * me.mgb_oiltemp_trq_influence;
        
    me.oilt.setValue( me.oiltLP.filter(targetOilT));
      
    return trq;
  }
};


# Propulsion class helpers ==============================================================

var parsetree = func (root) {
    var elements = {};
    proplist = root.getChildren();
    
    foreach (var x; proplist) {
      var a = x.getValue();
      var b = string.replace(x.getName(),"-","_");
      
      # new? make empty vector
      if (!contains(elements,b))
         elements[b] = [];
          
      if (a == nil)
        append(elements[ b ], parsetree(x));
      else
        append(elements[ b ], a);
        
    }
    
    # reduce where only one element 
    foreach (var y; keys(elements))
       if (size(elements[y])==1)
          elements[y] = elements[y][0];
    
    return elements;
};

# import parameters from a hash into object if scalar
var importto = func (obj, node) {
    var x=0;
    foreach(var a; keys(node)) 
      if (typeof(node[a]) == "scalar") {
         x = num(node[a]);
         if (contains(obj,a))
            obj[a] = (x==nil) ? node[a] : x;
         else
            die("propulsion: unknown parameter " ~ a);
      }
};

var parsetable = func (tbl) {
  var out = [];
  var x = split(" ",tbl);
  foreach (var y; x) {
    var i = split(",",y);
    var u = [];
    foreach (var k; i) 
       append(u, num(k));
    append(out,u);    
  }
  return out;
};

# Propulsion class  ==============================================================

var Propulsion = {
  new: func() {
    var m = { parents: [Propulsion] };
    m.table = {};
    
    # engines/rotor =====================================================
    m.rotor_rpm = props.globals.getNode("rotors/main/rpm");
    m.torque = props.globals.getNode("rotors/gear/total-torque", 1);
    m.collective = props.globals.getNode("controls/engines/engine[0]/throttle");
    m.target_rel_rpm = props.globals.getNode("controls/rotor/reltarget", 1);
    m.max_rel_torque = props.globals.getNode("controls/rotor/maxreltorque", 1);
    m.oatnode = props.globals.getNode("environment/temperature-degc");
    m.iasnode = props.globals.getNode("velocities/airspeed-kt");
   
    m.engine = [Turbine.new(0, m), Turbine.new(1, m)];
    m.transmission = Transmission.new(m);
    
    return m;
  },  
  parseprops: func () {
    
    # read model config data from property tree
    
    var elements = parsetree(props.globals.getNode("sim/systems/propulsion"));

    if (size(elements.turbines.turbine) != elements.num_engines)
      die("propulsion: number of engines incorrect in XML!");
    
    # parse tables section and fill tables var
    
    if (contains(elements, "tables")) {
      for(var n=0; n<size(elements.tables.table); n+=1) {
          var atable = elements.tables.table[n];
          me.table[atable.name] = LUT.new( parsetable(atable.tableData) );
      }
    }
    
    # import parameters to engine objects

    if (size(elements.turbines.turbine) >= 1) {
      importto(me.engine[0], elements.turbines);
      importto(me.engine[0], elements.turbines.turbine[0]);
    } 

    if (size(elements.turbines.turbine) == 2) {
      importto(me.engine[1], elements.turbines);
      importto(me.engine[1], elements.turbines.turbine[1]);
    } 

    if (!contains(elements, "transmission")) {
        die("propulsion: transmission missing in XML!");
    } else {
        importto(me.transmission, elements.transmission); 
    }
    
    me.numeng = size(me.engine);
  },  
  init: func () {
    
    me.parseprops();
    
    me.transmission.init(me.numeng, [me.engine[0].shaft_rpm_max, me.engine[1].shaft_rpm_max]);
    foreach (var i; [0,1])
       me.engine[i].init();
    
    # NEW: disable YASIM rotor target RPM control
    setprop("controls/rotor/reltarget", 2.0);    

  },
  quickstart: func () {
    foreach (var i; [0,1])
       me.engine[i].quickstart();
  },
  update: func (dt) {
    
    # get total power provided by engine(s)
    foreach (var i; [0,1])
       me.engine[i].update_n1(dt);
        
    var n2 = [me.engine[0].n2LP.get(), me.engine[1].n2LP.get()];
    
    #set point for the property rule PD-controller
    #setprop("controls/rotor/gov/reltarget-internal", max(n2[0], n2[1]) );
    
    # alternatively,  with YASIMs internal PD-controller 
    setprop("controls/rotor/reltarget", max(n2[0], n2[1]) );
    
    # feed total power to transmission
    var shaft = me.transmission.update(dt,[{state: me.engine[0].state, pw: me.engine[0].maxreltorque, rpm: n2[0] },
                                           {state: me.engine[1].state, pw: me.engine[1].maxreltorque, rpm: n2[1] } ] );
    
    # feed shaft rpm and torque back to engine(s)
    foreach (var i; [0,1]) {
       me.engine[i].update_n2(shaft[i]);      
    }
  }
    
};
