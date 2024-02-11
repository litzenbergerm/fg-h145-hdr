# linear interpolator class
# by litzi
# adopted from Zivko Edge
# original author Torsten Dreyer

var LUT = {
  new: func(pairs, nn=100)
  {
    var m = { parents: [ LUT ] };
    m.pairs = pairs;
    m.pairs2 = [];
    m.d = [];
    m.n = size(pairs)-1;
    
    m.resample(nn);
    
    return m;
  },
  resample: func (nn) {
    # resample pairs with equal spacing for
    # improved speed    
    me.res = (me.pairs[-1][0]-me.pairs[0][0])/(nn-1);
    
    for (var x=me.pairs[0][0]; x<me.pairs[-1][0]; x+=me.res) 
       append(me.pairs2, [x, me._get(x)]);
    
    me.nn = size(me.pairs2)-1;
    
    for (var i=0; i<me.nn; i+=1)
       append(me.d, (me.pairs2[i+1][1]-me.pairs2[i][1])/me.res);
  },
  _get: func(x)
  {
    if( x <= me.pairs[0][0] ) {
     return me.pairs[0][1];
    }
    if( x >= me.pairs[me.n][0] ) {
      return me.pairs[me.n][1];
    }
    for( var i = 0; i < me.n; i+=1 ) {
      if( x > me.pairs[i][0] and x <= me.pairs[i+1][0] ) {
        var x1 = me.pairs[i][0];
        var x2 = me.pairs[i+1][0];
        var y1 = me.pairs[i][1];
        var y2 = me.pairs[i+1][1];
        return (x-x1)/(x2-x1)*(y2-y1)+y1;
      }
    }
    return me.pairs[i][1];
  },
  get: func (x)
  {
    x = math.clamp(x,me.pairs2[0][0],me.pairs2[-1][0]);
    var i = math.clamp( int( (x-me.pairs2[0][0]) / me.res), 0, me.nn-1);
    return me.pairs2[i][1]+(x-me.pairs2[i][0])*me.d[i];
  },
  del: func() {}  
};
