# acts_as_favoitor - Add Favorites to you Rails app

<img src="https://travis-ci.org/slooob/acts_as_favoritor.svg?branch=master" />

acts_as_favoritor is a Rubygem to allow any ActiveRecord model to favorite any other model. This is accomplished through a double polymorphic relationship on the Favorite model. There is also built in support for blocking/un-blocking favorite records.

---

## Installation

acts_as_favoritor works with Rails 4.0 onwards. You can add it to your `Gemfile` with:

```ruby
gem 'acts_as_favoritor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_favoritor

If you always want to be up to date fetch the latest from GitHub in your `Gemfile`:

```ruby
gem 'amphtml', github: 'slooob/acts_as_favoritor'
```

Now run the generator:

    $ rails g acts_as_follower

    $ rails db:migrate

This will create a Favorite model as well as a migration file.

**Note:** Use `rake db:migrate` instead if you run Rails < 5.

## Usage

---

## Contributors

Give the people some :heart: who are working on this project. Check them all at:

https://github.com/slooob/acts_as_favoritor/graphs/contributors

## License

MIT License

Copyright (c) 2017 Jonas Hübotter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
