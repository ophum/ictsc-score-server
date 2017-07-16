class Team < ActiveRecord::Base
  validates :name, presence: true
  validates :registration_code, presence: true
  validates_associated :notification_subscriber

  has_many :members, dependent: :nullify
  has_many :answers, dependent: :destroy
  has_many :issues, dependent: :destroy
  has_one :notification_subscriber, dependent: :destroy, as: :subscribable

  before_validation def build_notification_subscriber_if_not_exists
    build_notification_subscriber if not notification_subscriber
  end

  # method: POST
  def self.allowed_to_create_by?(user = nil, action: "")
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer]
      true
    else # nologin, ...
      false
    end
  end

  # method: GET, PUT, PATCH, DELETE
  def allowed?(method:, by: nil, action: "")
    return self.class.readables(user: by, action: action).exists?(id: id) if method == "GET"

    case by&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer]
      true
    else # nologin, ...
      false
    end
  end

  # method: GET
  scope :readables, ->(user: nil, action: "") {
    all
  }
end
