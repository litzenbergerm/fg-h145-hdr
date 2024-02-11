# Electrical Load Simulation, v1.1
# by Martin Litzenberger 'litzi'

# this model simulates load distribution among electrical consumers
# in a network.
# it is, however, not a physically correct model. it does not solve
# Ohms equations. current is equally shared across all consumers 
# regardless of the individual voltage drop between 
# supply and the consumer.
# it builds upon the electrical voltage simulation v1.1
# by Gary Neely 'Buckaroo' (see in 'electrical.nas').
# the network must be defined in System/electrical.xml

DEBUG = 0;

# in global scope

var conns =[];
var nodes = {};
var load_path = "loads";

 
# some helper functions  
var isin = func(a, b) {
  foreach(var i; a) if (i==b) return 1;
  return 0;
}

var copy_by_element = func (x) {
  var y = [];
  foreach(var i; x) 
      append(y, i);
  return y;
}    



# class Node..
var Node = {
  new: func(n) {
    var m = { parents: [Node] };

    m.in = [];
    m.out = []; # holds my in- and output connector indizes
    m.supp =[];
    m.name = n;
    m.I = 0;    
    m.draw = nil;
    m.vmin = nil;
    m.propload = nil;
    m.prop = components[n].getNode("prop").getValue();
    m.kind = components[n].getNode("kind").getValue();
    m.consumer = 0;
    m.supplier = 0;
    
    
    if (components[n].getNode("rated-draw") != nil) 
       m.draw = components[n].getNode("rated-draw").getValue();
    else
       m.draw = nil;
    
    if (components[n].getNode("volts-min") != nil) 
       m.vmin = components[n].getNode("volts-min").getValue();
    else
       m.vmin = 0;
       
    if (m.draw != nil) {
      # check what kind of node i am, a consumer need special setup
      m.kind = "consumer";
      m.consumer=1;
      m.propload =  string.replace(m.prop, "outputs", load_path); ;
      setprop(m.propload,0);
      
    } else if (m.kind == "alternator" or m.kind == "battery") {
      # prepare an output prop for the suppliers
      m.propload =  string.replace(m.prop, "suppliers", load_path); ;
      setprop(m.propload,0);
      m.supplier=1;
    } 
    
    return m;
  },  
  
  recurse: func (p, history, it) {
      # p holds the connection path consumer-connection1-connection2-..-supplier
      # history holds the history of all nodes that we have already passed
      
      if (me.supplier and it>0) {
        # path closed at a supplier, done.
        append(p, me.name);   
        nodes[p[0]].addsupp(p);
        
        if (DEBUG) debug.dump(p);
        
      } else {
        
        if (it>5) return;
        it += 1;
        
        foreach (var i; me.out) {
          # check if we are not in a loop?
          # note: to recurse we need by-element copy of the lists, otherwise they will be referenced as objects!
          if ( ! isin(history, conns[i].in ) )
            nodes[conns[i].in].recurse( append(copy_by_element(p), i), append(copy_by_element(history), me.name), it ); 
        }
      }
  },
        
  update: func () {
    # calc draw per supplier of a consumer
    if (me.consumer) {      
      var n = 0;
      var isactive = [];
      
      var v = getprop(me.prop) or 0;
      var I0 = (v >= me.vmin) ? me.draw : 0;
      
      foreach (var p; me.supp) {
        append(isactive, 1);
        
        # check state of all connectors for each supplier
        if ( size(p)>2 ) {
           foreach (var k; p[1:-2]) {
              if (conns[k].active == 0) {
                isactive[-1] = 0;
                break;
              }
           }
        }
        n += isactive[-1];          
      }
       
      setprop(me.propload, -I0);  
      
      # calculate output per connected node
      me.I = (n==0) ? 0 : I0/n;
      
      # update all the connected suppliers' current 
      for (var j=0; j < size(me.supp); j+=1) 
          nodes[me.supp[j][-1]].I += me.I*isactive[j];
      
    } else if (me.supplier)
      setprop(me.propload, me.I);  

  },

get: func ()
 return me.I,

addin: func(i)
 append(me.in, i),   

addout: func(i)
 append(me.out, i),
 
addsupp: func(o)
 append(me.supp, o),
 
resetcurrent: func()
 if (me.supplier) me.I=0,
};

var loads_init = func () {
  print("electrical loads init: analysing network...");
  
  # init the network analysis, get all output nodes and create objects
  foreach(var o; keys(components))
    nodes[o] = Node.new(o);

  # init the network analysis, get all connections

  for(var i=0; i<size(connector_list); i+=1) {
    
    var myout = connector_list[i].getNode("output").getValue();
    var myin = connector_list[i].getNode("input").getValue();   
    var switches = connector_list[i].getChildren("switch");   
    var mysw = [];       
    foreach(var switch; switches) 
        append(mysw, switch.getValue());
    
    # init all connections as active
    append(conns, {"in": myin, "out": myout, "active": 1, "sw": mysw});
    nodes[myin].addin(i);
    nodes[myout].addout(i);    

  }

  if (DEBUG) print("paths [Consumer,via-conn1,...via-connN,Supplier]");  
     
  foreach(var o; keys(nodes))
    if (nodes[o].kind == "consumer")
       nodes[o].recurse([o,], [o,], 0);
       
  print("...Done.");

};


var loads_update = func () {

 # update the state of all connectors in the network
    
 for(var i=0; i<size(connector_list); i+=1) {
              
    # check if the current through this connector is 0?
    var vin = getprop( nodes[conns[i].in].prop ) or 0;
    var vout = getprop( nodes[conns[i].out].prop ) or 0;
      
    # is the voltage drop good to drive a current?
    if (vin >= vout) {
       # Begin testing all associated switches       
       var test = 1;
       
       foreach(var switch; conns[i].sw) {
           test = getprop(switch);
           if (test == nil or test == 0) {
                test=0;
                break;
           }
       }
       conns[i].active = test; 
     } else {
       conns[i].active = 0;
     }
  }
  
  if (DEBUG) debug.dump(conns);

  settimer(loads_update_consumers, 0.333);
};
     
# update all node objects to propagate the current

var loads_update_consumers = func () {
  
  foreach(var o; keys(nodes)) {
     nodes[o].resetcurrent(); 
  }
     
  foreach(var o; keys(nodes)) {
     if (nodes[o].consumer) nodes[o].update(); 
  }
     
  settimer(loads_update_suppliers,0.333);
};
  
var loads_update_suppliers = func () {

  foreach(var o; keys(nodes)) {
     if (nodes[o].supplier) nodes[o].update(); 
     if (DEBUG) print(nodes[o].name,"\t",nodes[o].I);
  }
  
  # check loads
  var Itotal=0;  
  foreach(var o; keys(nodes)) {
     if (nodes[o].supplier or nodes[o].consumer) Itotal += getprop(nodes[o].propload); 
  }
  if (abs(Itotal) > 0.001 and DEBUG) print("Electrical: Warning total current mismatch:",Itotal);
  
};

# battery drain/charge simulation, 1sec update rate

var batt = {
  init: func () {
    me.root = props.globals.initNode("/sim/systems/electrical/battery");
    me.capa = me.root.getNode("capacity-amph").getValue();
    # get the nodes for current draw and source
    me.source = nodes[ me.root.getNode("source-component").getValue() ];
    me.draw = nodes[ me.root.getNode("draw-component").getValue() ];
    me.charge = me.root.getNode("charge-amph");    
    me.maxdraw = me.draw.draw;
  },
  
  update: func () {      
    # ampsec to amph
    var newcharge = me.charge.getValue() - me.totalcurrent()/3600;    
    me.charge.setValue( math.clamp(newcharge, 0, me.capa) );
    
    # battery draw depends on charge level!
    var chargenorm = newcharge / me.capa;
    me.draw.draw = me.maxdraw * ( (chargenorm < 0.5) ?  1.0 : (2 - 2*chargenorm));
  },
  
  totalcurrent: func () {
    # calc. total current from/into battery
    return getprop(me.source.propload) + getprop(me.draw.propload);
  } 
};



# main timer loop:
var loads_timer = maketimer(0.333, func loads_update() );
var batt_timer = maketimer(1, func batt.update() );

setlistener("/sim/signals/fdm-initialized", func () {
  loads_init();
  batt.init();
  loads_timer.start();
  batt_timer.start();
  }
);
