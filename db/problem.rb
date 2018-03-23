require 'ostruct'

class Problem < ActiveRecord::Base
  validates :title,     presence: true
  validates :text,      presence: true
  validates :creator,   presence: true
  validates :reference_point, presence: true
  validates :perfect_point,   presence: true

  has_many :answers,  dependent: :destroy
  has_many :comments, dependent: :destroy, as: :commentable
  has_many :issues,   dependent: :destroy
  has_many :next_problems, class_name: self.to_s, foreign_key: "problem_must_solve_before_id"
  has_many :first_correct_answer, dependent: :destroy

  has_and_belongs_to_many :problem_groups, dependent: :nullify

  belongs_to :problem_must_solve_before, class_name: self.to_s
  belongs_to :creator, foreign_key: "creator_id", class_name: "Member"

  # method: POST
  def self.allowed_to_create_by?(user = nil, action: "")
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer]
      true
    else
      false
    end
  end

  def readable?(by: nil, action: '')
    self.class.readables(user: by, action: action).exists?(id: id)
  end

  # method: GET, PUT, PATCH, DELETE
  def allowed?(by: nil, method:, action: "")
    return readable?(by: by, action: action) if method == 'GET'

    case by&.role_id
    when ROLE_ID[:admin]
      true
    when ROLE_ID[:writer]
      creator_id == by.id
    else
      false
    end
  end

  # 権限によって許可するパラメータを変える
  def self.allowed_nested_params(user:)
    base_params = %w(answers answers-score answers-team issues issues-comments comments problem_groups)
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer], ROLE_ID[:viewer]
      base_params + %w(creator)
    when ROLE_ID[:participant]
      base_params
    else
      %w()
    end
  end

  def self.readable_columns(user:, action: '', reference_keys: true)
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:writer], ROLE_ID[:viewer]
      self.all_column_names(reference_keys: reference_keys)
    when ROLE_ID[:participant]
      case action
      when 'not_opened'
        # 未開放問題の閲覧可能情報
        %w(id team_private order problem_must_solve_before_id created_at updated_at)
      else
        self.all_column_names(reference_keys: reference_keys) - %w(creator_id reference_point)
      end
    else
      []
    end
  end

  scope :filter_columns, ->(user:, action: '') {
    cols = readable_columns(user: user, action: action, reference_keys: false)
    next none if cols.empty?
    select(*cols)
  }

  scope :readable_records, ->(user:, action: '') {
    case user&.role_id
    when ROLE_ID[:admin], ROLE_ID[:viewer]
      all
    when ROLE_ID[:writer]
      next all if action.empty?
      next where(creator: user) if action == "problems_comments"
      none
    when ->(role_id) { role_id == ROLE_ID[:participant] || user&.team }
      next none unless in_competition?

      fca_problem_ids = FirstCorrectAnswer.readables(user: user, action: 'opened_problem').pluck(:problem_id)

      case action
      when 'not_opened'
        # 未開放問題
        where.not(problem_must_solve_before_id: fca_problem_ids + [nil])
      else
        where(problem_must_solve_before_id: fca_problem_ids + [nil])
      end
    else
      none
    end
  }

  # method: GET
  scope :readables, ->(user:, action: '') {
    readable_records(user: user, action: action)
      .filter_columns(user: user, action: action)
  }

  def readable_teams
    Team.select do |team|
      # 適当にチームからユーザを取得してもいいが、想定外の動作をする可能性がある
      dummy_user = OpenStruct.new({ role_id: ROLE_ID[:participant], team: team })
      readable?(by: dummy_user)
    end
  end

  # 突破チーム数を返す
  # idが指定されると単一の値を返す
  def self.solved_teams_counts(user:, id: nil)
    rel = id ? FirstCorrectAnswer.where(problem_id: id) : FirstCorrectAnswer.all
    counts = rel
      .readables(user: user, action: 'for_count')
      .group(:problem_id)
      .count(:team_id) # readables内でselectしてるからカラムの指定が必要

    counts.default = 0

    id ? counts[id] : counts
  end
end
