var amqp = require('amqplib/callback_api');
const axios = require('axios').default;
const { Agenda } = require("agenda");
const mongoConnectionString = "mongodb://127.0.0.1/agenda";

const agenda = new Agenda({ db: { address: mongoConnectionString } });

agenda.define("send reminder", async (job) => {
  try {
    const { id } = job.attrs.data;
    const res = await axios.get(`http://localhost:3000/meetings/${id}.json`);
    console.log(`Seinding emails to: `);
  } catch (err) {
    console.log('error');
    console.log(err);
  }
});

agenda.start();

amqp.connect('amqp://localhost', function(error0, connection) {
  if (error0) {
    throw error0;
  }

  connection.createChannel(function(error1, channel) {
    if (error1) {
      throw error1;
    }
    var queue = 'meetings';

    console.log(" [*] Waiting for messages in %s. To exit press CTRL+C", queue);
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
});
