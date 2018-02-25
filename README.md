# Birdmonger

A [Finagle](http://twitter.github.io/finagle/)-based (via [TwitterServer](http://twitter.github.io/twitter-server)) Rack server for JRuby. Includes all benefits of Finagle and TwitterServer. Requires no legacy war stuff, so no Warbler.

Specs are forked from [Fishwife](https://github.com/dekellum/fishwife), which in turn is forked from [Mizuno](https://github.com/matadon/mizuno).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'birdmonger'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install birdmonger

## Usage

    $ rackup -s Birdmonger
    
Or with e.g. Rails

    $ RACK_HANDLER=Birdmonger rails s

## Development

After checking out the repo, run `bundle install` to install dependencies. Compile Scala code with `sbt clean assembly`. Run tests: `bundle exec rspec`. Package a new gem with `bundle exec rake build`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mebe/birdmonger.

## TODO

- [x] Support HTTPS
- [ ] Support H2
- [ ] Support hijacks
- [ ] Fix sleep in spec before(:all)

## License

Copyright (c) 2018 Iikka Niinivaara

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You
may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

### Fishwife

Copyright (c) 2011-2017 David Kellum

Licensed under the Apache Public License, version 2.0.

### Mizuno

Copyright (c) 2010-2011 Don Werve

Licensed under the Apache Public License, version 2.0.
