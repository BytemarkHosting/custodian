require 'custodian/testfactory'


#
#  The SSL-expiry test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### https://foo.vm.bytemark.co.uk/ must run https with content 'page text' otherwise 'http fail'.
###
#
#
module Custodian

  module ProtocolTest

    class SSLCertificateTest < TestFactory


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

      end




      #
      # Allow this test to be serialized.
      #
      def to_s
        @line
      end



      #
      # Run the test - this means making a TCP-connection to the
      # given host and validating that the SSL-certificate is not
      # expired.
      #
      # Because testing the SSL certificate is relatively heavy-weight
      # and because they don't change often we only test in office-hours.
      #
      #
      def run_test

        hour = Time.now.hour

        #
        #  If outside 10AM-5PM we don't alert.
        #
        if ( hour < 10 || hour > 17 )
          return true
        end

        #
        # NOP - validate here.
        #
        return true
      end


      #
      # If the test fails then report the error.
      #
      def error
        @error
      end

      register_test_type "https"

    end
  end
end
