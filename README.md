# Timetwister

A Chronic wrapper with improved date format parsing and fewer surprises.

Developed by the New York Public Library to transform freetext date metadata into machine-readable data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'timetwister'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timetwister

## Usage

Takes a date (or list of dates) as a string, and returns a list of hashes with parsed date data.

```ruby
require 'timetwister'
Timetwister.parse("Jun 1898 - [July 4 1900]")
 => [{:original_string=>"Jun 1898 - July 4 1900", :index_dates=>[1898, 1899, 1900], :date_start=>"1898-06-01", :date_end=>"1900-07-04", :date_start_full=>"1898-06-01", :date_end_full=>"1900-07-04", :inclusive_range=>true, :certainty=>"inferred", :test_data=>"330"}]
 ```

Output explanation:

- `:original_string` is the original input
- `:index_dates` is an `Array` of each year encompassed by the provided date range
- `:date_start` and `:date_end` are ISO8601 representations of the input date, with no assumed values
- `:date_start_full` and `:date_end_full` are ISO8601 representations of the input date in YYYY-MM-DD format (using assumed values when needed)
- `:inclusive_range` is whether or not the input value is a range
- `:certainty` is the certainty of the provided date, based on use of flags and punctuation

## Contributing

1. Fork it ( https://github.com/[my-github-username]/timetwister/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Update specs to test for new features (`rspec`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## Contributors

- [Alex Duryee](https://github.com/alexduryee/)
- [Trevor Thornton](https://github.com/trevorthornton/)
- [Matt Miller](https://github.com/thisismattmiller/)
- [Kristopher Kelly](https://github.com/emu47)
- [Stephen Schor](https://github.com/nodanaonlyzuul/)
