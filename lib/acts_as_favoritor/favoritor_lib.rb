# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    def build_result_for_scopes(scopes)
      return if scopes.empty?

      scopes = sanitized_scopes(scopes)
      result = scopes.map { |scope| [scope, yield(scope)] }.to_h

      return result[scopes.first] if scopes.size == 1

      result
    end

    private

    def sanitized_scopes(scopes)
      scopes.map(&:to_sym)
    end
  end
end
