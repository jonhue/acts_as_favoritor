# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'acts_as_favoritor/version'

Gem::Specification.new do |s|
    s.name        = 'acts_as_favoritor'
    s.version     = ActsAsFollower::VERSION
    s.authors     = ['Jonas Hübotter']
    s.email       = ['developer@slooob.com']
    s.homepage    = 'https://github.com/slooob/acts_as_favoritor'
    s.summary     = 'A Rubygem to add Favorite functionality for ActiveRecord models'
    s.description = 'acts_as_favoritor is a Rubygem to allow any ActiveRecord model to favorite any other model. This is accomplished through a double polymorphic relationship on the Favorite model. There is also built in support for blocking/un-blocking favorite records.'
    s.license     = 'MIT'

    s.rubyforge_project = 'acts_as_follower'

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ['lib']

    s.add_dependency 'activerecord', '>= 4.0'

    s.add_development_dependency 'sqlite3'
    s.add_development_dependency 'shoulda_create'
    s.add_development_dependency 'shoulda', '>= 3.5.0'
    s.add_development_dependency 'factory_girl', '>= 4.2.0'
    s.add_development_dependency 'rails', '>= 4.0'
end
