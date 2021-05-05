# Reminder Micro Service

Provided a system that already has users info and meetings info managed by a Rails app,
we need to create a reminder service that will send email or SMS reminders to our users whenever their meeting is due.

## System Requirements

1. Provide an API to Create/Update/Delete/Read reminders

2. When time comes, send an email using Mailgun to the recipient

3. Reminders are automatically created by the `meetings` service using the API. Every time a meeting changes, it will also re-schedule the reminder.

4. When a reminder triggers it should send the email to the current email address of the recipient (even if that address is different from what it was when the reminder was created).

For this tutorial we'll implement the new service in Node.JS using MongoDB and communicate with the main app using 3 different methods to see the difference between them.

## Implementation 1 - Using a REST API

## Implementation 2 - Using GraphQL API

## Implementation 3 - Connecting to the user's database

