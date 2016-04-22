require 'custodian/protocoltest/tcp'


#
#  The RSYNC-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### upload.ns.bytemark.co.uk must run rsync otherwise 'dns upload failure'.
###
#
#  The specification of the port is optional and defaults to 873
#
module Custodian

  module ProtocolTest

    class RSYNCTest < TCPTest


      #
      # Constructor
      #
      def initialize(line)

        #
        # Save the line.
        #
        @line = line

        #
        # If the target is an URL then strip to the hostname.
        #
        @host = line.split(/\s+/)[0]
        if @host =~ /^rsync:\/\/([^\/]+)\/?/
          @host = $1.dup
        end

        #
        # Save the port
        #
        if line =~ /on\s+([0-9]+)/
          @port = $1.dup
        else
          @port = 873
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

        run_test_internal(@host, @port, /^@RSYNCD/, true)
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'rsync'




    end
  end
end
