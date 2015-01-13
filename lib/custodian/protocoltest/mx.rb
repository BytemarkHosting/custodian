require 'custodian/protocoltest/tcp'

#
#  The MX (DNS + smtp) test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### bytemark.co.uk must run mx otherwise 'mail fail'.
###
#
#
module Custodian

  module ProtocolTest

    class MXTest < TestFactory


      #
      # Constructor
      #
      def initialize( line )

        # Save the line away
        @line = line

        # The main domain we're querying
        @host = line.split(/\s+/)[0]
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

        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance()
        period   = settings.timeout()

        #
        #  The MX-hosts
        #
        mx = Array.new()

        #
        #  Lookup the MX record
        #
        begin
          timeout( period ) do

            Resolv::DNS.open do |dns|
              ress = dns.getresources(@host, Resolv::DNS::Resource::IN::MX)
              ress.map { |r| mx.push( IPSocket::getaddress(r.exchange.to_s) ) }
            end
          end
        rescue Timeout::Error => e
          @error = "Timed-out performing DNS lookups: #{e}"
          return nil
        end

        #
        # At this point we should have an array of IPv4 or IPv6 addresses.
        #
        # If that array is empty then there will be no incoming mail because
        # there are now working MX records in DNS - or because the domain
        # has expired, etc.
        #
        # So on that basis we must alert.
        #
        if ( mx.empty? ) then
          @error = "Failed to perform DNS lookup of MX record(s) for host #{@host}"
          return false
        end

        mx.each do |bob|
          puts "XXXX #{bob}"
        end
        return true;
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type "mx"




    end
  end
end
