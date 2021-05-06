# app/graphql/types/meeting_type.rb
module Types
  class MeetingType < Types::BaseObject
    description 'A meeting'
    field :id, ID, null: false
    field :title, String, null: false
    field :starts_at, GraphQL::Types::ISO8601DateTime, null: false
    field :participants, [Types::ContactInfoType], null: true
  end
end
