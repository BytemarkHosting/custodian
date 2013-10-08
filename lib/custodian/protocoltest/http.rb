
require 'custodian/settings'
require 'uri'


#
#  The HTTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### http://foo.vm.bytemark.co.uk/ must run http with content 'page text' otherwise 'http fail'.
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


        #
        # Will we follow redirects?
        #
        @redirect = true


        #
        #  Ensure we've got a HTTP/HTTPS url.
        #
        if ( @url !~ /^https?:/ )
          raise ArgumentError, "The target wasn't a HTTP/HTTPS URL: #{line}"
        end


        #
        # Determine that the protocol of the URL matches the
        # protocol-test we're running
        #
        test_type = nil

        case line
        when /\s+must\s(not\s+)?run\s+http(\s+|\.|$)/i
        then
          test_type = "http"
        when /\s+must\s+(not\s+)?run\s+https(\s+|\.|$)/i
        then
          test_type = "https"
        else
          raise ArgumentError, "URL has invalid scheme: #{@line}"
        end

        #
        #  Get the schema of the URL
        #
        u = URI.parse( @url )
        if ( u.scheme != test_type )
          raise ArgumentError, "The test case has a different protocol in the URI than that which we're testing: #{@line} - \"#{test_type} != #{u.scheme}\""
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

        #
        # Do we follow redirects?
        #
        if ( line =~ /not following redirects?/i )
          @redirect = false
        end
      end


      #
      #  Get the right type of this object, based on the URL
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
      #  Do we follow redirects?
      #
      def follow_redirects?
        @redirect
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

        #
        # Get the timeout period for this test.
        #
        settings = Custodian::Settings.instance()
        period   = settings.timeout()

        #
        # The URL we'll fetch, which has a cache-busting
        # query-string
        #
        test_url = @url

        #
        #  Parse and append a query-string if not present.
        #
        u = URI.parse( test_url )
        if ( ! u.query )
          u.query   = "ctime=#{Time.now.to_i}"
          test_url  = u.to_s
        end


        begin
          timeout( period ) do
            begin


              c = Curl::Easy.new(test_url)

              #
              # Should we follow redirections?
              #
              if ( follow_redirects? )
                c.follow_location = true
                c.max_redirects   = 10
              end

              c.ssl_verify_host = false
              c.ssl_verify_peer = false
              c.timeout         = period
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
