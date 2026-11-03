import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CURRENCY from '@salesforce/i18n/currency';
import getAccounts from '@salesforce/apex/AccountListController.getAccounts';

const MIN_CARDS = 2;
const MAX_CARDS = 5;
const DEFAULT_ERROR = 'Something went wrong while loading Accounts.';
const NOT_SET = '—';

// Fixed palette so an Account keeps a stable avatar colour for its position in the list
const AVATAR_COLORS = ['#0b7fd1', '#a259d9', '#2e844a', '#e07a1f', '#c23934'];

const RATING_STYLES = {
    Hot: { cssClass: 'rating-value rating-hot', icon: '🔥' },
    Warm: { cssClass: 'rating-value rating-warm', icon: '' },
    Cold: { cssClass: 'rating-value rating-cold', icon: '' }
};

export default class AccountCardList extends NavigationMixin(LightningElement) {
    // Set from the App Builder property; never reassigned here, the clamped value lives in the maxRows getter
    @api displayCount = MAX_CARDS;

    currencyCode = CURRENCY;
    accounts = [];
    totalCount = 0;
    errorMessage;
    isLoading = true;

    get maxRows() {
        const requested = Number.parseInt(this.displayCount, 10);
        if (Number.isNaN(requested)) {
            return MAX_CARDS;
        }
        return Math.min(MAX_CARDS, Math.max(MIN_CARDS, requested));
    }

    @wire(getAccounts, { maxRows: '$maxRows' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.accounts = data.accounts.map((account, index) => this.toCard(account, index));
            this.totalCount = data.totalCount;
            this.errorMessage = undefined;
            this.isLoading = false;
        } else if (error) {
            this.accounts = [];
            this.totalCount = 0;
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
            this.isLoading = false;
        }
    }

    get hasAccounts() {
        return this.accounts.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.errorMessage && !this.hasAccounts;
    }

    get countLabel() {
        return `Showing ${this.accounts.length} of ${this.totalCount}`;
    }

    toCard(account, index) {
        const rating = RATING_STYLES[account.Rating];
        return {
            id: account.Id,
            name: account.Name,
            initial: account.Name ? account.Name.charAt(0).toUpperCase() : '?',
            avatarStyle: `background-color: ${AVATAR_COLORS[index % AVATAR_COLORS.length]}`,
            industry: account.Industry || NOT_SET,
            phone: account.Phone || NOT_SET,
            hasRevenue: account.AnnualRevenue != null,
            annualRevenue: account.AnnualRevenue,
            ratingLabel: account.Rating || NOT_SET,
            ratingClass: rating ? rating.cssClass : 'rating-value',
            ratingIcon: rating ? rating.icon : ''
        };
    }

    handleCardClick(event) {
        this.navigateToAccount(event.currentTarget.dataset.id);
    }

    handleCardKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.navigateToAccount(event.currentTarget.dataset.id);
        }
    }

    navigateToAccount(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId, objectApiName: 'Account', actionName: 'view' }
        });
    }
}
