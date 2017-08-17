# TracLang

An implementation of TRAC Language, written in Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trac_lang'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install trac_lang

## Usage

Once it's installed, you can run:

    $ trac_lang
    
from the command line to start the TRAC interpreter.  You can also give it a file name of a file with TRAC commands in it to load those commands before you start the interpreter.  Try the examples/util.trl file to get a number of useful utilities loaded.  

TRAC is a macro language, meaning it consists solely of replacing strings of text with other strings.  In spite of this simplicity, it is surprisingly powerful, to the point where you can create a version of the Y combinator, as follows:

#(DS,Y,(
  #(#(lambda,<x>,(
    #(<f>,(#(<x>,<x>)))
  )),#(lambda,<x>,(
    #(<f>,(#(<x>,<x>)))
  )))
))
##(SS,Y,<f>)

You can read about the different TRAC commands available in the examples/README.trl file, or read the original manual by the creator of TRAC, Calvin Mooers:

https://web.archive.org/web/20050205173449/http://tracfoundation.org:80/t64tech.htm

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/trac_lang. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

