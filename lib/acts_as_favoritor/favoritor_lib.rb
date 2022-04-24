# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    def build_result_for_scopes(scopes, &block)
      return yield(scopes) unless scopes.is_a?(Array)
      return if scopes.empty?

      sanitized_scopes(scopes).index_with(&block)
    end

    private

    def sanitized_scopes(scopes)
      scopes.map(&:to_sym)
    end
  end
end
