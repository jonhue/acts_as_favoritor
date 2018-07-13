# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    private

    DEFAULT_PARENTS = [ApplicationRecord, ActiveRecord::Base].freeze

    # Retrieves the parent class name if using STI.
    def parent_class_name(obj)
      unless parent_classes.include? obj.class.superclass
        return obj.class.base_class.name
      end
      obj.class.name
    end

    def apply_options_to_scope(scope, options = {})
      scope = scope.limit(options[:limit]) if options.key?(:limit)
      scope = scope.includes(options[:includes]) if options.key?(:includes)
      scope = scope.joins(options[:joins]) if options.key?(:joins)
      scope = scope.where(options[:where]) if options.key?(:where)
      scope = scope.order(options[:order]) if options.key?(:order)
      scope
    end

    def parent_classes
      DEFAULT_PARENTS
    end

    def validate_scopes(method, options = {})
      options[:scope] ||= [ActsAsFavoritor.configuration.default_scope]
      if options[:scope].size > 1
        options[:multiple_scopes] = true
      else
        options[:multiple_scopes] = false
        options[:scope] = options[:scope][0]
      end
      if options.key? :parameter
        parameter = options[:parameter]
        options.delete :parameter
        send method, parameter, options
      else
        send method, options
      end
    end
  end
end
