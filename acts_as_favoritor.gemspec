# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'acts_as_favoritor/version'

Gem::Specification.new do |gem|
    gem.name        = 'acts_as_favoritor'
    gem.version     = ActsAsFavoritor::VERSION
    gem.authors     = ['Jonas Hübotter']
    gem.email       = ['developer@slooob.com']
    gem.homepage    = 'https://github.com/slooob/acts_as_favoritor'
    gem.summary     = 'A Rubygem to add Favorite, Follow, etc. functionality to ActiveRecord models'
    gem.description = 'acts_as_favoritor is a Rubygem to allow any ActiveRecord model to favorite any other model. This is accomplished through a double polymorphic relationship on the Favorite model. There is also built in support for blocking/un-blocking favorite records.'
    gem.license     = 'MIT'

    gem.files         = `git ls-files`.split("\n")
    gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    gem.require_paths = ['lib']

    gem.required_ruby_version = '>= 2.0'

    gem.add_dependency 'activerecord', '>= 4.0'

    gem.add_development_dependency 'sqlite3', '~> 1.3'
    gem.add_development_dependency 'shoulda_create', '~> 0.0'
    gem.add_development_dependency 'shoulda', '~> 3.5'
    gem.add_development_dependency 'factory_girl', '~> 4.8'
    gem.add_development_dependency 'rails', '>= 4.0'
    gem.add_development_dependency 'tzinfo-data', '~> 1.2017'
end
