require 'custodian/protocoltest/tcp'


#
#  The SSH-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run ssh otherwise 'ssh fail'.
###
#
#  The specification of the port is optional, and defaults to 22.
#
module Custodian

  module ProtocolTest

    class SSHTest < TCPTest

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
          @port = 22
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

        run_test_internal(@host, @port, /SSH/i, true)
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'ssh'




    end
  end
end
