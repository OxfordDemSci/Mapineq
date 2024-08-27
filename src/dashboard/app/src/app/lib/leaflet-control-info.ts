import * as L from "leaflet";

export class LeafletControlInfo extends L.Control  {

    constructor(options?: L.ControlOptions) {
        super(options);
    } // END FUNCTION constructor


    override onAdd(map: L.Map): any {
        /* /
        const mapSelectInformation = L.DomUtil.create('div') as HTMLDivElement;
        mapSelectInformation.id = 'map_selectinformation_div';
        mapSelectInformation.style.width = '400px';
        mapSelectInformation.style.border = '1px solid rgba(255, 255, 255, 1)';
        mapSelectInformation.style.cursor = 'default';
        mapSelectInformation.style.padding = '10px';
        mapSelectInformation.style.backgroundColor = 'rgba(255,255,255,0.85)';
        mapSelectInformation.style.borderRadius = '5px';

        L.DomEvent
            .addListener(mapSelectInformation, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

        return mapSelectInformation;
        /* */

        const mapInfo = L.DomUtil.create('div') as HTMLDivElement;
        mapInfo.id = 'map_info_div';
        mapInfo.style.width = 'auto';


        const mapInfoToggleContainer = document.createElement('div');
        mapInfo.appendChild(mapInfoToggleContainer);
        mapInfoToggleContainer.id = 'map_info_div_toggle';
        mapInfoToggleContainer.className = 'panelToggleContainerRight';


        const mapInfoInfoContainer = document.createElement('div');
        mapInfo.appendChild(mapInfoInfoContainer);
        mapInfoInfoContainer.id = 'map_info_div_info_container';
        mapInfoInfoContainer.style.overflow = 'hidden';
        mapInfoInfoContainer.style.width = '0px';
        //mapInfoInfoContainer.style.height = '420px';
        mapInfoInfoContainer.style.transition = '0.5s';


        const mapInfoInfoBackground = document.createElement('div');
        mapInfoInfoContainer.appendChild(mapInfoInfoBackground);
        mapInfoInfoBackground.id = 'map_info_div_info';
        mapInfoInfoBackground.style.border = '1px solid rgba(255, 255, 255, 1)';
        mapInfoInfoBackground.style.cursor = 'default';
        mapInfoInfoBackground.style.padding = '9px';
        mapInfoInfoBackground.style.backgroundColor = 'rgba(255,255,255,0.85)';
        mapInfoInfoBackground.style.borderRadius = '5px';
        mapInfoInfoBackground.style.width = '400px';
        //mapInfoInfoBackground.style.height = '400px';
        mapInfoInfoBackground.innerHTML = 'Sjoerd';




        L.DomEvent
            .addListener(mapInfo, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

        return mapInfo;

    } // END FUNCTION onAdd



    override onRemove(map: L.Map): void {
        // Nothing to do here
    } // END FUNCTION onRemove

    addToggleButton(clickFunction) {

        const mapInfoToggleContainer = document.getElementById('map_info_div_toggle')
        const mapInfoToggleButton = document.createElement('button');
        mapInfoToggleContainer.appendChild(mapInfoToggleButton);
        mapInfoToggleButton.className = 'panelToggleContainerButtonLeft';
        mapInfoToggleButton.id = 'map_info_div_toggle_button';

        mapInfoToggleButton.addEventListener('click', clickFunction);
    } // END FUNCTION addToggleButton


} // END CLASS LeafletControlInfo
