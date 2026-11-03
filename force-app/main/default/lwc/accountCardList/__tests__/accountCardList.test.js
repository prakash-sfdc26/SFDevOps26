import { createElement } from '@lwc/engine-dom';
import AccountCardList from 'c/accountCardList';
import getAccounts from '@salesforce/apex/AccountListController.getAccounts';
import { getNavigateCalledWith } from 'lightning/navigation';

jest.mock(
    '@salesforce/apex/AccountListController.getAccounts',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

const MOCK_RESULT = {
    totalCount: 12,
    accounts: [
        {
            Id: '001000000000001AAA',
            Name: 'Acme Corporation',
            Industry: 'Technology',
            Phone: '(415) 555-1234',
            AnnualRevenue: 5200000,
            Rating: 'Hot'
        },
        {
            Id: '001000000000002AAA',
            Name: 'Global Industries',
            Industry: 'Manufacturing',
            Phone: '(312) 555-9876',
            AnnualRevenue: 1850000,
            Rating: 'Warm'
        }
    ]
};

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
};

function createComponent(props = {}) {
    const element = createElement('c-account-card-list', { is: AccountCardList });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
}

function cards(element) {
    return element.shadowRoot.querySelectorAll('.card');
}

describe('c-account-card-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders a card per Account with details, rating and the total count', async () => {
        const element = createComponent();
        getAccounts.emit(MOCK_RESULT);
        await flushPromises();

        const rendered = cards(element);
        expect(rendered).toHaveLength(2);
        expect(element.shadowRoot.querySelector('.header-title').textContent).toBe('My Accounts');
        expect(element.shadowRoot.querySelector('.header-count').textContent).toBe('Showing 2 of 12');

        const first = rendered[0];
        expect(first.querySelector('.avatar').textContent).toBe('A');
        expect(first.querySelector('.account-name').textContent).toBe('Acme Corporation');
        expect(first.textContent).toContain('Industry: Technology');
        expect(first.textContent).toContain('Phone: (415) 555-1234');
        expect(first.querySelector('.rating-hot').textContent).toContain('Hot');
        expect(first.querySelector('.rating-hot').textContent).toContain('🔥');
        expect(rendered[1].querySelector('.rating-warm').textContent).toContain('Warm');
    });

    it('navigates to the Account record when a card is clicked', async () => {
        const element = createComponent();
        getAccounts.emit(MOCK_RESULT);
        await flushPromises();

        cards(element)[1].click();

        const { pageReference } = getNavigateCalledWith();
        expect(pageReference.type).toBe('standard__recordPage');
        expect(pageReference.attributes.recordId).toBe('001000000000002AAA');
        expect(pageReference.attributes.actionName).toBe('view');
    });

    it('navigates when Enter is pressed on a focused card', async () => {
        const element = createComponent();
        getAccounts.emit(MOCK_RESULT);
        await flushPromises();

        cards(element)[0].dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));

        expect(getNavigateCalledWith().pageReference.attributes.recordId).toBe('001000000000001AAA');
    });

    it('requests 5 Accounts by default', async () => {
        createComponent();
        await flushPromises();

        expect(getAccounts.getLastConfig()).toEqual({ maxRows: 5 });
    });

    it.each([
        [1, 2],
        [3, 3],
        [99, 5],
        ['abc', 5]
    ])('clamps displayCount %p to %p Accounts', async (displayCount, expected) => {
        createComponent({ displayCount });
        await flushPromises();

        expect(getAccounts.getLastConfig()).toEqual({ maxRows: expected });
    });

    it('shows an error message when the Apex call fails', async () => {
        const element = createComponent();
        getAccounts.error({ message: 'No access to Account' });
        await flushPromises();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('No access to Account');
        expect(cards(element)).toHaveLength(0);
    });

    it('shows an empty state when there are no Accounts', async () => {
        const element = createComponent();
        getAccounts.emit({ totalCount: 0, accounts: [] });
        await flushPromises();

        expect(cards(element)).toHaveLength(0);
        expect(element.shadowRoot.querySelector('.message').textContent).toBe('No Accounts found.');
        expect(element.shadowRoot.querySelector('.header-count')).toBeNull();
    });
});
