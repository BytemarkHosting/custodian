
require 'custodian/settings'
require 'uri'


#
#  The open-proxy test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must not run openproxy otherwise 'insecurity'.
###
#
#
module Custodian

  module ProtocolTest


    class OpenProxyTest < TestFactory

      #
      # The line from which we were constructed.
      #
      attr_reader :line


      #
      # Constructor
      #
      def initialize(line)

        #
        #  Save the line
        #
        @line = line

        #
        #  Save the target
        #
        @host = line.split(/\s+/)[0]

        #
        # Is this test inverted?
        #
        if  line =~ /must\s+not\s+run\s+/
          @inverted = true
        else
          @inverted = false
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
        settings = Custodian::Settings.instance
        period   = settings.timeout

        begin
          timeout(period) do
            begin
              c = Curl::Easy.new
              c.follow_location = true
              c.max_redirects   = 10
              c.ssl_verify_host = false
              c.proxy_url       = @host
              c.proxy_tunnel    = true
              c.url             = 'http://google.com/'
              c.ssl_verify_peer = false
              c.timeout         = period
              c.perform
              @status = c.response_code
              @content = c.body_str
            rescue Curl::Err::SSLCACertificateError => x
              @error = 'SSL-Validation error'
              return false
            rescue Curl::Err::TimeoutError
              @error = 'Timed out fetching page.'
              return false
            rescue Curl::Err::TooManyRedirectsError
              @error = 'Too many redirections (more than 10)'
              return false
            rescue => x
               @error = "Exception: #{x}"
              return false
            end
          end
        rescue Timeout::Error => e
          @error = 'Timed out during fetch.'
          return false
        end

        #
        # A this point we've either had an exception, or we've
        # got a result.
        #
        if (@status.to_i == 200)
            return true
        else
            @error = "Proxy fetch of http://google.com/ via #{@host} failed"
            return false
        end
      end



      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'openproxy'



    end
  end
end
