require 'custodian/protocoltest/tcp'

#
#  The Redis-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run redis otherwise 'memory database fail'.
###
#
#  The specification of the port is optional and defaults to 6379
#
module Custodian

  module ProtocolTest

    class RedisTest < TCPTest

      #
      # Constructor
      #
      # Ensure we received a port to run the test against.
      #
      def initialize(line)

        #
        # Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split(/\s+/)[0]

        #
        # Save the port
        #
        if  line =~ /on\s+([0-9]+)/
          @port = $1.dup
        else
          @port = 6379
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

        # reset the error, in case we were previously executed.
        @error = nil

        run_test_internal(@host, @port)
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'redis'



    end
  end
end
