# provides relative vectors from eye-point to aircraft lights
# in east/north/up coordinates the renderer uses
# Thanks to BAWV12 / Thorsten

# adapted from A320 for H145 by litzi

io.include("/Aircraft/ec145/Nasal/light-manager.nas");

lightManager.init = func() {

		setprop("/sim/rendering/als-secondary-lights/flash-radius", 13);
		setprop("/sim/rendering/als-secondary-lights/num-lightspots", 2);
		
		#strobe effect
		
		me.Lights.light[0].setPos(-3,0,2);
		me.Lights.light[0].setColor(0.4,0.4,0.4);
		me.Lights.light[0].setSize(10);
		me.Lights.light[0].setStretch(0);
		me.ll[0] = props.globals.getNode("/lightpack/strobe-light-active",1);
		
		#landing light effect
		
		me.Lights.light[1].setPos(35,0,2);
		me.Lights.light[1].setColor(0.7,0.7,0.7);
		me.Lights.light[1].setSize(8);
		me.Lights.light[1].setStretch(4);
		me.ll[1] = props.globals.getNode("/lightpack/landing-lights-active",1);
				
		me.update();
		
	};

lightManager.init();
