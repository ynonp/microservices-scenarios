module Types
  class ContactInfoType < Types::BaseObject
    description 'A person in a meeting'
    field :id, ID, null: false
    field :email, String, null: false
    field :phone, String, null: false
  end
end
