import LightningDatatable from 'lightning/datatable';
import cellRedirect from './cellTemplates/cellRedirect.html';
import valueWithImage from './imageWithValue/valueWithImage.html';

export default class OrgDataTable extends LightningDatatable {

    static customTypes = {
        reDirectUrl : {
            template:cellRedirect,
            standardCellLayout: true,
            typeAttributes: ['label', 'sourceUrl','targetOpen']
        },
        imageValue : {
            template:valueWithImage,
            standardCellLayout: false,
            typeAttributes: ['imageUrl']
        }
    };
}