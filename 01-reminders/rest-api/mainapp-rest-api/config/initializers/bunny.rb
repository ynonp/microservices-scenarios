require_relative '../../lib/messaging_service.rb';

MESSAGING_SERVICE = MessagingService.new("amqp://localhost:5672")
