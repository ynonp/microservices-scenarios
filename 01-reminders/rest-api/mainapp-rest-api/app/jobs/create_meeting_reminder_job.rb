class CreateMeetingReminderJob < ApplicationJob
  def perform(meeting_id)
    meeting = Meeting.find(meeting_id)
    MESSAGING_SERVICE.meetings_queue.publish(
      { id: meeting.id, starts_at: meeting.starts_at }.to_json
    )
  end
end
