require 'resolv'




#
#  The DNSBL test.
#
#  This object is instantiated if the parser sees a line such as:
#
###
### 1.2.3.4 must not run dnsbl via zen.spamhaus.org otherwise 'The IP is blacklisted in spamhaus'.
###
#
#

module Custodian

  module ProtocolTest

    class DNSBLTest < TestFactory


      #
      # Save away state from the configuration line.
      #
      def initialize(line)
        @line = line
        @host = line.split(/\s+/)[0]

        #
        # Ensure the host is an IP address.
        #
        raise ArgumentError, 'The target must be an IP address' unless @host =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/

        #
        # See which blacklist(s) we're testing against.
        #
        if  line =~ /via\s+([^\s]+)\s+/ 
          @zones = $1.dup
        else
          @zones = 'zen.spamhaus.org'
        end

        #
        # Is this test inverted?
        #
        if  line =~ /must\s+not\s+run\s+/ 
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
      # Return "true" on success - if the IP is listed.  False if not.
      #
      def run_test

        # The error is empty.
        @error  = nil

        @zones.split(',').each do |zone|

          #
          #  Convert the IP to be looked up.
          #
          #  Given IP 1.2.3.4 we lookup the address of the name
          # 4.3.2.1.$zone
          #
          if  @host =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ 

            name = "#{$4}.#{$3}.#{$2}.#{$1}.#{zone}"

            result = Custodian::Util::DNS.hostname_to_ip(name)

            if  (!result.nil?) && (result.length > 0) 
              @error = "IP #{@host} listed in blacklist #{zone}.  Lookup of #{name} lead to result: #{result}"
              return true
            end

          else
             @error = "#{@host} wasn't an IP address"
             return true
          end
        end

        false
      end


      #
      # If the test failed here we will return a suitable error message.
      #
      def error
        @error
      end

      # register ourselves with the class-factory
      register_test_type 'dnsbl'
    end
  end
end
