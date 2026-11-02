---
governanceManaged: true
---
# Lightning Web Component Best Practices

## Component Structure
- Each LWC bundle must contain `.html`, `.js`, and `.js-meta.xml`. CSS is optional.
- `@api` properties must be primitive types or plain objects — never expose complex class instances.
- Never reassign `@api` properties from inside the component (enforced by `@lwc/lwc/no-api-reassignments`).

## Data Access
- Use `@wire` with Lightning Data Service (LDS) adapters for standard CRM record reads. Fall back to `@AuraEnabled` Apex only when LDS doesn't support the use case.
- Never call `@AuraEnabled` methods from `connectedCallback` without handling the loading/error state in the template.

## Event Handling
- Use `CustomEvent` (not `Event`) for child-to-parent communication (enforced by `@lwc/lwc/prefer-custom-event`).
- Prefix event names with the component name to avoid collisions (e.g., `mycomponent_save`).
- Never use `dispatchEvent(new Event('change'))` for cross-component contracts — use `CustomEvent` with a `detail` payload.

## Navigation & Platform
- Use `NavigationMixin` for all navigation — never hardcode `window.location.href`.
- Never use `eval()`, `setTimeout()`, `setInterval()`, or dynamic module imports (`import()`) without documented necessity (enforced by `@lwc/lwc/no-async-operation`).

## Testing
- Every LWC component must have a corresponding Jest test file at `__tests__/<componentName>.test.js`.
- Test coverage must include at least the default render, a user interaction, and an error/empty state.
