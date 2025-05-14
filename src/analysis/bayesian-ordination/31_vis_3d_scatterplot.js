function(el, x, data) {
  var df         = data.df,
      choices    = data.all_choices,
      axes       = data.current_axes.slice(),
      countries  = Array.from(new Set(df.map(d => d.Country)));

  // 1) Build dropdown container
  var ctr = document.createElement('div');
  ctr.style.marginBottom = '8px';
  ctr.innerHTML =
    'X-axis: <select id="selX"></select>' +
    '&nbsp;Y-axis: <select id="selY"></select>' +
    '&nbsp;Z-axis: <select id="selZ"></select>';
  el.parentNode.insertBefore(ctr, el);

  // 2) Populate the <select>s
  ['selX','selY','selZ'].forEach(function(id,i) {
    var sel = document.getElementById(id);
    choices.forEach(function(ch){
      var opt = document.createElement('option');
      opt.value = ch; opt.text = ch;
      if(ch === axes[i]) opt.selected = true;
      sel.appendChild(opt);
    });
  });

  // 3) The update function
  function update() {
    axes[0] = document.getElementById('selX').value;
    axes[1] = document.getElementById('selY').value;
    axes[2] = document.getElementById('selZ').value;

    var newX = [], newY = [], newZ = [], newT = [];
    countries.forEach(function(ct) {
      var rows = df.filter(d => d.Country === ct);
      newX.push(rows.map(r => +r[axes[0]]));
      newY.push(rows.map(r => +r[axes[1]]));
      newZ.push(rows.map(r => +r[axes[2]]));
      newT.push(rows.map(function(r){
        return 'Case: ' + r.CaseID +
               '<br>' + axes[0] + ' = ' + r[axes[0]] +
               '<br>' + axes[1] + ' = ' + r[axes[1]] +
               '<br>' + axes[2] + ' = ' + r[axes[2]];
      }));
    });

    // 4) Restyle & Relayout
    Plotly.restyle(el, { x: newX, y: newY, z: newZ, text: newT });
    Plotly.relayout(el, {
      'scene.xaxis.title': axes[0],
      'scene.yaxis.title': axes[1],
      'scene.zaxis.title': axes[2]
    });
  }

  // 5) Wire up the change events
  ['selX','selY','selZ'].forEach(function(id){
    document.getElementById(id).addEventListener('change', update);
  });
}
