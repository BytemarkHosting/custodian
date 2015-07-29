require 'custodian/protocoltest/tcp'

#
#  The RDP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run rdp otherwise 'remote desktop fail'.
###
#
#  The specification of the port is optional and defaults to 3389
#
module Custodian

  module ProtocolTest

    class RDPTest < TCPTest


      #
      # Constructor
      #
      def initialize(line)

        #
        #  Save the line
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
          @port = 3389
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

        run_test_internal(@host, @port, nil, false)
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'rdp'




    end
  end
end
