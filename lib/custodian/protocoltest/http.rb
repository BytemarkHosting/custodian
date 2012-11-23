
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
        @error = "Not implemented"
        false
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
