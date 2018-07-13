# frozen_string_literal: true

module ActsAsFavoritor
  module FavoritorLib
    private

    DEFAULT_PARENTS = [ApplicationRecord, ActiveRecord::Base]

    # Retrieves the parent class name if using STI.
    def parent_class_name obj
      unless parent_classes.include? obj.class.superclass
        return obj.class.base_class.name
      end
      obj.class.name
    end

    def apply_options_to_scope scope, options = {}
      if options.has_key? :limit
        scope = scope.limit options[:limit]
      end
      if options.has_key? :includes
        scope = scope.includes options[:includes]
      end
      if options.has_key? :joins
        scope = scope.joins options[:joins]
      end
      if options.has_key? :where
        scope = scope.where options[:where]
      end
      if options.has_key? :order
        scope = scope.order options[:order]
      end
      scope
    end

    def parent_classes
      return DEFAULT_PARENTS
    end

    def validate_scopes method, options = {}
      options[:scope] = options[:scope] || [ActsAsFavoritor.configuration.default_scope]
      if options[:scope].size > 1
        options[:multiple_scopes] = true
      else
        options[:multiple_scopes] = false
        options[:scope] = options[:scope][0]
      end
      if options.has_key? :parameter
        parameter = options[:parameter]
        options.delete :parameter
        send method, parameter, options
      else
        send method, options
      end
    end
  end
end
