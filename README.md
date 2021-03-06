# ActiveRecord Where Assoc

[![Build Status](https://travis-ci.org/MaxLap/activerecord_where_assoc.svg?branch=master)](https://travis-ci.org/MaxLap/activerecord_where_assoc)
[![Coverage Status](https://coveralls.io/repos/github/MaxLap/activerecord_where_assoc/badge.svg)](https://coveralls.io/github/MaxLap/activerecord_where_assoc)
[![Code Climate](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/gpa.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)
[![Issue Count](https://codeclimate.com/github/MaxLap/activerecord_where_assoc/badges/issue_count.svg)](https://codeclimate.com/github/MaxLap/activerecord_where_assoc)

NOTE: this gem is in active development:
 
* Expect it to be complete somewhere in April 2018.
* Until it is complete, the gem won't be published on rubygems.

This gem provides powerful methods to give you the power of SQL's EXISTS:

```
# Find my_post's comments that were not made by an admin
my_post.comments.where_assoc_not_exists(:author, is_admin: true).where(...)
 
# Find my_user's posts that have comments by an admin
my_user.posts.where_assoc_exists([:comments, :author], &:admins).where(...)
 
# Find my_user's posts that have at least 5 non-spam comments
my_user.posts.where_assoc_count(5, :>=, :comments) { |s| s.where(spam: false) }.where(...)
```

These allow for powerful, chainable, clear and easy to reuse scopes. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord_where_assoc'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activerecord_where_assoc

## Usage

### `#where_assoc_exists` & `#where_assoc_not_exists`
 
* The first parameter is the association we are doing the condition on.
* The second parameter (optional) is the condition to apply on the association. It can be anything that #where can receive, so: Hash, String and Array (string with binds).
* A block can also be passed. It can add conditions on the association's relation after all the conditions have been applied (association's scopes, default_scope, second parameter of the method).
  The block either:
  * Receive no argument, in that case self is set to the relation, so you can do { where(id: 123) }
  * Receive arguments, in that case, the block is called with the relation as first parameter
  The block should return the new relation to use or `nil` to do as if there were no blocks
  It's common to use where_assoc_*(..., &:scope_name) to apply a single scope quickly
  
### `#where_assoc_count`

* The first parameter can be a number or any string of SQL to embed in the SQL that returns a number that can be used for the comparison.
* The second parameter is the operator to use: `:<`, `:<=`, `:==`, `:>=`, `:>`
* The third and fourth parameters and the block are the same as the first and second parameters of `#where_assoc_exists`.

The order of the parameters may seem confusing. If you have better alternatives to suggest, feel free to open an issue to discuss this.

To help remember the order of the parameters, remember that the goal is to do:

    5 < (SELECT COUNT(*) FROM ...)

The parameters are in the same order as in that query: number, operator, association

## Supported Rails versions

Rails 5.1, 5.0, 4.2 and 4.1 are supported with Ruby 2.1 and above.

## More examples

High level explanation of various ways of using the methods. See next section for some tips.

```ruby
# Find my_post's comments that were not made by an admin
# Uses a Hash for the condition
my_post.comments.where_assoc_not_exists(:author, is_admin: true)

# Find my_user's posts that have comments by an admin
# Uses an array as shortcut to go to a nested related
# Uses the block shortcut to use a scope that exists on Author
my_user.posts.where_assoc_exists([:comments, :author], &:admins).where(...)

# Find my_user's posts that have at least 5 non-spam comments
# Uses a block with a parameter to do a condition
my_user.posts.where_assoc_count(5, :>=, :comments) { |s| s.where(spam: false) }

# Find my_user's posts that have at least 5 non-spam comments
# Uses a block without parameters to do a condition
my_user.posts.where_assoc_count(5, :>=, :comments) { where(spam: false) }

# Find my_user's posts that have comments by an honest admin
# Uses multiple associations.
# Uses a hash as 2nd parameter to do the conditions
my_user.posts.where_assoc_exists([:comments, :author], honest: true, is_admin: true)

# Find any post that has reached its maximum number of allowed comments
# Uses a string on the left side (first parameter) to refer to a column in the previous table.
Post.where_assoc_count("posts.max_comments_allowed", :==, :comments)
```

## Usage tips

### Nested associations

Sometimes, there isn't a single association that goes deep enough. In that situation, you can simply nest the scopes:

```ruby
# Find users that have a post that has a comment that was made by an admin.
# Using &:is_admin to use the is_admin scope (or any other class method of comments)
User.where_assoc_exists(:posts) { |posts|
    posts.where_assoc_exists(:comments) { |comments| 
        comments.where_assoc_exists(:author, &:is_admin)
    }
}
```

If you don't need special conditions on any of the intermediary associations, then you can use a shortcut:

```ruby
# Same as above
User.where_assoc_exists([:posts, :comments, :author], &:is_admin)
```

This shortcut can be used for every methods. The conditions and the block will be applied only to the last assocation of the chain.


### Beware of spreading conditions on multiple calls

The following have different meanings:

```ruby
my_user.posts.where_assoc_exists(:comments_authors, is_admin: true, honest: true)

my_user.posts.where_assoc_exists(:comments_authors, is_admin: true)
             .where_assoc_exists(:comments_authors, honest: true)
```

The first is the posts of my_user that have a comment made by an honest admin. It requires a single comment to match every conditions.

The second is the posts of my_user that have a comment made by an admin and a comment made by someone honest. It can be the same comment (like the first query) but also be 2 different comments.

### Inter-table conditions

It's possible, with string conditions, to refer to all the tables that are used before the association, including the source model.

```ruby
# Find posts where the author also commented on the post.
Post.where_assoc_exists(:comments, "posts.author_id = comments.author_id")
```

Note that some database systems limit how far up you can refer to tables in nested queries. Meaning it's possible that the following query may get refused because of those limits:

```ruby
# Somewhat far fetched... it's hard to come up with a good example.
Post.where_assoc_exists([:comments, :author, :address], "addresses.country = posts.database_country")
```

While doing the same thing, with less relations in between would not have issues.

### The opposite of multiple nested EXISTS...

... is a single NOT EXISTS with then nested ones still using EXISTS.

All the methods always chain nested associations using an EXISTS when they have to go through multiple hoops. Only the outer-most, or first, association will have a NOT EXISTS when using `#where_assoc_not_exists` or a COUNT when using `#where_assoc_count`. This is the logical way of doing it.

## Advantages
These methods many advantages over the alternative ways of achieving the similar results:
* Can be chained and nested with regular ActiveRecord scoping methods.
* They return relations with with a single added condition in the `WHERE` of the query.
  * You can easily have multiple conditions on different records of an association
* There is no joins needed:
  * No need for `#distinct` to remove duplicated records that are added by the joins. 
    (Avoids subtle bugs caused by unexpected `#distinct` in a scope) 
  * There are no duplicated results returned as you could have with joins & conditions
* Does not affect `includes` and `eager_load`
  * ActiveRecord only eager loads the records that match conditions the conditions of the query, which can lead to unexpected bugs.
* Applies the scope that was defined on the associations
* Applies the default_scopes that was defined on the target model
* Handles has_one correctly: Only testing the "first" record of the association that matches the default_scope and the scope on the association itself.

## Known issues/limitations

MySQL is terrible: On MySQL databases, it is not possible to use has_one associations and associations with a scope that apply either a limit or an offset.
I do not know of a way to do a query that can deal with all the specifics of has_one for MySQL. If you have one, then you may suggest it in an issue/pull request.

`has_many` and `has_one` using the `:through` option cannot have a scope that uses either `#limit` or `#offset`.
Making such cases work is pretty complicated and would require quite a bit of refactoring. So if a real need and use case is made, this may get fixed.  
`#limit` and `#offset` work fine in the scope of associations that do not use `:through`.

## Development

After checking out the repo, run `bundle install` to install dependencies.

Run `rake test` to run the tests for the latest version of rails

Run `bin/console` for an interactive prompt that will allow you to experiment in the same environment as the tests.

Run `bin/fixcop` to fix a lot of common styling mistake of your code and then display the remaining rubocop rules you break. Make sure to do this before committing and submitting PRs. Use common sense, sometimes it's okay to break a rule, add a [rubocop:disable comment](http://rubocop.readthedocs.io/en/latest/configuration/#disabling-cops-within-source-code) in that situation.

Run `bin/testall` to test all supported rails/ruby versions:
* It will tell you about missing ruby versions, which you can install if you want to test for them
* It will run `rake test` on each supported version or ruby/rails
* It automatically installs bundler if a ruby version doesn't have it
* It automatically runs `bundle install`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MaxLap/activerecord_where_assoc.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Acknowledgements

* [René van den Berg](https://github.com/ReneB) for some of the code of [activerecord-like](https://github.com/ReneB/activerecord-like) used for help with setting up the tests
