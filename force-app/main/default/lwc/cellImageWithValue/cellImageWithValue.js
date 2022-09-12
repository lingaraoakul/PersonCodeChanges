import { LightningElement, api } from 'lwc';

export default class CellImageWithValue extends LightningElement {
    @api imageUrl;
    @api value;

    renderedCallback() {
        const container = this.template.querySelector('.container');

        container.innerHTML = `<span>${this.value} </span> <span class="slds-float_right">${this.imageUrl} </span>`;
        // ... Do some logic with the container ...
      }
}