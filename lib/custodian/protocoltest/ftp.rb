require 'custodian/protocoltest/tcp'

#
#  The FTP-protocol test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### foo.vm.bytemark.co.uk must run ftp on 22 otherwise 'ftp fail'.
###
#
#  The specification of the port is optional and defaults to 21
#
module Custodian

  module ProtocolTest

    class FTPTest < TCPTest


      #
      # The line from which we were constructed.
      #
      attr_reader :line


      #
      # The host to test against.
      #
      attr_reader :host


      #
      # The port to connect to.
      #
      attr_reader :port





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
        @host  = line.split( /\s+/)[0]
        if ( @host =~ /^ftp:\/\/([^\/]+)\/?/ )
          @host = $1.dup
        end

        #
        # Save the port
        #
        if ( line =~ /on\s+([0-9]+)/ )
          @port = $1.dup
        else
          @port = 21
        end
      end




      #
      # Helper for development.
      #
      def to_s
        "ftp-test of #{@host}:#{@port}."
      end




      #
      # Convert this class to JSON such that it may be serialized.
      #
      def to_json
        hash = { :line => @line }
        hash.to_json
      end




      # Run the TCP-protocol test.
      #
      def run_test

        # reset the error, in case we were previously executed.
        @error = nil

        run_test_internal( @host, @port, "^220" )
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "ftp"




    end
  end
end
