# frozen_string_literal: true

module Mutations
  class DeleteProblemSupplement < BaseMutation
    field :problem_supplement, Types::ProblemSupplementType, null: true
    argument :problem_supplement_id, ID, required: true

    def resolve(problem_supplement_id:)
      problem_supplement = ProblemSupplement.find_by(id: problem_supplement_id)
      raise RecordNotExists.new(ProblemSupplement, id: problem_supplement_id) if problem_supplement.nil?

      Acl.permit!(mutation: self, args: { problem_supplement: problem_supplement })

      if problem_supplement.destroy
        # 削除されたレコードはreadableが使えないのでカラムのみフィルタする
        { problem_supplement: problem_supplement.filter_columns(team: self.current_team!) }
      else
        add_errors(problem_supplement)
      end
    end
  end
end
