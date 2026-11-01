---
governanceManaged: true
---
# Security Best Practices

## Sharing Model
- All Apex classes: default to `with sharing`. Use `without sharing` only for system-level operations (e.g., post-install scripts, scheduled jobs) with a code comment explaining why.
- Never store credentials, tokens, or secrets in Apex code, Custom Metadata, or Custom Settings visible to all users. Use Named Credentials or Protected Custom Metadata Types.

## SOQL Injection
- No string-concatenated dynamic SOQL from user input. Always use bind variables or `String.escapeSingleQuotes()` as a last resort.

## XSS in LWC / Visualforce
- Never use `innerHTML` or `lwc:dom="manual"` to inject unsanitized HTML. Use template bindings (`{expression}`) which are auto-escaped.

## Profile & Permission Set Metadata
- Permission sets are preferred over profile modifications for granting access.
- System Administrator profile metadata should not be modified to add application-level permissions; use permission sets instead.
- Never grant `Modify All Data` or `View All Data` in a permission set without documented approval.

## API Version
- All new metadata must target API version 68.0 (current project `sourceApiVersion`). Never deploy metadata below API 57.0 without documented justification (pre-57.0 lacks `WITH USER_MODE` support).
