Dummy::Application.configure do
    config.cache_classes = true
    config.consider_all_requests_local = true
    config.active_support.deprecation = :stderr
    config.eager_load = false
end
