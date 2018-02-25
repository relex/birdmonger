#--
# Copyright (c) 2018 Iikka Niinivaara
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

module Rack
  module Handler
    class Birdmonger

      include_package 'birdmonger'

      include_package 'java.nio.charset'

      include_package 'com.twitter.finagle.http'
      include_package 'com.twitter.io'
      include_package 'com.twitter.util'

      def self.run(app, rack_opts = {})
        birdmonger_opts = Shellwords.split(ENV['BIRDMONGER_OPTS'] || '')

        if (endpoint = birdmonger_opts.find { |opt| opt.start_with?('-birdmonger.endpoint') })
          rack_opts[:Host], rack_opts[:Port] = endpoint.split(':')
        else
          birdmonger_opts.unshift("-birdmonger.endpoint=#{rack_opts[:Host]}:#{rack_opts[:Port]}")
        end

        set_handler(app, rack_opts)

        Birdmonger::Server.main(birdmonger_opts.to_java(:string))
      end

      def self.shutdown
        Birdmonger::Server.close(Duration.from_seconds(10))
      end

      private

      def self.set_handler(app, rack_opts)
        Birdmonger::Server.handler_ = ->(request, headers) do
          ruby_io = StringIO.new
          ruby_io.set_encoding(Encoding.find('ASCII-8BIT'))
          buf = Await.result(Reader.read_all(request.reader))
          ruby_io.write(Buf.decode_string(buf, Charset.for_name('ASCII')))
          ruby_io.rewind

          env = {
              'REQUEST_METHOD' => request.method.to_s,
              'SCRIPT_NAME' => '',
              'PATH_INFO' => request.path,
              'QUERY_STRING' => Birdmonger::Request.query_string(request.params).sub(/^\?/, ''),
              'SERVER_NAME' => rack_opts[:Host],
              'SERVER_PORT' => rack_opts[:Port],
              'REMOTE_ADDR' => request.remote_host,
              'rack.version' => Rack::VERSION,
              'rack.url_scheme' => Birdmonger::Server.scheme,
              'rack.multithread' => true,
              'rack.multiprocess' => false,
              'rack.run_once' => false,
              'rack.hijack?' => false,
              'rack.input' => ruby_io,
              'rack.errors' => $stderr
          }.merge(Hash[headers.map do |k, v|
            k = k.tr('-', '_').upcase
            if %w(CONTENT_TYPE CONTENT_LENGTH).include?(k)
              [k, v]
            else
              ['HTTP_' + k, v]
            end
          end])

          status, headers, body, _ = app.call(env)

          res = Birdmonger::Response.apply(request.version, Status.from_code(status))

          headers.each { |k, vs| vs.split("\n").each { |v| res.header_map.add(k, v) } }

          if body.respond_to?(:to_path)
            begin
              file = java.io.File.new(body.to_path)
              fis = java.io.FileInputStream.new(file)
              channel = fis.channel
              buffer = java.nio.ByteBuffer.allocate(1_048_576)

              res.with_output_stream(->(os) do
                while channel.read(buffer) > 0
                  buffer.flip
                  buffer.limit.times { os.write(buffer.get) }
                  buffer.clear
                end
              end)
            ensure
              channel.close if channel
              fis.close if fis
            end
          else
            res.with_writer(->(writer) { body.each { |chunk| writer.write(chunk) } })
          end

          body.close if body.respond_to?(:close)

          res
        end
      end

    end
  end
end
