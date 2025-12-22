function main(el, x, data) {
  document.body.style.backgroundColor = 'black';
  document.body.style.color = 'white';

  var df = data.df,
    imputed = data.imputed,
    choices = data.all_choices,
    axes = data.current_axes.slice(),
    countries = Array.from(new Set(df.map(d => d.Country)));

  // 1) Build dropdown container
  var ctr = document.createElement('div');
  ctr.style.marginBottom = '8px';
  ctr.style.backgroundColor = 'black';
  ctr.style.color = 'white';
  ctr.style.padding = '6px';

  ctr.innerHTML =
    'X-axis: <select id="selX"></select>' +
    '&nbsp;Y-axis: <select id="selY"></select>' +
    '&nbsp;Z-axis: <select id="selZ"></select>'+
    '&nbsp;&nbsp;<input type="checkbox" id="togErr"> <label for="togErr" style="font-size:12px">Show Imputed Uncertainty</label>';
  el.parentNode.insertBefore(ctr, el);

  // 2) Populate the <select>s
  ['selX', 'selY', 'selZ'].forEach(function (id, i) {
    var sel = document.getElementById(id);
    choices.forEach(function (ch) {
      var opt = document.createElement('option');
      opt.value = ch; opt.text = ch;
      if (ch === axes[i]) opt.selected = true;
      sel.appendChild(opt);
    });

    sel.style.backgroundColor = 'black';
    sel.style.color = 'white';
    sel.style.border = '1px solid white';
    sel.style.padding = '2px 4px';
  });

  // 3) The update function
  function update() {
    axes[0] = document.getElementById('selX').value;
    axes[1] = document.getElementById('selY').value;
    axes[2] = document.getElementById('selZ').value;

    var newX = [], newY = [], newZ = [], newT = [];
    var errX = [], errY = [], errZ = [];
    var showErr = document.getElementById('togErr').checked;
    countries.forEach(function (ct) {
      var rows = df.filter(d => d.Country === ct);
      newX.push(rows.map(r => +r[axes[0]]));
      newY.push(rows.map(r => +r[axes[1]]));
      newZ.push(rows.map(r => +r[axes[2]]));

      // get error bars if toggled
      var getErr = function (r, axis) {
        if (!showErr) return 0;
        var isImputed = imputed.find(i => i.geo === r.geo && i[axis] === 1);
        var hasUpper = r[axis + '_upper'] !== undefined;
        return (isImputed && hasUpper) ? (+r[axis + '_upper'] - +r[axis]) : 0;
      };
      errX.push(rows.map(r => getErr(r, axes[0])));
      errY.push(rows.map(r => getErr(r, axes[1])));
      errZ.push(rows.map(r => getErr(r, axes[2])));
      // errX.push(rows.map(r => r[axes[0] + '_upper'] ? (+r[axes[0] + '_upper'] - +r[axes[0]]) : 0));
      // errY.push(rows.map(r => r[axes[1] + '_upper'] ? (+r[axes[1] + '_upper'] - +r[axes[1]]) : 0));
      // errZ.push(rows.map(r => r[axes[2] + '_upper'] ? (+r[axes[2] + '_upper'] - +r[axes[2]]) : 0));
      newT.push(rows.map(function (r) {
        return 'Case: ' + r.CaseID +
          '<br>' + axes[0] + ' = ' + r[axes[0]] +
          '<br>' + axes[1] + ' = ' + r[axes[1]] +
          '<br>' + axes[2] + ' = ' + r[axes[2]];
      }));
    });

    // 4) Restyle & Relayout
    Plotly.restyle(el, {
      x: newX,
      y: newY,
      z: newZ,
      text: newT,
      'error_x.array': errX,
      'error_y.array': errY,
      'error_z.array': errZ
    });
    Plotly.relayout(el, {
      'scene.xaxis.title.text': axes[0],
      'scene.yaxis.title.text': axes[1],
      'scene.zaxis.title.text': axes[2]
    });
  }

  // 5) Wire up the change events
  ['selX', 'selY', 'selZ', 'togErr'].forEach(function (id) {
    document.getElementById(id).addEventListener('change', update);
  });
  el.on('plotly_restyle', function (data) {
    // If the legend was used to hide/show traces, re-run the error bar logic
    if (data[0].visible) {
      update();
    }
  });
}
