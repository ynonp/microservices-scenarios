class MessagingService
  def initialize(amqp_url)
    @bunny = Bunny.new(amqp_url)
  end

  attr_reader :bunny

  def meetings_queue
    connect if @bunny.status == :not_connected

    @channel ||= bunny.channel
    @meetings_queue ||= @channel.queue('meetings', durable: true)
  end

  def connect
    @bunny.start
  end
end
