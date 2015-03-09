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
# We take care to resolve any value we test, so that we can test explicitly
# for the family involved.  (i.e. If we're ping-testing example.com then
# we will explicitly look for an IPv4 and IPv6 address to test, rather than
# just using 'example.com'.)
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
      def run_test

        #
        # Find the binary we're going to invoke.
        #
        binary = nil
        binary = './bin/multi-ping'
        binary = '/usr/bin/multi-ping'  if  File.exist?( '/usr/bin/multi-ping' ) 

        if  binary.nil? 
          @error = "Failed to find '/usr/bin/multi-ping'"
          return false
        end


        #
        # Sanity check the hostname for ping-tests, to
        # avoid this security hole:
        #
        #   $(/tmp/exploit.sh) must run ping ..
        #
        if  @host !~ /^([a-zA-Z0-9:\-\.]+)$/ 
          @error = "Invalid hostname for ping-test: #{@host}"
          return false
        end


        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance
        period   = settings.timeout



        #
        # Perform the DNS lookups of the specified name.
        #
        ips = []

        #
        #  Does the name look like an IP?
        #
        begin
          x = IPAddr.new( @host )
          if  x.ipv4? or x.ipv6? 
            ips.push( @host )
          end
        rescue ArgumentError
        end


        #
        #  Both types?
        #
        do_ipv6 = true
        do_ipv4 = true

        #
        # Allow the test to disable one/both
        #
        if  @line =~ /ipv4_only/ 
          do_ipv6 = false
        end
        if  @line =~ /ipv6_only/ 
          do_ipv4 = false
        end

        #
        # OK if it didn't look like an IP address then attempt to
        # look it up, as both IPv4 and IPv6.
        #
        begin
          timeout( period ) do

            Resolv::DNS.open do |dns|
              if  do_ipv4 
                ress = dns.getresources(@host, Resolv::DNS::Resource::IN::A)
                ress.map { |r| ips.push( r.address.to_s ) }
              end
              if  do_ipv6 
                ress = dns.getresources(@host, Resolv::DNS::Resource::IN::AAAA)
                ress.map { |r| ips.push( r.address.to_s ) }
              end
            end
          end
        rescue Timeout::Error => e
          @error = "Timed-out performing DNS lookups: #{e}"
          return nil
        end


        #
        #  Did we fail to perform a DNS lookup?
        #
        if  ips.empty? 
          @error = "#{@host} failed to resolve to either IPv4 or IPv6"
          return false
        end


        #
        # Run the test, avoiding the use of the shell, for each of the
        # IPv4 and IPv6 addresses we discovered, or the host that we
        # were given.
        #
        ips.each do |ip|
          if ( system( binary, ip ) != true )
            @error = "Ping failed for #{ip} - from #{@host} "
            return false
          end
        end

        #
        # If there was a failure then the previous loop would have
        # set the @error value and returned false.
        #
        # So by the time we reach here we know that all the addresses
        # were pingable.
        #
        true
      end




      #
      # If the test fails then report the error.
      #
      def error
        @error
      end




      register_test_type 'ping'




    end
  end
end
