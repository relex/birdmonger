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

require 'spec_helper'
require 'test_app'
require 'thread'
require 'digest/md5'
require 'base64'
require 'json'

describe Birdmonger do

  [:http, :https].each do |scheme|
    describe "for #{scheme.to_s} scheme" do

      def get(path, headers = {}, &block )
        Net::HTTP.start(@options[:host], @options[:port],
                        nil, nil, nil, nil, # Irrelevant http proxy parameters
                        @https_client_opts) do |http|
          request = Net::HTTP::Get.new(path, headers)
          if block
            http.request(request, &block)
          else
            http.request(request)
          end
        end
      end

      def post(path, params = nil, headers = {}, body = nil)
        Net::HTTP.start(@options[:host], @options[:port],
                        nil, nil, nil, nil, # Irrelevant http proxy parameters
                        @https_client_opts) do |http|
          request = Net::HTTP::Post.new(path, headers)
          request.form_data = params if params
          if body
            if body.respond_to?( :read )
              request.body_stream = body
            else
              request.body = body
            end
          end
          http.request(request)
        end
      end

      before(:all) do
        ENV['BIRDMONGER_OPTS'] = '-birdmonger.startServer=false'

        @scheme = scheme

        @options = {
            :host => '127.0.0.1',
            :port => 8888,
        }

        if @scheme == :https
          @https_client_opts = {
              use_ssl: true,
              ciphers: "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA",
              verify_mode: OpenSSL::SSL::VERIFY_NONE
          }

          ENV['BIRDMONGER_OPTS'] += ' -birdmonger.tls.certificatePath=spec/data/certificate.pem -birdmonger.tls.keyPath=spec/data/key.pem'
        end

        @app = Rack::Lint.new(TestApp.new)

        Net::HTTP.version_1_2

        ENV['BIRDMONGER_OPTS'] += ' -admin.port=:0'

        Rack::Handler::Birdmonger.run(@app, Host: @options[:host], Port: @options[:port].to_s)
        @server = Java::Birdmonger::Server.apply

        # FIXME: Why doesn't Await.ready ever return?
        # Java::com.twitter.util::Await.ready(@server)

        success = false
        counter = 0
        until success
          sleep 1
          counter += 1
          puts "Still waiting for TwitterServer (#{counter})" if counter % 10 == 0
          begin
            get('/ping')
            success = true
          rescue Errno::ECONNREFUSED
            success = false
          end

        end
      end

      after(:all) do
        @server.close
      end

      it "returns 200 OK" do
        response = get("/ping")
        response.code.should == "200"
      end

      it "returns 403 FORBIDDEN" do
        response = get("/error/403")
        response.code.should == "403"
      end

      it "returns 404 NOT FOUND" do
        response = get("/jimmy/hoffa")
        response.code.should == "404"
      end

      it "sets Rack headers" do
        response = get("/echo")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content["rack.multithread"].should be true
        content["rack.multiprocess"].should be false
        content["rack.run_once"].should be false
      end

      it "passes form variables via GET" do
        response = get("/echo?answer=42")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content['request.params']['answer'].should == '42'
      end

      it "passes form variables via POST" do
        question = "What is the answer to life, the universe, and everything?"
        response = post("/echo", 'question' => question)
        response.code.should == "200"
        content = JSON.parse(response.body)
        content['request.params']['question'].should == question
      end

      it "Passes along larger non-form POST body" do
        body = '<' + "f" * (93*1024) + '>'
        headers = { "Content-Type" => "text/plain" }
        response = post("/dcount", nil, headers, body)
        response.code.should == "200"
        response.body.to_i.should == body.size * 2
      end

      it "Passes along larger non-form POST body when chunked" do
        body = '<' + "f" * (93*1024) + '>'
        headers = { "Content-Type" => "text/plain",
                    "Transfer-Encoding" => "chunked" }
        response = post("/dcount", nil, headers, StringIO.new( body ) )
        response.code.should == "200"
        response.body.to_i.should == body.size * 2
      end

      it "passes custom headers" do
        response = get("/echo", "X-My-Header" => "Pancakes")
        response.code.should == "200"
        content = JSON.parse(response.body)
        content["HTTP_X_MY_HEADER"].should == "Pancakes"
      end

      it "returns multiple values of the same header" do
        response = get("/multi_headers")
        response['Warning'].should == "warn-1, warn-2"
        # Net::HTTP handle multiple headers with join( ", " )
      end

      it "sets the server port and hostname" do
        response = get("/echo")
        content = JSON.parse(response.body)
        content["SERVER_PORT"].should == @options[:port].to_s
        content["SERVER_NAME"].should == @options[:host]
      end

      it "sets the client address" do
        response = get("/echo")
        content = JSON.parse(response.body)
        content["REMOTE_ADDR"].should == "127.0.0.1"
      end

      it "passes the URI scheme" do
        response = get("/echo")
        content = JSON.parse(response.body)
        content['rack.url_scheme'].should == @scheme.to_s
      end

      it "supports file downloads" do
        response = get("/download")
        response.code.should == "200"
        response['Content-Type'].should == 'image/png'
        checksum = Digest::MD5.hexdigest(response.body)
        checksum.should == '8da4b60a9bbe205d4d3699985470627e'
      end

      it "supports file uploads" do
        boundary = '349832898984244898448024464570528145'
        content = []
        content << "--#{boundary}"
        content << 'Content-Disposition: form-data; name="file"; ' +
            'filename="reddit-icon.png"'
        content << 'Content-Type: image/png'
        content << 'Content-Transfer-Encoding: base64'
        content << ''
        content <<
            Base64.encode64( File.read('spec/data/reddit-icon.png') ).strip
        content << "--#{boundary}--"
        body = content.map { |l| l + "\r\n" }.join('')
        headers = { "Content-Type" =>
                        "multipart/form-data; boundary=#{boundary}" }
        response = post("/upload", nil, headers, body)
        response.code.should == "200"
        response.body.should == '8da4b60a9bbe205d4d3699985470627e'
      end

      it "handles frozen Rack responses" do
        response = get("/frozen_response")
        response.code.should == "200"
      end

      xit "handles response hijacking" do
        chunks = []
        get( "/hijack" ) do |resp|
          resp.code.should == '200'
          resp.read_body do |chunk|
            chunks << chunk
          end
        end
        chunks.should == [ "hello", " world\n" ]
      end

      xit "handles ugly response hijacking" do
        chunks = []
        get( "/hijack?ugly=t" ) do |resp|
          resp.code.should == '200'
          resp.read_body do |chunk|
            chunks << chunk
          end
        end
        chunks.should == [ "hello", " world\n" ]
      end

      xit "gracefully declines request hijacking" do
        chunks = []
        resp = get( "/request_hijack" )
        resp.code.should == '200'
        resp.body.should =~ /^Only response hijacking is supported/
      end

    end

  end

end
