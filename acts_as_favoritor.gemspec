# frozen_string_literal: true

require File.expand_path(File.join('..', 'lib', 'acts_as_favoritor', 'version'), __FILE__)

Gem::Specification.new do |gem|
  gem.name                  = 'acts_as_favoritor'
  gem.version               = ActsAsFavoritor::VERSION
  gem.platform              = Gem::Platform::RUBY
  gem.summary               = 'A Rubygem to add Favorite, Follow, Vote, etc. ' \
                              'functionality to ActiveRecord models'
  gem.description           = 'acts_as_favoritor is a Rubygem to allow any ' \
                              'ActiveRecord model to associate any other ' \
                              'model including the option for multiple ' \
                              'relationships per association with scopes. You ' \
                              'are able to differentiate followers, ' \
                              'favorites, watchers, votes and whatever else ' \
                              'you can imagine through a single relationship. ' \
                              'This is accomplished by a double polymorphic ' \
                              'relationship on the Favorite model. There is ' \
                              'also built in support for blocking/un-blocking ' \
                              'favorite records as well as caching.'
  gem.authors               = 'Jonas Hübotter'
  gem.email                 = 'jonas.huebotter@gmail.com'
  gem.homepage              = 'https://github.com/jonhue/acts_as_favoritor'
  gem.license               = 'MIT'

  gem.files                 = Dir['README.md', 'LICENSE', 'lib/**/*']
  gem.require_paths         = ['lib']

  gem.required_ruby_version = '>= 2.7'

  gem.add_dependency 'activerecord', '>= 5.0'

  gem.add_development_dependency 'factory_bot'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'rails'
  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'rubocop-rails'
  gem.add_development_dependency 'rubocop-rspec'
  gem.add_development_dependency 'sqlite3'
end
