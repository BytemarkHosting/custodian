require 'custodian/protocoltest/tcp'


#
#  The telnet-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run telnet otherwise 'insecure-login fail'.
###
#
#  The specification of the port is optional and defaults to 23.
#
module Custodian

  module ProtocolTest

    class TelnetTest < TCPTest


      #
      # Constructor
      #
      def initialize(line)

        #
        # Save the line.
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split(/\s+/)[0]

        #
        # Is this test inverted?
        #
        if  line =~ /must\s+not\s+run\s+/ 
          @inverted = true
        else
          @inverted = false
        end

        #
        # Save the port
        #
        if  line =~ /on\s+([0-9]+)/ 
          @port = $1.dup
        else
          @port = 23
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




      register_test_type 'telnet'




    end
  end
end
