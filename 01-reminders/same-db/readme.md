# MicroService Communication via Same DB

## What We Have
Your team is provided with a system that has one main application and a micro service.

The application manages meetings and contacts. We can create new contacts and schedule meetings with them.
Every time a meeting is about to start, A Reminders micro service should send a reminder to each participant
reminding them to come to the meeting.

In the directory `mainapp` you'll find the code to the main app (in Rails).
And in the directory `reminders` you'll find the code for the reminders service.

You can run both applications and their databases using the provider docker config. First run:

```
$ docker compose build
```

And then start the stack with:

```
$ docker compose up
```

Press Ctrl+C to stop the containers. Changing the code in the source folders of either the main app or the reminders will reload the code in the container, so you don't need to restart docker compose.

The main app already notifies the service every time it creates a new meeting or meeting details change via a message queue (rabbitmq).

In the file `reminders/main.js` you'll find the following snippet that gets called just before a meeting is about to start with the meeting id:

```
agenda.define("send reminder", async (job) => {
  try {
    const { id } = job.attrs.data;
    console.log(`Meeting ${id} is about to start - sending reminders`);
    // TODO: Use knex to query the main app's database for the emails
  } catch (err) {
    console.log('error');
    console.log(err);
  }
});
```

Before moving on to the task, see that you can run the services, create a new meeting and get a console log line in docker compose when the meeting is about to start.

## What We Need
We know the meeting ID, but we don't know how to contact the meeting participants and remind them of the meeting. Your job is to:

1. Modify the micro service code to connect to the main app's database and fetch the data it needs

2. The service needs the emails of all the users participating in the meeting

3. No need to actually send the email, enough to print out to the console the list of participants

We'll use knex to connect to Rail's postgresql db. You can find knex API here:
[http://knexjs.org/](http://knexjs.org/)

You can try on your own or scroll to the end of this document to find a more detailed walkthrough.

## Discussion
Having a micro service use the same database as the main app has several advantages and other disadvantages. Try to list as many advantages and disadvantages as you can find. Here are some questions to help you see some of them:

1. What happens if you need more information? For example, if some contacts prefer to be notified via SMS. What needs to change?

2. How will you guarantee that the data is only read by the service that needs it?

3. What happens when another service needs to get more information about a meeting's participants? For example a calendar service that would also need to display an avatar next to each participant.

4. What did we gain by writing the Reminders service as a micro service? What did we lose?

5. What happens if we need to Refactor business logic code in the main app? For example move some data to a new table, or change the names of database columns ?



## Bonus

1. Change the code so actual email will be sent (using sendgrid)

2. Allow a participant to define other communication methods and to select her preferred way.

3. The Reminders service should use the preferred communication method (SMS, email, twitter, etc.) to send a reminder. 































## Connecting from Node.JS to the same DB to get the information
On Node.JS we use knex to connect to a database. All the credentials are passed in docker-compose.yml file as environment variables to the services (which can easily be converted to docker secrets for a more secure setup).

First insert the following snippet in line 8 of main.js (marked with the first TODO):

```
const knex = require('knex')({
    client: 'pg',
    connection: {
      host: 'db',
      user: process.env.MAINAPP_DB_USER,
      password: process.env.MAINAPP_DB_PASS,
      database: process.env.MAINAPP_DB_NAME,
    },
});
```

This creates the DB connection.

Now paste the following snippet to line 15 near the second TODO:

```
    const data = await knex('meetings')
      .where('meetings.id', id)
      .join('contact_info_meetings', 'meetings.id', '=', 'contact_info_meetings.meeting_id')
      .join('contact_infos', 'contact_infos.id', '=', 'contact_info_meetings.contact_info_id')
      .select('contact_infos.email');

    console.log(data);

```

This snippet builds an SQL query and executes it against the database.

Run the code to verify the list of emails is printed on screen.


