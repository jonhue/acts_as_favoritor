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
            return DEFAULT_PARENTS unless ActsAsFavoritor.custom_parent_classes

            ActiveSupport::Deprecation.warn('Setting custom parent classes is deprecated and will be removed in future versions.')
            ActsAsFavoritor.custom_parent_classes + DEFAULT_PARENTS
        end

        def validate_scopes method_name, options = {}
            if options[:scope].size > 1
                result = method multiple_scopes: true, options
            else
                options[:scope] = options[:scope][0]
                result = method multiple_scopes: false, options
            end
            return result
        end

    end
end
