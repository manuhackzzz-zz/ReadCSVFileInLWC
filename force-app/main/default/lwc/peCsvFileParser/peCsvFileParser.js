import { LightningElement, api , wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import parseCsvToPeApex from '@salesforce/apex/CLMParseCSVToPEController.parseCsvToPe';
import {NavigationMixin} from 'lightning/navigation';

// const fields = [REQUEST_TYPE_FIELD];

export default class PeCsvFileParser extends NavigationMixin(LightningElement){
    @api recordId;
    showSpinner=false;

    // @wire(getRecord, { recordId: '$recordId', fields })
    // opportunity;

    uploadFileHandler(event) {
        const uploadedFiles = event.detail.files;
        this.showSpinner = true;
        parseCsvToPeApex({
            recordId: this.recordId,
            filesJson: JSON.stringify(uploadedFiles)
        })
        .then(result => {
            this.showNotification(result.title, result.message, result.variant, result.mode);
            this.showSpinner = false;
            this.navigateToRelatedPricingExhibits();
        })
            .catch(error => {
            //debugger;
            console.log(JSON.stringify(error));
            this.showNotification(
                'ERROR', 'Please contact your administrator with following message :' + JSON.stringify(error), 'error', 'sticky'
            );
            this.showSpinner = false;
        })
    }

    showNotification(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    navigateToRelatedPricingExhibits(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                //objectApiName: 'Opportunity',
                relationshipApiName: 'Pricing_Exhibits__r',
                actionName: 'view'
            },
        });
    }

    get acceptedCSVFormats() {
        return ['.csv'];
    }
}