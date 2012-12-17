


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
      # The actual status & content received.
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
        @host = @url

        if ( @url !~ /^https?:/ )
          raise ArgumentError, "The target wasn't an URL: #{line}"
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

      end


      #
      #  Get the right type of this object, based on the
      # URL
      #
      def get_type
        if ( @url =~ /^https:/ )
          "https"
        elsif ( @url =~ /^http:/ )
          "http"
        else
          raise ArgumentError, "URL isn't http/https: #{@url}"
        end
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
        @error    = nil
        @status   = nil
        @content  = nil

        begin
          require 'rubygems'
          require 'curb'
        rescue LoadError
          @error = "The required rubygem 'curb' was not found."
          return false
        end

        begin
          timeout( 20 ) do
            begin
              c = Curl::Easy.new(@url)
              c.follow_location = true
              c.max_redirects   = 10
              c.ssl_verify_host = false
              c.ssl_verify_peer = false
              c.timeout         = 20
              c.perform
              @status = c.response_code
              @content = c.body_str
            rescue Curl::Err::SSLCACertificateError => x
              @error = "SSL-Validation error"
              return false
            rescue Curl::Err::TimeoutError
              @error = "Timed out fetching page."
              return false
            rescue Curl::Err::TooManyRedirectsError
              @error = "Too many redirections (more than 10)"
              return false
            rescue => x
               @error = "Exception: #{x}"
              return false
            end
          end
        rescue Timeout::Error => e
          @error = "Timed out during fetch."
          return false
        end

        #
        # A this point we've either had an exception, or we've
        # got a result
        #
        if ( @expected_status.to_i != @status.to_i )
          @error = "Status code was #{@status} not the expected #{@expected_status}"
          return false
        end

        if ( !@expected_content.nil? )
          if ( @content && (! @content.match(/#{@expected_content}/i) ) )
            @error = "<p>The response did not contain our expected text '#{@expected_content}'</p>"
            return false
          end
        end

        #
        #  All done.
        #
        return true
      end



      #
      # If the test fails then report the error../
      #
      def error
        @error
      end




      register_test_type "http"
      register_test_type "https"




    end
  end
end
