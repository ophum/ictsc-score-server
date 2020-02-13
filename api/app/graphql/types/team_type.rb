# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    field :id,           ID, null: false
    field :role,         Types::Enums::TeamRole, null: false
    field :beginner,     Boolean, null: false
    field :name,         String,  null: true
    field :organization, String,  null: true
    field :number,       Integer, null: true
    field :color,        String,  null: true
    field :secret_text,  String,  null: true
    # channelはgraphqlでは渡さない

    has_many :attachments
  end
end
