#--
# Copyright (c) 2018 Iikka Niinivaara
# Copyright (c) 2011-2017 David Kellum
# Copyright (c) 2010-2011 Don Werve
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++

$CLASSPATH << `sbt "export runtime:fullClasspath" | grep -v '\\[*\\]'`.chomp.split(':')
$USE_CLASSPATH = true

require 'rubygems'
require 'bundler/setup'

# All dependencies for testing.
require 'yaml'
require 'net/http'
require 'openssl'
require 'rack/urlmap'
require 'rack/lint'
require 'birdmonger'

Thread.abort_on_exception = true

# Adjust Rack::Lint to not interfere with File body.to_path
class Rack::Lint

  def respond_to?( mth )
    if mth == :to_path
      @body.respond_to?( :to_path )
    else
      super
    end
  end

  def to_path
    @body.to_path
  end

end

RSpec.configure do |cfg|
  cfg.expect_with(:rspec) { |c| c.syntax = :should }
  cfg.mock_with(:rspec) { |m| m.syntax = :should }
end
