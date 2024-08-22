import * as L from "leaflet";

export class LeafletControlSelectInformation extends L.Control  {

    constructor(options?: L.ControlOptions) {
        super(options);
    }


    override onAdd(map: L.Map): any {
        const mapSelectInformation = L.DomUtil.create('div') as HTMLImageElement;
        mapSelectInformation.id = 'map_selectinformation_div';
        mapSelectInformation.style.width = 'auto';
        mapSelectInformation.style.border = '1px solid rgba(255, 255, 255, 1)';
        mapSelectInformation.style.cursor = 'default';
        mapSelectInformation.style.padding = '10px';
        mapSelectInformation.style.backgroundColor = 'rgba(255,255,255,0.85)';
        mapSelectInformation.style.borderRadius = '5px';

        L.DomEvent
            .addListener(mapSelectInformation, 'contextmenu mousedown click dblclick', L.DomEvent.stopPropagation);

        return mapSelectInformation;
    }



    override onRemove(map: L.Map): void {
        // Nothing to do here
    } //

}
