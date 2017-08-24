# -*- encoding: utf-8 -*-
require File.expand_path(File.join('..', 'lib', 'acts_as_favoritor', 'version'), __FILE__)

Gem::Specification.new do |gem|
    gem.name                  = 'acts_as_favoritor'
    gem.version               = ActsAsFavoritor::VERSION
    gem.platform              = Gem::Platform::RUBY
    gem.summary               = 'A Rubygem to add Favorite, Follow, Vote, etc. functionality to ActiveRecord models'
    gem.description           = 'acts_as_favoritor is a Rubygem to allow any ActiveRecord model to associate any other model including the option for multiple relationships per association with scopes. You are able to differentiate followers, favorites, watchers, votes and whatever else you can imagine through a single relationship. This is accomplished by a double polymorphic relationship on the Favorite model. There is also built in support for blocking/un-blocking favorite records.'
    gem.authors               = ['Jonas Hübotter']
    gem.email                 = 'developer@slooob.com'
    gem.homepage              = 'https://github.com/slooob/acts_as_favoritor'
    gem.license               = 'MIT'

    gem.files                 = `git ls-files`.split("\n")
    gem.require_paths         = ['lib']
    gem.bindir                = 'bin'
    gem.executables           = ['acts_as_favoritor']

    gem.post_install_message  = IO.read('INSTALL.md')

    gem.required_ruby_version = '>= 2.3'

    gem.add_dependency 'activerecord', '>= 4.0'

    gem.add_development_dependency 'sqlite3', '~> 1.3'
    gem.add_development_dependency 'shoulda_create', '~> 0.0'
    gem.add_development_dependency 'shoulda', '~> 3.5'
    gem.add_development_dependency 'factory_girl', '~> 4.8'
    gem.add_development_dependency 'rails', '>= 4.0'
    gem.add_development_dependency 'tzinfo-data', '~> 1.2017'
end
