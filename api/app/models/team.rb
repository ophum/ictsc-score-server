# frozen_string_literal: true

class Team < ApplicationRecord
  # PlasmaでSSEする際にlistenするチャンネル
  # 認証の代わりに推測困難なIDを使う
  has_secure_token :channel
  # create時に生成されるためバリデーション無効
  validates :channel, presence: true, on: :update

  validates :role,            presence: true
  validates :beginner,        boolean:  true
  validates :number,          presence: true, uniqueness: true
  validates :name,            presence: true, uniqueness: true
  # dummy field
  validates :password,        presence: true, length: { maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED }, if: :will_save_change_to_password_digest?
  validates :password_digest, presence: true
  validates :organization,    presence: false
  validates :color,           color_code: true, allow_nil: true

  has_many :answers,               dependent: :destroy
  has_many :attachments,           dependent: :nullify
  has_many :first_correct_answers, dependent: :destroy
  has_many :issues,                dependent: :destroy
  has_many :notices,               dependent: :nullify, inverse_of: 'target_team', foreign_key: 'target_team_id'
  has_many :problem_environments,  dependent: :destroy

  # 値が大きいほど大体権限が高い
  enum role: {
    staff: 10,
    audience: 5,
    player: 1
  }

  after_commit :delete_session, on: %i[update], if: :saved_change_to_password_digest?

  attr_reader :password

  def delete_session
    Session.destroy_by(team_id: id)
  end

  def password=(value)
    return if value.blank?

    @password = value
    self.password_digest = BCrypt::Password.create(@password, cost: BCrypt::Engine.cost)
  end

  def authenticate(plain_password)
    BCrypt::Password.new(password_digest).is_password?(plain_password) && self
  end

  # greater than or equal roles
  def gte_roles
    Team.roles.select {|_k, v| v >= self.role_before_type_cast }
  end

  # less than or equal roles
  def lte_roles
    Team.roles.select {|_k, v| v <= self.role_before_type_cast }
  end

  class << self
    def login(name:, password:)
      # ハッシュ計算は重いため計算を始める前にコネクションをリリースする
      Team
        .find_by(name: name)
        .tap { connection_pool.release_connection }
        &.authenticate(password)
    end
  end
end
