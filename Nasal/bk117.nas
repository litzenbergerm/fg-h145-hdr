# Melchior FRANZ, < mfranz # aon : at >



if (!contains(globals, "cprint"))
	var cprint = func nil;

var devel = !!getprop("devel");
var quickstart = !!getprop("quickstart");

var sin = func(a) math.sin(a * D2R);
var cos = func(a) math.cos(a * D2R);
var pow = func(v, w) math.exp(math.ln(v) * w);
var npow = func(v, w) v ? math.exp(math.ln(abs(v)) * w) * (v < 0 ? -1 : 1) : 0;
var clamp = func(v, min = 0, max = 1) v < min ? min : v > max ? max : v;
var normatan = func(x, slope = 1) math.atan2(x, slope) * 2 / math.pi;
var bell = func(x, spread = 2) pow(math.e, -(x * x) / spread);
var max = func(a, b) a > b ? a : b;
var min = func(a, b) a < b ? a : b;

# liveries =========================================================
aircraft.livery.init("Aircraft/ec145/Models/liveries");

#retractable landinglight================================================
var landinglight = aircraft.door.new("/controls/landinglight", 2);

#doors=========================
leftFrontDoor = aircraft.door.new( "/sim/model/bk117/door-positions/leftFrontDoor", 4, 0 );
rightFrontDoor = aircraft.door.new( "/sim/model/bk117/door-positions/rightFrontDoor", 4, 0 );
leftBackDoor = aircraft.door.new( "/sim/model/bk117/door-positions/leftBackDoor", 4, 0 );
rightBackDoor = aircraft.door.new( "/sim/model/bk117/door-positions/rightBackDoor", 4, 0 );
leftRearDoor = aircraft.door.new( "/sim/model/bk117/door-positions/leftRearDoor", 4, 0 );
rightRearDoor = aircraft.door.new( "/sim/model/bk117/door-positions/rightRearDoor", 4, 0 );


# timers ============================================================
aircraft.timer.new("/sim/time/hobbs/helicopter", nil).start();
var elapsedN = props.globals.getNode("/sim/time/elapsed-sec", 1);


# strobes ===========================================================
var strobe_switch = props.globals.initNode("controls/lighting/strobe", 1, "BOOL");
aircraft.light.new("sim/model/bk117/lighting/strobe-top", [0.05, 1.00], strobe_switch);
aircraft.light.new("sim/model/bk117/lighting/strobe-bottom", [0.05, 1.03], strobe_switch);

# beacons ===========================================================
var beacon_switch = props.globals.initNode("controls/lighting/beacon", 1, "BOOL");
aircraft.light.new("sim/model/bk117/lighting/beacon-top", [0.62, 0.62], beacon_switch);
aircraft.light.new("sim/model/bk117/lighting/beacon-bottom", [0.63, 0.63], beacon_switch);


# nav lights ========================================================
var nav_light_switch = props.globals.initNode("controls/lighting/nav-lights", 1, "BOOL");
var visibility = props.globals.getNode("environment/visibility-m", 1);
var sun_angle = props.globals.getNode("sim/time/sun-angle-rad", 1);
var nav_lights = props.globals.getNode("sim/model/bk117/lighting/nav-lights", 1);

var nav_light_loop = func {
	if (nav_light_switch.getValue())
           nav_lights.setValue( visibility.getValue() < 5000 or sun_angle.getValue() > 1.4);
	else
           nav_lights.setValue(0);

	settimer(nav_light_loop, 3);
}

nav_light_loop();

# init propulsion and load the XML definition for turbines and gearbox:

io.include("propulsion.nas");
var propulsion = Propulsion.new();

# make a fuel system with 3 tanks, the Tank class is defined in propulsion.nas:

var fuel = {
        main: Tank.new(0),
        # by litzi: ec145 needs two supply tanks, one per engine
        supply: [ Tank.new(1), Tank.new(2) ],
	init: func {
                # init the 3 tanks
                me.main.init();
                me.supply[0].init();
                me.supply[1].init();
                
                var fuel = props.globals.getNode("/consumables/fuel");
		me.pump_capacity = 10 * L2GAL / 60; # same pumps for transfer and supply
		me.total_galN = fuel.getNode("total-fuel-gals", 1);
		me.total_lbN = fuel.getNode("total-fuel-lbs", 1);
		me.total_normN = fuel.getNode("total-fuel-norm", 1);
		
		# transfer pumps electrical supply
		var elec = props.globals.getNode("/systems/electrical/outputs/");
                # transfer pumps (feed supply tanks from main tank) have more than 23V power?
                setlistener(elec.getNode("fuelpump-fwd",1), func(n) {me.trans1 = (n.getValue() or 0)>23;} , 1);
                setlistener(elec.getNode("fuelpump-aft",1), func(n) {me.trans2 = (n.getValue() or 0)>23;} , 1);
                            
		setlistener("/sim/freeze/fuel", func(n) me.freeze = n.getBoolValue(), 1);
		me.capacity = me.main.capacity + me.supply[0].capacity + me.supply[1].capacity;
		me.warntime = 0;
		me.update(0);
		print("fuel system ... initialized");
	},
	update: func(dt) {
		
		foreach (a; me.supply) {
                    var free = a.capacity - a.level();
                    if (free > 0) {
                        var trans_flow = (me.trans1 + me.trans2) * me.pump_capacity;
                        a.consume( -me.main.consume(min(trans_flow * dt, free)));
                    }
                }

		var level = me.main.level() + me.supply[0].level() + me.supply[1].level();;
		me.total_galN.setValue(level);
		me.total_lbN.setValue(level * GAL2LB);
		me.total_normN.setValue(level / me.capacity);
	},
	level: func(eng) {
		return me.supply[eng].level();
	},
	consume: func(eng, amount) {
		return me.freeze ? 0 : me.supply[eng].consume(amount);
	},
};
        

var fuel_pump_prime = {
   p: ["/controls/fuel/tank[1]/prime-pump", "/controls/fuel/tank[2]/prime-pump"],
   on: func(n) {
     setprop(me.p[n], 1); 
     },
   
   off: func(n) {
     setprop(me.p[n], 0); 
     },
   
   get: func(n) {
     return( getprop(me.p[n]) ); 
   }
};

###this is the bit we need###
var fuel_pump_xfer = {
   p: ["/controls/switches/fuel/transfer-pump[0]", "/controls/switches/fuel/transfer-pump[1]"],
   on: func(n) {
     setprop(me.p[n], 1); },
   
   off: func(n) {
     setprop(me.p[n], 0); },
   
   get: func(n) {
     return( getprop(me.p[n]) ); }
};


###create fuel endurance in sec###
var endu = "/consumables/fuel/endurance-sec";
var ff = ["/engines/engine[0]/fuel-flow_pph", 
          "/engines/engine[1]/fuel-flow_pph"];

var fuelendurance = func () {
  var ffx =  (getprop(ff[0]) or 0) + (getprop(ff[1]) or 0); #pound/h
             
  if (ffx > 0) {
      # max. 10h indication
      var ss = min( getprop("/consumables/fuel/total-fuel-lbs")/ffx*3600, 36000);
      interpolate(endu, ss, 10);
  } else {
      setprop(endu, 0);
  }
};


###create hydraulic pressure in bar###
var hydraulic = {
  # hydraulic pumps are powered by the accessory drive
  # of the main gear box
  
  p: ["/systems/hydraulic/sys[0]/hyd-press-bar","/systems/hydraulic/sys[1]/hyd-press-bar"],
  
  init: func() {
     setprop(me.p[0], 0);
     setprop(me.p[1], 0);
  },
  
  update: func() {
     var r=propulsion.rotor_rpm.getValue();
     var targetpress = (r > 30)*93 + max(0,r/36); # 105 bar according to EASA operational evaluation board report 
     var testsw = getprop("/controls/test/hydraulic");
     
     # if hydr test sw (overhead panel) is set to test, disable respective system
     
     interpolate(me.p[0], targetpress * (testsw != 2), 2);
     interpolate(me.p[1], 1.01*targetpress * (testsw != 0), 2);
  }
};

var vert_speed_fpm = props.globals.initNode("/velocities/vertical-speed-fpm");

if (devel) {
	setprop("/instrumentation/altimeter/setting-inhg", getprop("/environment/pressure-inhg"));
        setprop("/controls/fuel/tank[1]/prime-pump",1);
        setprop("/controls/fuel/tank[2]/prime-pump",1);
        
	setlistener("/sim/signals/fdm-initialized", func {
		settimer(func {
			screen.property_display.x = 10;
			screen.property_display.y = 500;
			screen.property_display.format = "%.3g";
			screen.property_display.add(
                                "/controls/engines/engine/throttle",                 
				propulsion.rotor_rpm,
				"/consumables/fuel/total-fuel-gals",
				"L",
				propulsion.engine[0].runningOut,
                                propulsion.engine[0].starterOut,
                                propulsion.engine[0].powerOut,
                                propulsion.engine[0].freewheelOut,
				"/controls/engines/engine[0]/power",
				propulsion.engine[0].maxRelTrqOut,
				propulsion.engine[0].n1pct,
				propulsion.engine[0].n2pct,
				propulsion.engine[0].outOfFuelOut,
				"R",
                                propulsion.engine[1].runningOut,
                                propulsion.engine[1].starterOut,
                                propulsion.engine[1].powerOut,
                                propulsion.engine[1].freewheelOut,
                                "/controls/engines/engine[1]/power",
                                propulsion.engine[1].maxRelTrqOut,
                                propulsion.engine[1].n1pct,
                                propulsion.engine[1].n2pct,
                                propulsion.engine[1].outOfFuelOut,
				"X",
				"/sim/model/gross-weight-kg",
				"/sim/systems/electrical/battery/charge-amph",
				"/position/altitude-ft",
				"/position/altitude-agl-ft",
				"/instrumentation/altimeter/indicated-altitude-ft",
				"/environment/temperature-degc",
				"/velocities/airspeed-kt",
				vert_speed_fpm
			);
		}, 1);
	});
}



var mouse = {
	init: func {
		me.x = me.y = nil;
		me.savex = nil;
		me.savey = nil;
		setlistener("/sim/startup/xsize", func(n) me.centerx = int(n.getValue()) / 2, 1);
		setlistener("/sim/startup/ysize", func(n) me.centery = int(n.getValue()) / 2, 1);
		setlistener("/devices/status/mice/mouse/mode", func(n) me.mode = n.getValue(), 1);
		setlistener("/devices/status/mice/mouse/button[1]", func(n) {
			me.mmb = n.getValue();
			if (me.mode)
				return;
			if (me.mmb) {
				me.savex = me.x;
				me.savey = me.y;
				gui.setCursor(me.centerx, me.centery, "none");
			} else {
				gui.setCursor(me.savex, me.savey, "pointer");
			}
		}, 1);
		setlistener("/devices/status/mice/mouse/x", func(n) me.x = n.getValue(), 1);
		setlistener("/devices/status/mice/mouse/y", func(n) me.update( me.y = n.getValue() ), 1);
	},
	update: func {
		if (me.mode or !me.mmb)
			return;

		if (var dy = -me.y + me.centery)
			#engines.adjust_power(dy * 0.005);

		gui.setCursor(me.centerx, me.centery);
	},
};


var startup = func {
        if (procedure.stage < 0) {
                procedure.step = 1;
                procedure.next();
        }
};
        
var shutdown = func {
        if (procedure.stage > 0) {
                procedure.step = -1;
                procedure.next();
        }
};        

var procedure = {
	stage: -999,
	step: nil,
	loopid: 0,
	reset: func {
		me.loopid += 1;
		me.stage = -999;
		step = nil;
		propulsion.init();
	},
	next: func(delay = 0) {
		if (crashed)
			return;
		if (me.stage < 0 and me.step > 0 or me.stage > 0 and me.step < 0)
			me.stage = 0;

		settimer(func { me.stage += me.step; me.process(me.loopid) }, delay * !quickstart);
		# interpolate(startup_proc,startup_proc.getPath()+delay,delay);
	},
	process: func(id) {
                # the model-specific startup processes are defined in enginecontrol-h145.nas and enginecontrol-ec145-nas
        }
};


# blade vibration absorber pendulum
var pendulum = props.globals.getNode("/sim/model/bk117/absorber-angle-deg", 1);
var update_absorber = func {
         pendulum.setValue( 90 * clamp(abs( propulsion.rotor_rpm.getValue() ) / 90));
};



var vibration = { # and noise ...
	init: func {
		me.lonN = props.globals.initNode("/rotors/main/vibration/longitudinal");
		me.latN = props.globals.initNode("/rotors/main/vibration/lateral");
		me.soundN = props.globals.initNode("/sim/sound/vibration");
		me.airspeedN = props.globals.getNode("/velocities/airspeed-kt");
		me.vertspeedN = props.globals.getNode("/velocities/vertical-speed-fps");

		me.groundspeedN = props.globals.getNode("/velocities/groundspeed-kt");
		me.speeddownN = props.globals.getNode("/velocities/speed-down-fps");
		me.angleN = props.globals.initNode("/velocities/descent-angle-deg");
		me.dir = 0;
	},
	update: func(dt) {
		var airspeed = me.airspeedN.getValue();
		if (airspeed > 145) { # overspeed vibration
			var frequency = 2000 + 500 * rand();
			var v = 0.49 + 0.5 * normatan(airspeed - 160, 10);
			var intensity = v;
			var noise = v * internal;

		} elsif (airspeed > 30) { # Blade Vortex Interaction (BVI)    8 deg, 65 kts max?
			var frequency = propulsion.rotor_rpm.getValue() * 4 * 60;
			var down = me.speeddownN.getValue() * FT2M;
			var level = me.groundspeedN.getValue() * NM2M / 3600;
			me.angleN.setValue(var angle = math.atan2(down, level) * R2D);
			var speed = math.sqrt(level * level + down * down) * MPS2KT;
			angle = bell(angle - 9, 13);
			speed = bell(speed - 65, 450);
			var v = angle * speed;
			var intensity = v * 0.10;
			var noise = v * (1 - internal * 0.4);

		} else { # hover
			var rpm = propulsion.rotor_rpm.getValue();
			var frequency = rpm * 4 * 60;
			var coll = bell(propulsion.collective.getValue(), 0.5);
			var ias = bell(airspeed, 600);
			var vert = bell(me.vertspeedN.getValue() * 0.5, 400);
			var rpm = 0.477 + 0.5 * normatan(rpm - 350, 30) * 1.025;
			var v = coll * ias * vert * rpm;
			var intensity = v * 0.10;
			var noise = v * (1 - internal * 0.4);
		}

		me.dir += dt * frequency;
		me.lonN.setValue(cos(me.dir) * intensity);
		me.latN.setValue(sin(me.dir) * intensity);
		me.soundN.setValue(noise);
	},
};




# sound =============================================================

# stall sound
var stall = props.globals.getNode("rotors/main/stall", 1);
var stall_filtered = props.globals.getNode("rotors/main/stall-filtered", 1);

var stall_val = 0;
stall.setValue(0);

var update_stall = func(dt) {
	var s = getprop(stall.getPath());
	if (s < stall_val) {
		var f = dt / (0.3 + dt);
		stall_val = s * f + stall_val * (1 - f);
	} else {
		stall_val = s;
	}
	var c = propulsion.collective.getValue();
	stall_filtered.setValue(stall_val + 0.006 * (1 - c));
}



# skid slide sound
var Skid = {
	new: func(n) {
		var m = { parents: [Skid] };
		var soundN = props.globals.getNode("sim/model/bk117/sound", 1).getChild("slide", n, 1);
		var gearN = props.globals.getNode("gear", 1).getChild("gear", n, 1);

		m.compressionN = gearN.getNode("compression-norm", 1);
		m.rollspeedN = gearN.getNode("rollspeed-ms", 1);
		m.frictionN = gearN.getNode("ground-friction-factor", 1);
		m.wowN = gearN.getNode("wow", 1);
		m.volumeN = soundN.getNode("volume", 1);
		m.pitchN = soundN.getNode("pitch", 1);

		m.compressionN.setValue(0);
		m.rollspeedN.setValue(0);
		m.frictionN.setValue(0);
		m.volumeN.setValue(0);
		m.pitchN.setValue(0);
		m.wowN.setValue(1);
		m.self = n;
		return m;
	},
	update: func {
		me.wow = me.wowN.getValue();
		if (me.wow < 0.5)
			return me.volumeN.setValue(0);

		var rollspeed = abs(me.rollspeedN.getValue() );
		me.pitchN.setValue(rollspeed * 0.6);

		var s = normatan(20 * rollspeed);
		var f = clamp((me.frictionN.getValue() - 0.5) * 2);
		var c = clamp(me.compressionN.getValue() * 2);
		var vol = s * f * c;
		me.volumeN.setValue(vol > 0.1 ? vol : 0);
	}
};
        
var skids = [];
for (var i = 0; i < 4; i += 1)
        append(skids, Skid.new(i));

#var antislide = props.globals.initNode("/gear/antislide");
var update_slide = func {
        var wow = 0;
        foreach (var s; skids) {
                s.update();
                wow += s.wow;
        }
        #antislide.getPath(),wow > 0 ? 1 - rotor_rpm.getPath() / 10 : 0);
}

var internal = 1;
setlistener("sim/current-view/view-number", func {
        internal = getprop("sim/current-view/internal");
}, 1);



# crash handler =====================================================
var crash = func {
	if (arg[0]) {
		# crash
		setprop("sim/model/bk117/tail-angle-deg", 35);
		setprop("sim/model/bk117/shadow", 0);
		setprop("sim/model/bk117/doors/door[0]/position-norm", 0.2);
		setprop("sim/model/bk117/doors/door[1]/position-norm", 0.9);
		setprop("sim/model/bk117/doors/door[2]/position-norm", 0.2);
		setprop("sim/model/bk117/doors/door[3]/position-norm", 0.6);
		setprop("sim/model/bk117/doors/door[4]/position-norm", 0.1);
		setprop("sim/model/bk117/doors/door[5]/position-norm", 0.05);
		setprop("rotors/main/rpm", 0);
		setprop("rotors/main/blade[0]/flap-deg", -60);
		setprop("rotors/main/blade[1]/flap-deg", -50);
		setprop("rotors/main/blade[2]/flap-deg", -40);
		setprop("rotors/main/blade[3]/flap-deg", -30);
		setprop("rotors/main/blade[0]/incidence-deg", -30);
		setprop("rotors/main/blade[1]/incidence-deg", -20);
		setprop("rotors/main/blade[2]/incidence-deg", -50);
		setprop("rotors/main/blade[3]/incidence-deg", -55);
		setprop("rotors/tail/rpm", 0);
		strobe_switch.setValue(0);
		beacon_switch.setValue(0);
		nav_light_switch.setValue(0);
		propulsion.engine[0].n2pct.setValue(0);
		propulsion.engine[1].n2pct.setValue(0);
		#torque_pct.setValue(torque_val = 0);
		stall_filtered.setValue(stall_val = 0);

	} else {
		# uncrash (for replay)
		setprop("sim/model/bk117/tail-angle-deg", 0);
		setprop("sim/model/bk117/shadow", 1);
		doors.reset();
		setprop("rotors/tail/rpm", 2219);
		setprop("rotors/main/rpm", 442);
		for (i = 0; i < 4; i += 1) {
			setprop("rotors/main/blade[" ~ i ~ "]/flap-deg", 0);
			setprop("rotors/main/blade[" ~ i ~ "]/incidence-deg", 0);
		}
		strobe_switch.setValue(1);
		beacon_switch.setValue(1);
		propulsion.engine[0].n2pct.setValue(100);
		propulsion.engine[1].n2pct.setValue(100);
	}
}




# "manual" rotor animation for flight data recorder replay ============
var rotor_step = props.globals.getNode("sim/model/bk117/rotor-step-deg");
var blade1_pos = props.globals.getNode("rotors/main/blade[0]/position-deg", 1);
var blade2_pos = props.globals.getNode("rotors/main/blade[1]/position-deg", 1);
var blade3_pos = props.globals.getNode("rotors/main/blade[2]/position-deg", 1);
var blade4_pos = props.globals.getNode("rotors/main/blade[3]/position-deg", 1);
var rotorangle = 0;

var rotoranim_loop = func {
	var i = rotor_step.getValue();
	if (i >= 0.0) {
		blade1_pos.setValue(rotorangle);
		blade2_pos.setValue(rotorangle + 90);
		blade3_pos.setValue(rotorangle + 180);
		blade4_pos.setValue(rotorangle + 270);
		rotorangle += i;
		settimer(rotoranim_loop, 0.1);
	}
}

var init_rotoranim = func {
	if (rotor_step.getValue() >= 0.0)
		settimer(rotoranim_loop, 0.1);
}



# view management ===================================================

var flap_mode = 0;
var down_time = 0;
controls.flapsDown = func(v) {
	if (!flap_mode) {
		if (v < 0) {
			down_time = elapsedN.getValue();
			flap_mode = 1;
			dynamic_view.lookat(
					5,     # heading left
					-20,   # pitch up
					0,     # roll right
					0.2,   # right
					0.6,   # up
					0.85,  # back
					0.2,   # time
					55,    # field of view
			);
		} elsif (v > 0) {
			flap_mode = 2;
			gui.popupTip("AUTOTRIM", 1e10);
			aircraft.autotrim.start();
		}

	} else {
		if (flap_mode == 1) {
			if (elapsedN.getValue() < down_time + 0.2)
				return;

			dynamic_view.resume();
		} elsif (flap_mode == 2) {
			aircraft.autotrim.stop();
			gui.popdown();
		}
		flap_mode = 0;
	}
}


# register function that may set me.heading_offset, me.pitch_offset, me.roll_offset,
# me.x_offset, me.y_offset, me.z_offset, and me.fov_offset
#
dynamic_view.register(func {
	var lowspeed = 1 - normatan(me.speedN.getValue() / 50);
	var r = sin(me.roll) * cos(me.pitch);

	me.heading_offset =						# heading change due to
		(me.roll < 0 ? -50 : -30) * r * abs(r);			#    roll left/right

	me.pitch_offset =						# pitch change due to
		(me.pitch < 0 ? -50 : -50) * sin(me.pitch) * lowspeed	#    pitch down/up
		+ 15 * sin(me.roll) * sin(me.roll);			#    roll

	me.roll_offset =						# roll change due to
		-15 * r * lowspeed;					#    roll
});


# main() ============================================================

var delta_time = props.globals.getNode("/sim/time/delta-sec", 1);
var hi_heading = props.globals.getNode("/instrumentation/heading-indicator/indicated-heading-deg", 1);
var vertspeed = props.globals.initNode("/velocities/vertical-speed-fps");
var gross_weight_lb = props.globals.initNode("/yasim/gross-weight-lbs");
var gross_weight_kg = props.globals.initNode("/sim/model/gross-weight-kg");
props.globals.getNode("/instrumentation/adf/rotation-deg", 1).alias(hi_heading);

var main_loop = func {
	props.globals.removeChild("autopilot");
	if (replay)
		setprop("/position/gear-agl-m", getprop("/position/altitude-agl-ft") * 0.3 - 1.2);
	
	vert_speed_fpm.setValue( vertspeed.getValue() * 60 );
	#gross_weight_kg.getPath(),gross_weight_lb.getPath() * LB2KG);

	var dt = delta_time.getValue();
        fuel.update(dt);
	propulsion.update(dt);
	update_stall(dt);
	vibration.update(dt);
	settimer(main_loop, 0);
}

var aux_loop = func {
        update_slide();
        #update_volume();
        update_absorber();       
        fuelendurance();
        hydraulic.update();
        settimer(aux_loop, 0.1);
}
  
  
var replay = 0;
var crashed = 0;

setlistener("/sim/signals/fdm-initialized", func {
	gui.menuEnable("autopilot", 1);
	#init_rotoranim();
	vibration.init();
	mouse.init();
        fuel.init();
        propulsion.init(); # this inits all other engine related stuff
        hydraulic.init();
        
	#init_weapons();
	#setlistener("/sim/model/livery/file", reconfigure, 1);

	propulsion.collective.setValue(1);

	setlistener("/sim/signals/reinit", func(n) {
		n.getBoolValue() and return;
		cprint("32;1", "reinit");
		procedure.reset();
		collective.setValue(1);
		aircraft.livery.rescan();
		reconfigure();
		crashed = 0;
	});

	setlistener("sim/crashed", func(n) {
		cprint("31;1", "crashed ", n.getValue());
		propulsion.engine[0].timer.stop();
		propulsion.engine[1].timer.stop();
		if (n.getBoolValue()) crash(crashed = 1);
	});

	setlistener("/sim/freeze/replay-state", func(n) {
              replay = n.getValue();
              cprint("33;1", (replay) ? "replay" : "pause" );
              if (crashed) crash(!getprop(n.getPath()));
	});

	main_loop();
	aux_loop();
	
	if (devel and quickstart)
		propulsion.quickstart();
});


