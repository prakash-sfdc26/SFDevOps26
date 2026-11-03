Create an Apex trigger and trigger handler class for the object: $ARGUMENTS

Follow these conventions:
- Trigger should delegate all logic to a handler class
- Handler class name: {ObjectName}TriggerHandler
- Use the project's existing trigger handler pattern
- Include before insert, before update, after insert, after update contexts
- Add TODO comments where business logic should go
- API version 65.0