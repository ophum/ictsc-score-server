# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    # あまりにも多用するのでショートハンド化
    def current_team!
      self.context.current_team!
    end

    def graphql_name
      self.class.graphql_name
    end

    def add_error_message(message, ast_node: nil, options: nil, extensions: nil)
      Rails.logger.error message
      self.context.add_error(GraphQL::ExecutionError.new(message, ast_node: ast_node, options: options, extensions: extensions))
    end

    def add_errors(*records)
      records.each do |record|
        record.errors.each do |attr, message|
          message = "#{record.model_name} #{attr} #{message}"
          self.add_error_message(GraphQL::ExecutionError.new(message))
        end
      end

      # resolveの戻り値はハッシュかnilな必要がある
      nil
    end

    class << self
      # フィールド一覧をクエリとして使える形式で返す
      def to_fields_query(with: nil)
        self.fields.map {|name, field|
          if field.type.kind.composite?
            "#{name} { #{field.type.to_fields_query(with: with&.at(name))} }"
          else
            name
          end
        }
          .join("\n")
      end
    end
  end
end
