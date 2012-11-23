require 'openssl'
require 'socket'
require 'timeout'
require 'uri'



#
#  The HTTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### http://foo.vm.bytemark.co.uk/ must run http with content 'foo' otherwise 'ftp fail'.
###
#
#
module Custodian

  module ProtocolTest


    class HTTPTest < TestFactory

      #
      # The line from which we were constructed.
      #
      attr_reader :line

      #
      # The URL to poll
      #
      attr_reader :url

      #
      # The expected status + content
      #
      attr_reader :expected_status, :expected_content


      #
      # The actual status & content
      #
      attr_reader :status, :content



      #
      # Constructor
      #
      def initialize( line )

        #
        #  Save the line
        #
        @line = line

        #
        #  Save the URL
        #
        @url  = line.split( /\s+/)[0]

        if ( @url !~ /^https?:/ )
          raise ArgumentError, "The target wasn't an URL"
        end

        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end

        #
        # Expected status
        #
        if ( line =~ /with status ([0-9]+)/ )
          @expected_status = $1.dup
        else
          @expected_status = "200"
        end

        #
        # The content we expect to find
        #
        if ( line =~ /with content '([^']+)'/ )
          @expected_content = $1.dup
        else
          @expected_content = nil
        end

        @status  = nil
        @content = nil

      end




      #
      # Allow this test to be serialized.
      #
      def to_s
        @line
      end



      #
      # Run the test.
      #
      def run_test

        #  Reset state, in case we've previously run.
        @error = nil

        #  Parse the URL
        uri = URI.parse(@url)

        #
        # Ensure we have a path to request - to cover people who write:
        #
        #   http://example.com must run http ..
        #
        if ( uri.path.empty? )
          uri.path = "/"
        end

        #
        #  Connect a socket to the host.
        #
        socket = connect( uri.host, uri.port, uri.scheme == "https" )

        path = uri.path
        if ( uri.query )
          path = "#{url.path}?#{url.query}"
        end

        req =<<EOF
GET #{path} HTTP/1.1
Host: #{uri.host}
Connection: close

EOF

        do_check( socket, req )

        if ( @expected_status.to_i != @status.to_i )
          @error = "Status code was #{@status} not the expected #{@expected_status}"
          return false
        end

        if ( !@expected_content.nil? )
          if (! @content.match(/#{@expected_content}/i) )
            @error = "<p>The response did not contain our expected text '#{@expected_content}'</p>"
          end
        end

        #
        #  Done?
        #
        true
      end



      #
      # Create a socket to the appropriate host - configuring
      # SSL if appropriate.
      #
      def connect( host, port, ssl )
        sock = TCPSocket.new(host, port)
        if ( ssl)
          ssl_sock = OpenSSL::SSL::SSLSocket.new(
                                                 sock,
                                                 OpenSSL::SSL::SSLContext.new("SSLv3_client")
                                                 )
          ssl_sock.sync_close = true
          ssl_sock.connect
          return ssl_sock
        else
          return sock
        end
      end



      #
      # Send the request and get back the response.
      #
      def do_check( socket, script )
        header = true

        begin
          Timeout.timeout(30, Errno::ETIMEDOUT) do
            script.each do |line|
              if line.is_a?(String)
                socket.print line
              end
            end

            loop do
              trans = socket.gets

              if ( header && trans =~ /HTTP\/[0-9]\.[0-9] ([0-9]+) OK/ )
                @status = $1.dup
              end
              if ( header && trans =~ /^$/ )
                header = false
                next
              end

              if ( !header )
                @content = "#{@content}#{trans}"
              end
              break if trans.nil?
            end
            socket.close
          end
        rescue => err
          @error = err
        ensure
          socket.close if socket.is_a?(Socket) and not socket.closed?
        end

      end



      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "http"
      register_test_type "https"




    end
  end
end
