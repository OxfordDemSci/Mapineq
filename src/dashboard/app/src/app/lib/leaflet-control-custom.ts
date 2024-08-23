import * as L from 'leaflet';


export class LeafletControlWatermark extends L.Control {

  override onAdd(map: L.Map): any {
    const waterMark = L.DomUtil.create('img') as HTMLImageElement;
    waterMark.src = 'assets/map/watermark/map_app_icon.svg';
    waterMark.style.width = '60px';
    waterMark.style.height = '60px';
    // waterMark.style.cursor = 'pointer';
    waterMark.id = 'map_watermark_img';
    waterMark.title = 'Mapineq logo';

    L.DomEvent
      .addListener(waterMark, 'contextmenu', L.DomEvent.stopPropagation)
      .addListener(waterMark, 'mousedown', L.DomEvent.stopPropagation)
      .addListener(waterMark, 'click', L.DomEvent.stopPropagation)
      .addListener(waterMark, 'dblclick', L.DomEvent.stopPropagation)
      /*
      .addListener(waterMark, 'click', () => {
        window.open('https://www.mapineq.eu', '_blank');
      })*/;

    return waterMark;
  } // END FUNCTION onAdd

  override onRemove(map: L.Map): void {
    // Nothing to do here
  } // END FUNCTION onRemove

  constructor(options?: L.ControlOptions) {
    options = options || {position: 'bottomleft'};
    super(options);
  } // END FUNCTION constructor
} // END CLASS LeafletControlWatermark


export class LeafletControlLegend extends L.Control {

  override onAdd(map: L.Map): any {
    const mapLegend = L.DomUtil.create('div') as HTMLImageElement;
    mapLegend.id = 'map_legend_div';
    mapLegend.style.width = 'auto';
    mapLegend.style.border = '1px solid rgba(255, 255, 255, 1)';
    mapLegend.style.cursor = 'default';
    mapLegend.style.padding = '10px';
    mapLegend.style.backgroundColor = 'rgba(255,255,255,0.85)';
    mapLegend.style.borderRadius = '5px';

    L.DomEvent
      .addListener(mapLegend, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

    return mapLegend;
  } // END FUNCTION onAdd

  override onRemove(map: L.Map): void {
    // Nothing to do here
  } // END FUNCTION onRemove

  constructor(options?: L.ControlOptions) {
    super(options);
  } // END FUNCTION constructor
} // END CLASS LeafletControlLegend


export class LeafletControlMapButtons extends L.Control {

  mapButtonsContainerDiv: any;
  mapButtonsContainerDivId: string;

  override onAdd(map: L.Map): any {
    //console.log('onAdd(): ', this.mapButtonsContainerDivId);

    this.mapButtonsContainerDiv = L.DomUtil.create('div') as HTMLDivElement;
    this.mapButtonsContainerDiv.id = this.mapButtonsContainerDivId;
    this.mapButtonsContainerDiv.style.width = '34px';
    this.mapButtonsContainerDiv.style.cursor = 'default';

    L.DomEvent
      .addListener(this.mapButtonsContainerDiv, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

    return this.mapButtonsContainerDiv;
  } // END FUNCTION onAdd

  setContainerDivId(newId): void {
    this.mapButtonsContainerDivId = newId;
    this.mapButtonsContainerDiv.id = this.mapButtonsContainerDivId;
  } // END FUNCTION setContainerDivId

  addButton(callback, options?): void {
    options = options || {};

    let newButton = document.createElement('div');
    this.mapButtonsContainerDiv.appendChild(newButton);
    newButton.className = 'map_button';

    if (typeof options.id !== 'undefined') {
      newButton.id = options.id;
    }
    if (typeof options.tabIndex !== 'undefined') {
      newButton.tabIndex = options.tabIndex;
    } else {
      newButton.tabIndex = 0;
    }
    if (typeof options.title !== 'undefined') {
      newButton.title = options.title;
      newButton.ariaLabel = options.title;
    }
    if (typeof options.class !== 'undefined') {
      newButton.classList.add(options.class);
    }
    if (typeof options.mat_icon !== 'undefined') {
      newButton.classList.add('map_button_mat_icon');
      /*
      let mat_icon = document.createElement('mat-icon');
      newButton.appendChild(mat_icon);
      mat_icon.innerHTML = options.mat_icon;
      */
      newButton.innerHTML = options.mat_icon;
    }

    newButton.addEventListener('keypress', (event) => {
      // alert('OK' + newButton.id);
      if (event.key === "Enter") {
        event.preventDefault();
        newButton.click();
      }
    });

    if (typeof options.toggle !== 'undefined') {
      if (newButton.classList.contains('map_button_mat_icon')  &&  typeof options.switch === 'undefined') {
        if (newButton.innerHTML === options.toggle[1]) {
          newButton.classList.add('map_button_mat_icon_inactive');
        }
      }


      newButton.addEventListener('click', () => {
        // TOGGLE BUTTON ICON
        if (newButton.classList.contains('map_button_mat_icon')) {
          if (newButton.innerHTML === options.toggle[0]) {
            newButton.innerHTML = options.toggle[1];
          } else {
            newButton.innerHTML = options.toggle[0];
          }
          if (typeof options.switch === 'undefined') {
            if (newButton.classList.contains('map_button_mat_icon_inactive')) {
              newButton.classList.remove('map_button_mat_icon_inactive');
            } else {
              newButton.classList.add('map_button_mat_icon_inactive');
            }
          }
        } else {
          if (newButton.classList.contains(options.toggle[0])) {
            newButton.classList.remove(options.toggle[0]);
            newButton.classList.add(options.toggle[1]);
          } else {
            newButton.classList.remove(options.toggle[1]);
            newButton.classList.add(options.toggle[0]);
          }
        }

        // ACTUAL CALLBACK
        callback();
      });
    } else {
      newButton.addEventListener('click', callback);
    }
  }  // END FUNCTION addButton

  createMapButtonStyles(): void {
    // console.log('createMapButtonStyles() ...');

    let styleMapButtonsExists = false;

    let existingStyles = document.getElementsByTagName('style');

    for (let i = 0; i < existingStyles.length; i++) {
      if (typeof existingStyles[i].id !== 'undefined'  &&  existingStyles[i].id === 'style_map_buttons') {
        styleMapButtonsExists = true;
      }
    }

    if (!styleMapButtonsExists) {
      let style = document.createElement('style');
      style.setAttribute('type', 'text/css');
      style.id = 'style_map_buttons';

      let css = '';
      // css += '.cssClass { color: #f00; }';

      css += '.map_button {                        ' +
        '      position: relative;                 ' +
        '      /*                                  ' +
        '      display: inline-block;              ' +
        '      */                                  ' +
        '      /*overflow: hidden;*/               ' +
        '      /*float: right;                     ' +
        '      clear: right;*/                     ' +
        '      /*                                  ' +
        '      margin: 0px 5px 5px 0px             ' +
        '      */                                  ' +
        '      margin: 0px 0px 0px 0px;            ' +
        '      padding: 0;                         ' +
        '      width: 30px;                        ' +
        '      height: 30px;                       ' +
        '      border-radius: 4px;                 ' +
        '      border: 2px solid rgba(0,0,0,0.2);  ' +
        '      text-align: center;                 ' +
        '      background-color: #fff;             ' +
        '      background-repeat: no-repeat;       ' +
        '      background-position: 50% 50%;       ' +
        '      /*background-size: 24px 24px;*/     ' +
        '      background-size: 30px 30px;         ' +
        '      background-clip: content-box;       ' +
        '      font-size: 20px;                    ' +
        '      /*line-height: 30px;*/              ' +
        '    }                                     ';

      css += '.map_button + .map_button { margin-top: 10px; }';

      css += '.map_button:hover {                      ' +
        '      background-color: #f4f4f4;              ' +
        '      cursor: pointer;                        ' +
        '    }                                         ';

      css += '.map_button_mat_icon {                       ' +
        '  /*                                              ' +
        '  color: red;                                     ' +
        '  text-align: center;                             ' +
        '  */                                              ' +
        '  font-family: \'Material Icons\';                ' +
        '  font-weight: normal;                            ' +
        '  font-style: normal;                             ' +
        '  font-size: 24px;  /* Preferred icon size */     ' +
        '  display: inline-block;                          ' +
        '  line-height: 1.25;                              ' +
        '  text-transform: none;                           ' +
        '  letter-spacing: normal;                         ' +
        '  word-wrap: normal;                              ' +
        '  white-space: nowrap;                            ' +
        '  direction: ltr;                                 ' +
        '  /* Support for all WebKit browsers. */          ' +
        '  -webkit-font-smoothing: antialiased;            ' +
        '  /* Support for Safari and Chrome. */            ' +
        '  text-rendering: optimizeLegibility;             ' +
        '                                                  ' +
        '  /* Support for Firefox. */                      ' +
        '  -moz-osx-font-smoothing: grayscale;             ' +
        '                                                  ' +
        '  /* Support for IE. */                           ' +
        '  font-feature-settings: \'liga\';                ' +
        '}                                                 ';

      css += '.map_button_mat_icon_inactive {              ' +
        '  color: #808080;                                 ' +
        //'  text-align: center;                              ' +
        '}                                                 ';

      let map_button_postfixes = ['navigate', 'navigate_off', 'map', 'photo']; // 'nld'
      map_button_postfixes.forEach(postfix => {
        css += '.map_button_' + postfix + ' {                                             ' +
          '  background-image: url("assets/map/buttons/map_button_' + postfix + '.svg");  ' +
          '}                                                                              ';
      })

      style.innerHTML = css;

      document.getElementsByTagName('head')[0].appendChild(style);
    }
  } // END FUNCTION createMapButtonStyles

  override onRemove(map: L.Map): void {
    // Nothing to do here
  } // END FUNCTION onRemove

  constructor(options?: L.ControlOptions) {
    options = options || {position: 'topright'};
    super(options);

    this.createMapButtonStyles();

    //console.log('constructor ---');
    this.mapButtonsContainerDivId = 'map_buttons_container_div';
  } // END FUNCTION constructor
} // END CLASS LeafletControlMapButtons


export class LeafletControlMapButtonsLeft extends LeafletControlMapButtons {
  constructor(options?: L.ControlOptions) {
    options = options || {position: 'topleft'};
    super(options);

    //console.log('constructor LEFT');
    this.mapButtonsContainerDivId = 'map_buttons_container_div_left';
  } // END FUNCTION constructor
} // END CLASS LeafletControlMapButtonsLeft


export class LeafletControlMapButtonsRight extends LeafletControlMapButtons {
  constructor(options?: L.ControlOptions) {
    options = options || {position: 'topright'};
    super(options);

    //console.log('constructor RIGHT');
    this.mapButtonsContainerDivId = 'map_buttons_container_div_right';
  } // END FUNCTION constructor
} // END CLASS LeafletControlMapButtonsRight


