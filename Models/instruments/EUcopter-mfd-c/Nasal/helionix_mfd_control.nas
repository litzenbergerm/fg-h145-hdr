# mfd.nas to drive gauges of the VMD MFD #

### Eucopter MFD panel control class ###

# Bezel Button Numbers
#    2 3 4 5 6 7 
#[1]<pwr           
# 25                8
# 24                9
# 23                10
# 22                11
# 21                12
# 20                13
#  19 18 17 16 15 14

var EUcoptermfd = {
    new: func(i) {
        var m = { parents: [Timerloop.new(), EUcoptermfd] };
        m.id = i;
        m.idx = 0;
        m.pwr_state = 0;
        
        #split the modes list
        m.list = split(",", getprop("/instrumentation/mfd["~i~"]/mode-list"));
        
        #handle empty mode list, no pages return nil
        if (m.list[0] == "")
           return nil;
        
        m.l = size(m.list);
        m.supply = getprop("instrumentation/mfd["~i~"]/supply");
        m.supply = m.supply == nil ? "systems/electrical/volts" : m.supply;        
        m.pwr_sw = "instrumentation/mfd["~i~"]/pwr-sw-pos";
        m.mode = "instrumentation/mfd["~i~"]/mode";
        m.initstep = "instrumentation/mfd["~i~"]/initstep";       
        m.navsrprop = "instrumentation/mfd["~i~"]/nav-source";
        m.bear0prop = "instrumentation/mfd["~i~"]/bearing-source[0]";       
        m.bear1prop = "instrumentation/mfd["~i~"]/bearing-source[1]";
        m.efbpageprop = "instrumentation/efis/efb/page";
        m.numprop = adc.vmdnum.path;
        
        m.volt = 21; # mfd min. voltage demand (just a guess)
        setprop(m.mode, m.list[0] );
        #setprop(m.navsrprop, "NAV1"); 

        setprop(m.initstep, 1 );
        return m;
        },
        
    update: func() {
      var v = getprop(me.supply);
      v = v == nil ? 0 : v;
      
         
      if (!me.pwr_state and getprop(me.pwr_sw) and v >= me.volt) {
      
        # start with the first page mode in list
        setprop(me.mode, me.list[0]);
        me.idx = 0;
        me.pwr_state = 1;        
        
      } else if (!getprop(me.pwr_sw) or v < me.volt) {
      
        me.pwr_state=0;
        setprop(me.mode, "off"); # show blank screen
        
      }
      
      # special procedure for the init screen animation
      
      if (getprop(me.mode) == "init" and me.idx==0) {         
        me.idx = 1;
        
        #show the 2nd test pattern, 1.5 sec later
        settimer(func {setprop(me.initstep,2)}, 1.5 );
        
        if (me.list[1]=="fnd") {
          # timers to show the FND AI Alignment screen
          settimer(func {setprop(me.initstep,3)}, 3.0 );
          settimer(func {me.modeprop(); },        8.0 );
          settimer(func {setprop(me.initstep,1)}, 9.0 );
        } else {
          settimer(func {me.modeprop(); },        3.0 );
          settimer(func {setprop(me.initstep,1)}, 4.0 );
        }  
      }
       
       # show/hide canvas
       foreach(var m; me.list)
        if (me.getmode() == m)   
            mfd[me.id][m].show();
        else       
            mfd[me.id][m].hide();

      },

    modeprop: func () setprop(me.mode, me.list[me.idx]),

    setmode: func (modestr) {
        i = isin(modestr, me.list); 
        if (i>=0) { me.idx=i; me.modeprop();}
        },

    getmode: func () {
        return getprop(me.mode);
        },
        
    pwr_on: func () {
        setprop(me.pwr_sw, 1);
        },
    
    pwr_off: func () {
        setprop(me.pwr_sw, 0);
        },
    
    clickon: func (n) {
        var mymode = me.getmode();
        if (me.pwr_state) {
          if (n==2) me.setmode("fnd");
          if (n==3) me.setmode("navd");
          if (n==4) me.setmode("vmd");
          if (n==5) me.setmode("dmap");
          if (n==7) me.setmode("efb");
          if (n==9) {
              if (mymode=="dmap") toggleprop(planprop);              
              }
          if (n==10) {
              if (mymode=="navd") cycleprop(me.bear0prop, ["NAV1", "ADF1", "FMS"]);
              if (mymode=="vmd") toggleprop(me.numprop);              
              }
          if (n==11) {
              if (mymode=="fnd") cycleprop(me.bear0prop, ["NAV1", "ADF1", "FMS"]);
              if (mymode=="navd") cycleprop(me.bear1prop, ["NAV2", "ADF1", "FMS"]);
              }
          if (n==12) {
              if (mymode=="fnd") cycleprop(me.bear1prop, ["NAV2", "ADF1", "FMS"]);
              }              
          if (n==13) {
              #if (mymode=="dmap") cycleprop(databpage, [0,1,2]);
              }              
          if (n==16) {
               #if (mymode=="DMAP") cycleprop(databpage, [0,1,2]);
               }
          if (n==19) {
               if (mymode=="navd" or mymode=="fnd") {
                  # set AP source and activate AP heading mode
                  var s = getprop(me.navsrprop);
                  #setprop("instrumentation/efis/nav-source", (s=="NAV1") ? "" : s);
                  setprop("instrumentation/efis/fnd/nav-source", s);
                  cycleprop("autopilot/locks/heading", ["nav1-hold", ""]);
                  }
               if (mymode=="efb") setprop(me.efbpageprop,0);
                  
               }
          if (n==20) {
              if (mymode=="fnd") cycleprop(me.navsrprop, ["NAV1", "NAV2", "FMS"]);
              if (mymode=="navd") cycleprop(me.navsrprop, ["NAV1", "NAV2", "FMS"]);
              }
          if (n==21) {
              if (mymode=="vmd") cycleprop(datapageprop, [0,1,2]);
              }
          if (n==22) {
              if (mymode=="navd") cycleprop(datafltr, [1,2,3] );
              }
          if (n==24) {
              if (mymode=="navd" or mymode=="dmap") cycleprop(rngprop, [5, 10, 20, 40]);
              if (mymode=="efb") {
                 if (getprop(me.efbpageprop)==0)
                     setprop(me.efbpageprop,20)
                 else
                     decrprop(me.efbpageprop);
              }
            }
          if (n==25) {
              if (mymode=="navd") cycleprop(me.navsrprop, ["NAV1", "NAV2", "FMS"]);
              if (mymode=="dmap") toggleprop(mapprop);
              if (mymode=="efb") {
                 if (getprop(me.efbpageprop)==0)
                     setprop(me.efbpageprop,1)
                 else
                     incrprop(me.efbpageprop);
               }
            }
          if (n==99) {
             cycleprop(me.mode, me.list);
            }
        }
        if (n==1) toggleprop(me.pwr_sw); # toggle power property !!!
     }
};
