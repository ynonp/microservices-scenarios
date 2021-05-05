json.extract! meeting, :id, :title, :starts_at, :created_at, :updated_at
json.url meeting_url(meeting, format: :json)
json.participants meeting.participants do |participant|
  json.email participant.email
end
