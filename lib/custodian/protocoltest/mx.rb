require 'custodian/protocoltest/tcp'

#
#  The MX (DNS + smtp) test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### bytemark.co.uk must run mx otherwise 'mail fail'.
###
#
#
module Custodian

  module ProtocolTest

    class MXTest < TestFactory


      #
      # Constructor
      #
      def initialize( line )
        @line = line
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

        # reset the error, in case we were previously executed.
        @error = nil

        return true;
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "mx"




    end
  end
end
