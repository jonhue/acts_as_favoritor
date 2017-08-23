Dummy::Application.configure do
    config.cache_classes = false
    config.whiny_nils = true
    config.consider_all_requests_local = true
    config.active_support.deprecation = :log
    config.eager_load = false
end
