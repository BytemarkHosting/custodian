require 'custodian/protocoltest/tcp'


#
#  The Jabber-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run jabber otherwise 'chat failure'.
###
#
#  The specification of the port is optional, and defaults to 5222.
#
module Custodian

  module ProtocolTest

    class JABBERTest < TCPTest


      #
      # Constructor
      #
      def initialize( line )

        #
        # Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host  = line.split( /\s+/)[0]

        #
        # Is this test inverted?
        #
        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end

        #
        # Save the port
        #
        if ( line =~ /on\s+([0-9]+)/ )
          @port = $1.dup
        else
          @port = 5222
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

        run_test_internal( @host, @port, "<stream:stream" )
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "jabber"




    end
  end
end
