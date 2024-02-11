# Melchior FRANZ, < mfranz # aon : at >


var sun = {
 init: func () {
      me.sun = "sim/model/sun-on-panel";
      me.sun_angle = "sim/time/sun-angle-rad";
      me.timeh = "sim/time/local-day-seconds";
      me.head = "orientation/heading-deg";
      setprop(me.sun, 0);

      me.r = "rendering/scene/ambient/red";
      me.g = "rendering/scene/ambient/green";
      me.b = "rendering/scene/ambient/blue";
      settimer(func me.update(),0.2);
 },

 update: func () {
      var x = getprop(me.sun_angle);
      var heading = getprop(me.head);
      var pitch = 0; #todo: include pitch in calc.
      
      # very simple sun direction estimation
      var time = getprop(me.timeh)/3600;
      var sundir = time / 24 * 360;
      var sunang = x / math.pi*180;

      var relsundir = math.abs(heading - sundir);
      var relsunang = math.abs(pitch - sunang);
      
      var illum = ( getprop(me.r)+getprop(me.g)+getprop(me.b) )/3;
      
      var out = ((illum > 0.3) and (relsundir > 90) and (relsunang > 10 and relsunang < 70));
      setprop( me.sun, out);
      settimer(func me.update(),0.2);
    }
};
       
sun.init();      
