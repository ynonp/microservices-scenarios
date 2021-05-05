class ContactInfo < ApplicationRecord
  has_many :contact_info_meetings
  has_many :meetings, through: :contact_info_meetings
end
