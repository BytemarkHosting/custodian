require 'custodian/testfactory'


#
#  The ping test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### DNSHOSTS must run ping otherwise ..
###
#
#
module Custodian

  module ProtocolTest

    class PINGTest < TestFactory


      #
      # Constructor
      #
      def initialize( line )

        #
        #  Save the line
        #
        @line = line

        #
        # Save the host
        #
        @host = line.split( /\s+/)[0]

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

        #
        # Find the binary we're going to invoke.
        #
        binary = nil
        binary = "/usr/bin/multi-ping"  if ( File.exists?( "/usr/bin/multi-ping" ) )

        if ( binary.nil? )
          @error = "Failed to find '/usr/bin/multi-ping'"
          return false
        end


        #
        # Sanity check the hostname for ping-tests, to
        # avoid this security hole:
        #
        #   $(/tmp/exploit.sh) must run ping ..
        #
        if ( @host !~ /^([a-zA-Z0-9:\-\.]+)$/ )
          @error = "Invalid hostname for ping-test: #{@host}"
          return false
        end


        #
        # Run the test: Avoiding the use of the shell.
        #
        if ( system( binary, @host ) == true )
          return true
        else
          @error = "Ping failed."
          return false
        end

      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "ping"




    end
  end
end
