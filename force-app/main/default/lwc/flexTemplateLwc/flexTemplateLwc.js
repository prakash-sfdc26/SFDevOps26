import { LightningElement } from 'lwc';
import getFlexTemplateResponse from '@salesforce/apex/FlexTemplateController.getFlexTemplateResponse';

const DEFAULT_ERROR = 'Something went wrong while generating the pitch.';

export default class FlexTemplateLwc extends LightningElement {
    accountName = '';
    ratingValue;
    response;
    errorMessage;
    isLoading = false;

    ratingOptions = [
        { label: 'Best', value: 'Best' },
        { label: 'Average', value: 'Average' },
        { label: 'Low', value: 'Low' }
    ];

    get isSubmitDisabled() {
        return this.isLoading || !this.accountName || !this.ratingValue;
    }

    handleRatingChange(event) {
        this.ratingValue = event.detail.value;
    }

    handleAccountChange(event) {
        this.accountName = event.target.value;
    }

    async handleSubmit() {
        this.isLoading = true;
        this.errorMessage = undefined;
        this.response = undefined;

        try {
            this.response = await getFlexTemplateResponse({
                accountName: this.accountName,
                rating: this.ratingValue
            });
        } catch (error) {
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
        } finally {
            this.isLoading = false;
        }
    }
}
