class Meeting < ApplicationRecord
  has_many :contact_info_meetings
  has_many :participants, class_name: :ContactInfo, through: :contact_info_meetings, source: :contact_info
end
