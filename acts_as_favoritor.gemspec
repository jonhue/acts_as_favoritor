# frozen_string_literal: true

require File.expand_path(
  File.join('..', 'lib', 'acts_as_favoritor', 'version'),
  __FILE__
)

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |gem|
  gem.name                  = 'acts_as_favoritor'
  gem.version               = ActsAsFavoritor::VERSION
  gem.platform              = Gem::Platform::RUBY
  gem.summary               = 'A Rubygem to add Favorite, Follow, Vote, etc. '\
                              'functionality to ActiveRecord models'
  gem.description           = 'acts_as_favoritor is a Rubygem to allow any '\
                              'ActiveRecord model to associate any other '\
                              'model including the option for multiple '\
                              'relationships per association with scopes. You '\
                              'are able to differentiate followers, '\
                              'favorites, watchers, votes and whatever else '\
                              'you can imagine through a single relationship. '\
                              'This is accomplished by a double polymorphic '\
                              'relationship on the Favorite model. There is '\
                              'also built in support for blocking/un-blocking '\
                              'favorite records as well as caching.'
  gem.authors               = 'Jonas Hübotter'
  gem.email                 = 'me@jonhue.me'
  gem.homepage              = 'https://github.com/jonhue/acts_as_favoritor'
  gem.license               = 'MIT'

  gem.files                 = Dir['README.md', 'LICENSE', 'lib/**/*']
  gem.require_paths         = ['lib']

  gem.required_ruby_version = '>= 2.2.2'

  gem.add_dependency 'activerecord', '~> 5.2'

  gem.add_development_dependency 'factory_bot'
  gem.add_development_dependency 'rails', '~> 5.2'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'shoulda'
  gem.add_development_dependency 'shoulda_create'
  gem.add_development_dependency 'sqlite3'
end
# rubocop:enable Metrics/BlockLength
