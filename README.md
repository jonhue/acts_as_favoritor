# acts_as_favoritor

acts_as_favoritor is a Rubygem to allow any ActiveRecord model to associate any other model including the option for multiple relationships per association with scopes.

You are able to differentiate followers, favorites, watchers, votes and whatever else you can imagine through a single relationship. This is accomplished by a double polymorphic relationship on the Favorite model. There is also built in support for blocking/un-blocking favorite records as well as caching.

## Installation

You can add acts_as_favoritor to your `Gemfile` with:

```ruby
gem 'acts_as_favoritor'
```

And then run:

    $ bundle install

Or install it yourself as:

    $ gem install acts_as_favoritor

If you always want to be up to date fetch the latest from GitHub in your `Gemfile`:

```ruby
gem 'acts_as_favoritor', github: 'jonhue/acts_as_favoritor'
```

Now run the generator:

    $ rails g acts_as_favoritor

To wrap things up, migrate the changes into your database:

    $ rails db:migrate

## Usage

### Setup

Add `acts_as_favoritable` to the models you want to be able to get favorited:

```ruby
class User < ActiveRecord::Base
  acts_as_favoritable
end

class Book < ActiveRecord::Base
  acts_as_favoritable
end
```

Specify which models can favorite other models by adding `acts_as_favoritor`:

```ruby
class User < ActiveRecord::Base
  acts_as_favoritor
end
```

### `acts_as_favoritor` methods

```ruby
book = Book.find(1)
user = User.find(1)

# `user` favorites `book`.
user.favorite(book)

# `user` removes `book` from favorites.
user.unfavorite(book)

# Whether `user` has marked `book` as his favorite.
user.favorited?(book)

# Returns an Active Record relation of `user`'s `Favorite` records that have not been blocked.
user.all_favorites

# Returns an array of all unblocked favorited objects of `user`. This can be a collection of different object types, e.g.: `User`, `Book`.
user.all_favorited

# Returns an Active Record relation of `Favorite` records where the `favoritable_type` is `Book`.
user.favorites_by_type('Book')

# Returns an Active Record relation of all favorited objects of `user` where `favoritable_type` is 'Book'.
user.favorited_by_type('Book')

# Returns the exact same as `user.favorited_by_type('User')`.
user.favorited_users

# Whether `user` has been blocked by `book`.
user.blocked_by?(book)

# Returns an array of all favoritables that blocked `user`.
user.blocked_by
```

### `acts_as_favoritable` methods

```ruby
# Returns all favoritors of a model that `acts_as_favoritable`
book.favoritors

# Returns an Active Record relation of records with type `User` following `book`.
book.favoritors_by_type('User')

# Returns the exact same as `book.favoritors_by_type('User')`.
book.user_favoritors

# Whether `book` has been favorited by `user`.
book.favorited_by?(user)

# Block a favoritor
book.block(user)

# Unblock a favoritor
book.unblock(user)

# Whether `book` has blocked `user` as favoritor.
book.blocked?(user)

# Returns an array of all blocked favoritors.
book.blocked
```

### `Favorite` model

```ruby
# Returns an Active Record relation of all `Favorite` records where `blocked` is `false`.
Favorite.unblocked

# Returns an Active Record relation of all `Favorite` records where `blocked` is `true`.
Favorite.blocked

# Returns an Active Record relation of all favorites of `user`, including those who were blocked.
Favorite.for_favoritor(user)

# Returns an Active Record relation of all favoritors of `book`, including those who were blocked.
Favorite.for_favoritable(book)
```

### Scopes

Using scopes with `acts_as_favoritor` enables you to Follow, Watch, Favorite, [...] between any of your models. This way you can separate distinct functionalities in your app between user states. For example: A user sees all his favorited books in a dashboard (`'favorite'`), but he only receives notifications for those, he is watching (`'watch'`). Just like YouTube or GitHub do it. Options are endless. You could also integrate a voting / star system similar to YouTube or GitHub

By default all of your favorites are scoped to `'favorite'`.

You can create new scopes on the fly. Every single method takes `scope`/`scopes` as an option which expexts a symbol or an array of symbols containing your scopes.

So lets see how this works:

```ruby
user.favorite(book, scopes: [:favorite, :watching])
user.unfavorite(book, scope: :watching)
second_user = User.find(2)
user.favorite(second_user, scope: :follow)
```

That's simple!

When you call a method which returns something while specifying multiple scopes, the method returns the results in a hash with the scopes as keys when scopes are given as an array:

```ruby
user.favorited?(book, scopes: [:favorite, :watching]) # => { favorite: true, watching: false }
user.favorited?(book, scopes: [:favorite]) # => { favorite: true }
user.favorited?(book, scope: :favorite) # => true
```

`acts_as_favoritor` also provides some handy scopes for you to call on the `Favorite` model:

```ruby
# Returns all `Favorite` records where `scope` is `my_scope`
Favorite.send("#{my_scope}_list")

## Examples
### Returns all `Favorite` records where `scope` is `favorites`
Favorite.favorite_list
### Returns all `Favorite` records where `scope` is `watching`
Favorite.watching_list
```

### Caching

When you set the option `cache` in `config/initializers/acts_as_favoritor.rb` to true, you are able to cache the amount of favorites/favoritables an instance has regarding a scope.

For that you need to add some database columns:

*acts_as_favoritor*

```ruby
add_column :users, :favoritor_score, :text
add_column :users, :favoritor_total, :text
```

*acts_as_favoritable*

```ruby
add_column :users, :favoritable_score, :text
add_column :users, :favoritable_total, :text
add_column :books, :favoritable_score, :text
add_column :books, :favoritable_total, :text
```

Caches are stored as hashes with scopes as keys:

```ruby
user.favoritor_score # => { favorite: 1 }
user.favoritor_total # => { favorite: 1, watching: 1 }
second_user.favoritable_score # => { follow: 1 }
book.favoritable_score # => { favorite: 1 }
```

**Note:** Only scopes who have favorites are included.

`acts_as_favoritor` makes it even simpler to access cached values:

```ruby
user.favoritor_favorite_cache # => 1
second_user.favoritable_follow_cache # => 1
book.favoritable_favorite_cache # => 1
```

**Note:** These methods are available for every scope you are using.

## Configuration

You can configure acts_as_favoritor by passing a block to `configure`. This can be done in `config/initializers/acts_as_favoritor.rb`:

```ruby
ActsAsFavoritor.configure do |config|
  config.default_scope = :follow
end
```

**`default_scope`** Specify your default scope. Takes a string. Defaults to `:favorite`. Learn more about scopes [here](#scopes).

**`cache`** Whether `acts_as_favoritor` uses caching or not. Takes a boolean. Defaults to `false`. Learn more about caching [here](#caching).

## Development

To start development you first have to fork this repository and locally clone your fork.

Install the projects dependencies by running:

    $ bundle install

### Testing

Tests are written with RSpec and can be found in `/spec`.

To run tests:

    $ bundle exec rspec

To run RuboCop:

    $ bundle exec rubocop

## Contributing

We warmly welcome everyone who is intersted in contributing. Please reference our [contributing guidelines](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

[Here](https://github.com/jonhue/acts_as_favoritor/releases) you can find details on all past releases. Unreleased breaking changes that are on the current master can be found [here](CHANGELOG.md).

acts_as_favoritor follows Semantic Versioning 2.0 as defined at http://semver.org.

### Publishing

1. Review breaking changes and deprecations in `CHANGELOG.md`.
1. Change the gem version in `lib/acts_as_favoritor/version.rb`.
1. Reset `CHANGELOG.md`.
1. Create a pull request to merge the changes into `master`.
1. After the pull request was merged, create a new release listing the breaking changes and commits on `master` since the last release.
2. The release workflow will publish the gem to RubyGems.
