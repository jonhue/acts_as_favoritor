# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    def build_result_for_scopes(scopes)
      return yield(scopes) unless scopes.is_a?(Array)
      return if scopes.empty?

      sanitized_scopes(scopes).to_h { |scope| [scope, yield(scope)] }
    end

    private

    def sanitized_scopes(scopes)
      scopes.map(&:to_sym)
    end
  end
end
