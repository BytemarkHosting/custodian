require 'custodian/settings'
require 'custodian/testfactory'
require 'custodian/util/tftp'

require 'uri'


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
        url = line.split(/\s+/)[0]

        #
        #  Ensure we've got a TFTP url.
        #
        if url !~ /^tftp:/
          raise ArgumentError, "The target wasn't a TFTP URL: #{line}"
        end

        #
        #  Parse the URL which should have a host + path, and optional port
        #
        u = URI.parse(url)

        #
        #  Record the values.
        #
        @host = u.host
        @file = u.path

        # Port might not be specified, if it is missing then default to 69.
        @port = u.port || '69'
        @port = @port.to_i

        #
        # Ensure there is a file to fetch
        #
        if @file.nil? || @file.empty?
          raise ArgumentError, 'Missing file name'
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
