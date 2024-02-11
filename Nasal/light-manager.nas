# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# adapted from A320 for H145 by litzi

var als_on = props.globals.getNode("");
var alt_agl = props.globals.getNode("position/gear-agl-ft");
var cur_alt = 0;

var Light = {
	new: func(n) {
		var light = {parents: [Light]};
		light.isOn = 0;
		
		light.Pos = {
			x: 0,
			y: 0,
			z: 0,
		};
		
		light.Color = {
			r: 0,
			g: 0,
			b: 0,
		};
		
		light.colorr = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-r[" ~ n ~ "]", 1);
		light.colorg = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-g[" ~ n ~ "]", 1);
		light.colorb = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/lightspot-b[" ~ n ~ "]", 1);
		light.dir = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/dir[" ~ n ~ "]", 1);
		light.size = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/size[" ~ n ~ "]", 1);
		light.posx = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-x-m[" ~ n ~ "]", 1);
		light.posy = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-y-m[" ~ n ~ "]", 1);
		light.posz = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/eyerel-z-m[" ~ n ~ "]", 1);
		
		if (n <= 1) {
			light.stretch = props.globals.getNode("/sim/rendering/als-secondary-lights/lightspot/stretch[" ~ n ~ "]", 1);
		}
		return light;
	},
	setColor: func(r,g,b) {
		me.Color.r = r;
		me.Color.g = g;
		me.Color.b = b;
	},
	setDir: func(dir) {
		me.dir.setValue(dir);
	},
	setSize: func(size) {
		me.size.setValue(size);
	},
	setStretch: func(stretch) {
		me.stretch.setValue(stretch);
	},
	
	setPos: func(x,y,z) {
		me.Pos.x = x;
		me.Pos.y = y;
		me.Pos.z = z;
	},
	
	on: func() {
		if (me.isOn) { return; }
		me.colorr.setValue(me.Color.r);
		me.colorg.setValue(me.Color.g);
		me.colorb.setValue(me.Color.b);
		me.isOn = 1;
	},
	
	off: func() {
		if (!me.isOn) { return; }
		me.colorr.setValue(0);
		me.colorg.setValue(0);
		me.colorb.setValue(0);
		me.isOn = 0;
	},
};

var lightManager = {

	lat_to_m: 110952.0,
	lon_to_m: 0.0,
	apos: 0,
	curAlt: 0,
	ll: [0,0],
	nav: 0,
	run: 0,
	vpos: 0,
	Pos: {
		alt: 0,
		heading: 0,
		headingSine: 0,
		headingCosine: 0,
		lat: 0,
		lon: 0,
	},
	
	Lights: {
		light: [
              Light.new(0),
              Light.new(1)
		]
    },
	
	# note: init method is aircraft specific. 
	
	update: func() {
		if (!me.run) {
			settimer ( func me.update(), 0.00);
			return;
		}
		
		me.curAlt = alt_agl.getValue() or 0;
		
		if (me.curAlt > 100) {
			settimer ( func me.update(), 1);
			return;
		}
		
		me.apos = geo.aircraft_position();
		me.vpos = geo.viewer_position();

		me.Pos.lat = me.apos.lat();
		me.Pos.lon = me.apos.lon();
		me.Pos.alt = me.apos.alt();
		me.Pos.heading = (getprop("orientation/model/heading-deg") or 0) * D2R;
		me.Pos.headingSine = math.sin(me.Pos.heading);
		me.Pos.headingCosine = math.cos(me.Pos.heading);
		me.lon_to_m = math.cos(me.Pos.lat*D2R) * me.lat_to_m;

        for (var i=0; i <= 1; i = i+1) {
			
            if (me.ll[i].getValue() != 0) {
                me.Lights.light[i].on();
            } else {
                me.Lights.light[i].off();
            }
		
            # light i position update from viewer_position
            
            me.apos.set_lat(me.Pos.lat + ((me.Lights.light[i].Pos.x + me.curAlt) * me.Pos.headingCosine + me.Lights.light[i].Pos.y * me.Pos.headingSine) / me.lat_to_m);
            me.apos.set_lon(me.Pos.lon + ((me.Lights.light[i].Pos.x + me.curAlt) * me.Pos.headingSine - me.Lights.light[i].Pos.y * me.Pos.headingCosine) / me.lon_to_m);
     
            me.Lights.light[i].posx.setValue((me.apos.lat() - me.vpos.lat()) * me.lat_to_m);
            me.Lights.light[i].posy.setValue(-(me.apos.lon() - me.vpos.lon()) * me.lon_to_m);
            me.Lights.light[i].posz.setValue(me.apos.alt()- (me.curAlt / 10) - me.vpos.alt());
            me.Lights.light[i].dir.setValue(me.Pos.heading);			
        }
		
		settimer ( func me.update(), 0.00);
	},
};

setlistener( "sim/rendering/shaders/skydome", func(v) {
	lightManager.run = v.getValue() ? 1 : 0;
}, 1, 0);
