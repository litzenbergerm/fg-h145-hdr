# ==============================================================================
# Original Boeing 747-400 pfd by Gijs de Rooy
# Modified for 737-800 by Michael Soitanen
# Modified for EC145 by litzi
# ==============================================================================

setprop("instrumentation/efis/efb/page",0);
adc["efbpage"] = Sensor.new({prop: "instrumentation/efis/efb/page" });

page_setup["efb"] = func (i) {
  
  p = mfd[i].add_page("efb", HELIONIXPATH~"svg/efb.svg");

  # MFD top row button labels
  # ============================
  
  p.add_cond("fndBtn",  {offset: isin("fnd", mfd[i].pages) > -1 } );
  p.add_cond("vmdBtn",  {offset: isin("vmd", mfd[i].pages) > -1 } );
  p.add_cond("navdBtn", {offset: isin("navd", mfd[i].pages) > -1 } );
  p.add_cond("dmapBtn", {offset: isin("dmap", mfd[i].pages) > -1 } );
  p.add_cond("miscBtn", {offset: isin("misc", mfd[i].pages) > -1 } );
  p.add_cond("efbBtn", {offset: 0}  );

  # EFB pages
  # ============================
  var maxpg=5;
  
  #hide all pages except TOC (page number =0)
  
  for (var page=1; page<=maxpg; page=page+1)
    p.add_cond("pg"~page, {offset: 0});
  
  #callbacks for page update
  
  for (var page=0; page<=maxpg; page=page+1)
    p.add_cond("pg"~page, {sensor: adc.efbpage, equals: page});
  
  p.add_cond("pageBtn", {sensor: adc.efbpage, notequal: 0});
  p.add_text("pageNo", {sensor: adc.efbpage, format: "PAGE %d/99" });
  
}; # func
