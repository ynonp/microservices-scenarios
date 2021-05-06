var amqp = require('amqplib/callback_api');
const axios = require('axios').default;
const { Agenda } = require("agenda");
const mongoConnectionString = "mongodb://mongo/agenda";
const { request, gql } = require('graphql-request');

const agenda = new Agenda({ db: { address: mongoConnectionString } });


agenda.define("send reminder", async (job) => {
  try {
    const { id } = job.attrs.data;
    console.log(`Meeting ${id} is about to start - sending reminders`);
    // TODO: Connect via GraphQL API to Rails App and get the list of parcitipants
  } catch (err) {
    console.log('error');
    console.log(err);
  }
});

agenda.start();

amqp.connect('amqp://rabbitmq', function(error0, connection) {
  if (error0) {
    throw error0;
  }

  function closeOnErr(err) {
    if (!err) return false;
    console.error("[AMQP] error", err);
    connection.close();
    return true;
  }

  connection.createChannel(function(error1, channel) {
    if (error1) {
      throw error1;
    }
    var queue = 'meetings';

    console.log(" [*] Waiting for messages in %s. To exit press CTRL+C", queue);
    channel.assertQueue(queue, { durable: true }, function(err, _ok) {
      if (closeOnErr(err)) return;

      channel.consume(queue, async function(msg) {
        console.log(" [x] Received %s", msg.content.toString());
        const data = JSON.parse(msg.content);
        const numRemoved = await agenda.cancel({ data: { id: data.id }});
        console.log(`canceled previous ${numRemoved} jobs`);
        agenda.schedule(data.starts_at, "send reminder", {
          id: data.id
        });
      }, { noAck: true })
    })
  })
});
