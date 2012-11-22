
#
#  The DNS-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### DNSHOSTS must run dns for bytemark.co.uk resolving NS as '80.68.80.26;85.17.170.78;80.68.80.27'.
###
#
#
module Custodian
  module ProtocolTest

    class DNSTest < TestFactory


      #
      # The line from which we were constructed.
      #
      attr_reader :line



      #
      # Constructor
      #
      def initialize( line )

        #
        #  Save the line
        #
        @line = line

      end




      #
      # Helper for development.
      #
      def to_s
        "dns-test - TODO."
      end




      #
      # Convert this class to JSON such that it may be serialized.
      #
      def to_json
        hash = { :line => @line }
        hash.to_json
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




      register_test_type "dns"




    end
  end
end