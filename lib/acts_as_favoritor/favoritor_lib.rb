# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    private

    DEFAULT_PARENTS = [ApplicationRecord, ActiveRecord::Base].freeze

    # Retrieves the parent class name if using STI.
    def parent_class_name(obj)
      unless DEFAULT_PARENTS.include? obj.class.superclass
        return obj.class.base_class.name
      end

      obj.class.name
    end

    def build_result_for_scopes(scopes)
      return if scopes.empty?

      scopes = sanitized_scopes(scopes)
      result = scopes.map { |scope| [scope, yield(scope)] }.to_h

      return result[scopes.first] if scopes.size == 1

      result
    end

    def sanitized_scopes(scopes)
      scopes.map(&:to_sym)
    end
  end
end
