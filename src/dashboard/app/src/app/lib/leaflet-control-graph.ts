import * as L from "leaflet";

export class LeafletControlGraph extends L.Control {

    override onAdd(map: L.Map): any {
        const mapGraph = L.DomUtil.create('div') as HTMLDivElement;
        mapGraph.id = 'map_graph_div';
        mapGraph.style.width = 'auto';


        const mapGraphToggleContainer = document.createElement('div');
        mapGraph.appendChild(mapGraphToggleContainer);
        mapGraphToggleContainer.id = 'map_graph_div_toggle';
        mapGraphToggleContainer.className = 'graphToggleContainerRight';


        const mapGraphGraphContainer = document.createElement('div');
        mapGraph.appendChild(mapGraphGraphContainer);
        mapGraphGraphContainer.id = 'map_graph_div_graph_container';
        mapGraphGraphContainer.style.overflow = 'hidden';
        mapGraphGraphContainer.style.width = '0px';
        mapGraphGraphContainer.style.height = '420px';
        mapGraphGraphContainer.style.transition = '0.5s';


        const mapGraphGraphBackground = document.createElement('div');
        mapGraphGraphContainer.appendChild(mapGraphGraphBackground);
        mapGraphGraphBackground.id = 'map_graph_div_graph';
        mapGraphGraphBackground.style.border = '1px solid rgba(255, 255, 255, 1)';
        mapGraphGraphBackground.style.cursor = 'default';
        mapGraphGraphBackground.style.padding = '9px';
        mapGraphGraphBackground.style.backgroundColor = 'rgba(255,255,255,0.85)';
        mapGraphGraphBackground.style.borderRadius = '5px';
        mapGraphGraphBackground.style.width = '400px';
        mapGraphGraphBackground.style.height = '400px';




        L.DomEvent
            .addListener(mapGraph, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

        return mapGraph;
    } // END FUNCTION onAdd

    override onRemove(map: L.Map): void {
        // Nothing to do here
    } // END FUNCTION onRemove

    addToggleButton(clickFunction) {

        const mapGraphToggleContainer = document.getElementById('map_graph_div_toggle')
        const mapGraphToggleButton = document.createElement('button');
        mapGraphToggleContainer.appendChild(mapGraphToggleButton);
        mapGraphToggleButton.className = 'graphToggleContainerButtonRight';
        mapGraphToggleButton.id = 'map_graph_div_toggle_button';

        mapGraphToggleButton.addEventListener('click', clickFunction);
    } // END FUNCTION addToggleButton


    constructor(options?: L.ControlOptions) {
        super(options);
    } // END FUNCTION constructor
} // END CLASS LeafletControlGraph

