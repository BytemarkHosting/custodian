require 'custodian/settings'
require 'custodian/testfactory'
require 'custodian/util/tftp'


#
# The TFTP-protocol test
#
# This object is instantiated if the parser sees a line such as:
#
###
### tftp://foo.vm.bytemark.co.uk/pxelinux.0 must run tftp otherwise 'tftp fail'
###
#
#
module Custodian

  module ProtocolTest

    class TFTPTest < TestFactory

      #
      # The line from which we were constructed.
      #
      attr_reader :line

      #
      # The TFTP server
      #
      attr_reader :host

      #
      # The TFTP port
      #
      attr_reader :port

      #
      # The file on the TFTP server to test
      #
      attr_reader :file

      #
      # Constructor
      #
      def initialize(line)

        #
        #  Save the line
        #
        @line = line

        #
        #  Save the URL
        #
        url  = line.split(/\s+/)[0]

        #
        #  Ensure we've got a TFTP url.
        #
        if url !~ /^tftp:/
          raise ArgumentError, "The target wasn't a TFTP URL: #{line}"
        end

        #
        # Extract host, port and file from URL
        #
        if line =~ /^tftp:\/\/([^\/]+)\/([^\s]*)/
          @host = $1.split(':')[0]
          @file = $2.dup
          p = $1.split(':')[1]
          @port = (p && p.to_i > 0) ? p.to_i : 69
        end

        #
        # Ensure there is a file to fetch
        #
        if @file.nil? || @file.empty?
          raise ArgumentError, "Missing file name"
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
        tftp = Custodian::Util::Tftp.new(@host, @port)
        if tftp.test(@file)
          Custodian::TestResult::TEST_PASSED
        else
          @error = "TFTP failed for #{@file} on #{@host}"
          Custodian::TestResult::TEST_FAILED
        end
      end

      #
      # If the test fails then report the error.
      #
      def error
        @error
      end

      register_test_type 'tftp'

    end

  end

end
