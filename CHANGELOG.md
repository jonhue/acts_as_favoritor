# Changelog

This file tracks all unreleased breaking changes and deprecations on `master`. You can find a list of all releases [here](https://github.com/jonhue/acts_as_favoritor/releases).

acts_as_favoritor follows Semantic Versioning 2.0 as defined at http://semver.org.

### Breaking Changes

* Passing an array containing a single scope to a method (e.g. `user.favorited?(book, scopes: [:purchase])`) now returns a hash as a result (e.g. `{ purchase: true }`). Use `user.favorited?(book, scope: :purchase) to receive the same result as in earlier versions.

### Deprecated

* None
