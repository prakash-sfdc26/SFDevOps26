import { createElement } from '@lwc/engine-dom';
import FlexTemplateLwc from 'c/flexTemplateLwc';
import getFlexTemplateResponse from '@salesforce/apex/FlexTemplateController.getFlexTemplateResponse';

jest.mock(
    '@salesforce/apex/FlexTemplateController.getFlexTemplateResponse',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = async () => {
    await Promise.resolve();
    await Promise.resolve();
};

function createComponent() {
    const element = createElement('c-flex-template-lwc', { is: FlexTemplateLwc });
    document.body.appendChild(element);
    return element;
}

function fillForm(element, accountName, rating) {
    const input = element.shadowRoot.querySelector('lightning-input');
    input.value = accountName;
    input.dispatchEvent(new CustomEvent('change'));

    const combobox = element.shadowRoot.querySelector('lightning-combobox');
    combobox.dispatchEvent(new CustomEvent('change', { detail: { value: rating } }));
}

describe('c-flex-template-lwc', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('renders the form with Submit disabled and no response or error', () => {
        const element = createComponent();

        expect(element.shadowRoot.querySelector('lightning-card').title).toBe('Customer Pitch Maker');
        expect(element.shadowRoot.querySelector('lightning-button').disabled).toBe(true);
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('calls Apex with the entered values and shows the generated pitch', async () => {
        getFlexTemplateResponse.mockResolvedValue('<p>Great pitch</p>');
        const element = createComponent();
        fillForm(element, 'Acme', 'Best');
        await flushPromises();

        const button = element.shadowRoot.querySelector('lightning-button');
        expect(button.disabled).toBe(false);
        button.click();
        await flushPromises();

        expect(getFlexTemplateResponse).toHaveBeenCalledWith({ accountName: 'Acme', rating: 'Best' });
        expect(element.shadowRoot.querySelector('lightning-formatted-rich-text').value).toBe(
            '<p>Great pitch</p>'
        );
        expect(element.shadowRoot.querySelector('[role="alert"]')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('shows the Apex error message when the call fails', async () => {
        getFlexTemplateResponse.mockRejectedValue({ body: { message: 'No such account' } });
        const element = createComponent();
        fillForm(element, 'Nope', 'Low');
        await flushPromises();

        element.shadowRoot.querySelector('lightning-button').click();
        await flushPromises();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe('No such account');
        expect(element.shadowRoot.querySelector('lightning-formatted-rich-text').value).toBeUndefined();
        expect(element.shadowRoot.querySelector('lightning-spinner')).toBeNull();
    });

    it('falls back to a generic message when the error has no body', async () => {
        getFlexTemplateResponse.mockRejectedValue(new Error('network'));
        const element = createComponent();
        fillForm(element, 'Acme', 'Average');
        await flushPromises();

        element.shadowRoot.querySelector('lightning-button').click();
        await flushPromises();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toBe(
            'Something went wrong while generating the pitch.'
        );
    });
});
