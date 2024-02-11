# test routines for tuning engine PD controller

var tune = func(a,b,c) {
bk117.engines.engine[0].Fadec.Kp = a;
bk117.engines.engine[0].Fadec.Kd = b;
bk117.engines.engine[0].pwrLP.coeff = c;

print( "set:" , bk117.engines.engine[0].Fadec.Kp, ", ", 
bk117.engines.engine[0].Fadec.Kd, ", ",
bk117.engines.engine[0].pwrLP.coeff);

};


