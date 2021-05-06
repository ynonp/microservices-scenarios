# MicroService Communication via GraphQL

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
    // TODO: Connect via REST API to Rails App and get the list of parcitipants
  } catch (err) {
    console.log('error');
    console.log(err);
  }
});
```

Before moving on to the task, see that you can run the services, create a new meeting and get a console log line in docker compose when the meeting is about to start.

## What We Need
We know the meeting ID, but we don't know how to contact the meeting participants and remind them of the meeting. Your job is to:

1. Expose new Rails API to send contact info for a given meeting

2. Modify the code in the service to connect to the new Rails API, fetch meeting participants' info so it can send them a reminder.

3. No need to actually send the email, enough to print out to the console the list of participants

We'll use GraphQL to implement the API according to the instructions here:
[https://graphql-ruby.org/getting_started](https://graphql-ruby.org/getting_started)

You can try on your own or scroll to the end of this document for a more detailed walkthrough.

## Discussion
Using GraphQL to communicate between a main app and a micro service has several advantages and other disadvantages.
Try to list as many advantages and disadvantages as you can find. Here are some questions to help you see some of them:

1. What happens if you need more information? For example, if some contacts prefer to be notified via SMS. What needs to change?

2. How will you guarantee that the data is only read by the service that needs it?

3. What happens when another service needs to get more information about a meeting's participants? For example a calendar service that would also need to display an avatar next to each participant.

4. What did we gain by writing the Reminders service as a micro service? What did we lose?


## Bonus

1. Change the code so actual email will be sent (using sendgrid)

2. Allow a participant to define other communication methods and to select her preferred way.

3. The Reminders service should use the preferred communication method (SMS, email, twitter, etc.) to send a reminder. 































## Adding A Rails API Endpoint
GraphQL is already installed in the starter but is not configured. A GraphQL API lets the client decide what data it needs according to a schema of pre-defined types. In order to open a GraphQL endpoint on our server we first need to define types for relevant data, and then expose those types from a GraphQL root.

A type in GraphQL corresponds to a model in Rails: It has "fields" to describe the data in the DB table, and also supports methods for callbacks and more complex logic.

In our application we have two types: A `MeetingType` and a `ContactInfoType`.

Create a new file named `app/graphql/types/meeting_type.rb` with the following content:

```
# app/graphql/types/meeting_type.rb
module Types
  class MeetingType < Types::BaseObject
    description 'A meeting'
    field :id, ID, null: false
    field :title, String, null: false
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: false
    field :participants, [Types::ContactInfoType], null: true
  end
end
```

Observe how the fields match the columns in the database.

Now create a second file named `app/graphql/types/contact_info_type.rb` with the following content:

```
module Types
  class ContactInfoType < Types::BaseObject
    description 'A person in a meeting'
    field :id, ID, null: false
    field :email, String, null: false
    field :phone, String, null: false
  end
end
```

Although in the database we have a connection table and a connection model `ContactInfoMeeting`, this is not needed in GraphQL schema. The schema only cares about the data a user can request.

After we have both types in place we need to declare an API endpoint. The endpoint is the "starting point" of a query. In our case a client starts the query with a meeting id, and they would usually want to get some data on the meetings and its participants.

Add the following code to the class `QueryType` in file `app/graphql/types/query_type.rb`:

```
    field :meeting, MeetingType, null: false do
      description 'Find a meeting by ID'
      argument :id, ID, required: true
    end

    def meeting(id:)
      Meeting.find(id)
    end
```

By declaring a field in class QueryType we allow a client to request data from this field. Within the block I define an argument :id, and the method `meeting(:id)` will be called to actually get the object.

Pay attention to this field/method relationship: Actually in GraphQL each field can have a method that will calculate its value. In those methods, the special variable `object` refers to the object that "has" those fields.

Finally observe the file `config/routes.rb` in the starter:

```
Rails.application.routes.draw do
  post "/graphql", to: "graphql#execute"
  root to: 'meetings#index'
  resources :meetings
  resources :contact_infos
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
```

The first route tells Rails to send each GraphQL query to the GraphqlController's execute method. Head over to the file `app/controllers/graphql_controller.rb` to check its implementation.

## Checking the GraphQL Schema
Our graphql schema is now ready but before we move on to modify Node.JS micro service let's verify that it works.

Start the Rails console by typing (in `mainapp` folder):

```
$ ./bin/rails c
```

In the console run the following code:

```
query = "
 {
   meeting(id: 1) {
    id
    title
    participants { email }
  }
}"

MainappSchema.execute(query)
```

And if all goes well you should see the meeting's data for meeting with ID = 1

## Connecting from Node.JS to Rails to get the data
Now let's continue to node.js micro service and allow it to query the main app to get the actual meeting's participants.

Add the following code to the job description function (after the TODO comment):

```
    const query = gql`
      {
        meeting(id: ${id}) {
          title
          participants {
            email
          }
        }
      }
    `
    request('http://web:3000/graphql', query).then((data) => {
      console.log(data.meeting.participants);
    })
```

Having a GraphQL endpoint on the main app means our client decides what data it needs and can structure the query any way it wants.
