# Changelog

### master

* nothing yet

### 2.0.1 - 2018-01-01

* bugfixes
    * fixed error when generating files (without configuration becoming initialized)

### 2.0.0 - 2017-12-21

* features
    * configuration by passing a block to `configure`
    * generator generates initializer instead of yaml file

### 1.5.0 - 2017-09-02

* features
    * access scope specific caches through methods

### 1.4.0 - 2017-09-01

* features
    * update caching functionality to include `score` & `total`

### 1.3.2 - 2017-08-31

* features
    * add caching functionality to `acts_as_favoritor` & `acts_as_favoritable` model

### 1.2.2 - 2017-08-24

* bugfixes
    * `acts_as_favoritor` generator hotfix

### 1.2.1 - 2017-08-24

* enhancements
    * improve migration template
    * add installer readme
* minor bugfixes

### 1.2.0 - 2017-08-24

* features
    * add `blocked?` method to `acts_as_favoritor` model
    * add `blocked?` method to `acts_as_favoritable` model
    * add `favoritable_type` method to `acts_as_favoritor` model
    * add `favoritor_type` method to `acts_as_favoritable` model
    * add `blocks` method to `acts_as_favoritor` model
    * add `block` method to `acts_as_favoritor` model
    * add `unblock` method to `acts_as_favoritor` model
    * add `blocked_favoritables_count` method to `acts_as_favoritor` model
* minor bugfixes

### 1.1.3 - 2017-08-23

* bugfixes
    * `fix NoMethodError: undefined method 'each' for <SCOPE>:String`

### 1.1.2 - 2017-08-23

* bugfixes
    * migration hotfix

### 1.1.1 - 2017-08-23

* notes
    * default scope changed from `favorites` to `favorite`
* features
    * added configuration
* enhancements
    * add `scope` generator option
    * add `skip_configuration` generator option
    * index database columns
* minor bugfixes

### 1.1.0 - 2017-08-23

* features
    * add scope functionality

### 1.0.2 - 2017-08-22

* enhancements

### 1.0.1 - 2017-08-22

* bug fixes

### 1.0.0 - 2017-08-22

* initial release
