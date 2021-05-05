class ContactInfoMeeting < ApplicationRecord
  belongs_to :contact_info
  belongs_to :meeting
end
