# MicroService Communication via REST API

## What We Have
Your team is provided with a system that has one main application and a micro service.

The application manages meetings and contacts. We can create new contacts and schedule meetings with them.
Every time a meeting is about to start, A Reminders micro service should send a reminder to each participant
reminding them to come to the meeting.

In the directory `mainapp-rest-api` you'll find the code to the main app (in Rails).
And in the directory `reminders-rest-api` you'll find the code for the reminders service.

You can run both applications and their databases using the provider docker config by running: 

```
$ docker compose up
```

Press Ctrl+C to stop the containers. Changing the code in the source folders of either the main app or the reminders will reload the code in the container, so you don't need to restart docker compose.

The main app already notifies the service every time it creates a new meeting or meeting details change via a message queue (rabbitmq).

Let's see this in action. First we'll need to create some contacts. Head over to:

```
http://localhost:4400/contact_infos
```

And press "New Contact Info". Fill in the details and repeat to create 2-3 contacts.

Now head back to the main page:

```
http://localhost:4400/
```

And click "New Meeting". Fill in some details and save.

In the docker terminal (where you started docker compose) you should now see the line:

```
reminders_1  |  [x] Received {"id":1,"starts_at":"2021-06-08T09:42:00.000+03:00"}
```

This is the reminders service telling us it received a request through the message queue to create a new meeting reminder.

Now let's move on to the code involved.

## Your Task

In the file `reminders-rest-api/main.js` you'll find the following snippet that gets called just before a meeting is about to start with the meeting id:

```
agenda.define("send reminder", async (job) => {
  try {
    const { id } = job.attrs.data;
    console.log(`Meeting ${id} is about to start - sending reminders`);
    // TODO: Connect via REST API to Rails App and get the list of parcitipants
  } catch (err) {
    console.log('error');
    console.log(err);
  }
});
```

If you created a meeting that starts now, you should already see the line in the docker compose terminal. However to actually send reminders we need some more data.  We know the meeting ID, but we don't know how to contact the meeting participants and remind them of the meeting.

Your job is to:

1. Expose new Rails API to send contact info for a given meeting

2. Modify the code in the service to connect to the new Rails API, fetch meeting participants' info so it can send them a reminder.

3. No need to actually send the email, enough to print out to the console the list of participants

You can try on your own or scroll to the end of this document to find a more detailed walkthrough.



## Discussion
Using REST API to communicate between a main app and a micro service has several advantages and other disadvantages. Try to list as many advantages and disadvantages as you can find. Here are some questions to help you see some of them:

1. What happens if you need more information? For example, if some contacts prefer to be notified via SMS. What needs to change?

2. How will you guarantee that the data is only read by the service that needs it?

3. What happens when another service needs to get more information about a meeting's participants? For example a calendar service that would also need to display an avatar next to each participant.

4. What did we gain by writing the Reminders service as a micro service? What did we lose?



## Bonus

1. Change the code so actual email will be sent (using sendgrid)

2. Allow a participant to define other communication methods and to select her preferred way.

3. The Reminders service should use the preferred communication method (SMS, email, twitter, etc.) to send a reminder. 































## Adding A Rails JSON API Endpoint
In Rails we already have a Meetings controller that supports sending JSON data over a REST API. So first from your browser connext to `http://localhost:4400`, create a new meeting and see its JSON. For example if the meeting ID is 1 we'll browse to:

```
http://localhost:4400/meetings/1.json
```

And we'll see the meeting info as JSON.

For our task we need to get the list of participants in a meeting. One simple way to do it is to change the view and add to the JSON the list of emails that should attend the meeting.

The view file is `app/views/meetings/_meeting.json.jbuilder`.

It's a jbuilder format file and you can read about jbuilder here:

[https://github.com/rails/jbuilder](https://github.com/rails/jbuilder)

Each `meeting` object has a `participants` property with all the meeting's participants. 

So to add the data we can add this loop to the end of the file:

```
json.participants meeting.participants do |participant|
  json.email participant.email
end
```


## Connecting from Node.JS to Rails to get the data
On the node.js side we can use axios to perform an HTTP call. The following code will perform an HTTP call to a host named web port 3000 asking for the details about a specific meeting:

```
const res = await axios.get(`http://web:3000/meetings/${id}.json`);
```

After this call we will have the JSON result in `res.data`. Use console.log to see it:

```
console.log(res.data);
```

If you still have time you can sign up to sendgrid free plan and send real emails to those recipients by following the instructions here:

[https://sendgrid.com/docs/for-developers/sending-email/quickstart-nodejs/](https://sendgrid.com/docs/for-developers/sending-email/quickstart-nodejs/)
