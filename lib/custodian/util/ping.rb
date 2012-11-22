
require 'custodian/util/dns'



#
# This class has methods to determine whether the target
# of a hostname/IP address is IPv4 or IPv6.
#
# Assuming the address resolves to one of those two types
# it can invoke on of /usr/bin/ping or /usr/bin/ping6 appropriately.
#
module Custodian

  module Util

    class Ping

      #
      # The hostname we'll ping, and the resolved address.
      #
      attr_reader :hostname, :resolved

      #
      # Save the hostname away, resolve it if possible.
      #
      def initialize( hostname )
        @hostname = hostname
        @resolved = Custodian::Util::DNS.hostname_to_ip( hostname )
      end


      #
      # Return the resolved address
      #
      def address
        @resolved
      end



      #
      # Does the hostname resolve to an IPv4 address?
      #
      def is_ipv4?
        if ( ( ! @resolved.nil? ) && ( @resolved =~  /^([0-9]+).([0-9]+).([0-9]+).([0-9]+)$/ ) )
          true
        else
          false
        end
      end


      #
      # Does the hostname resolve to an IPv6 address?
      #
      def is_ipv6?
        if ( ( ! @resolved.nil? ) && ( @resolved =~  /^([a-f0-9:]+)$/i ) )
          true
        else
          false
        end
      end



      #
      # Run the ping - if it succeeds return "true".
      #
      # Return false on error.
      #
      def run_ping
        if ( is_ipv6? )
          if ( system( "ping6 -c 1 #{@resolved} 2>/dev/null >/dev/null" ) == true )
            return true
          end
        elsif( is_ipv4? )
          if ( system( "ping -c 1 #{@resolved} 2>/dev/null >/dev/null" ) == true )
            return true
          end
        else
          puts "ERROR: Resolved to neither an IPv6 or IPv4 address."
        end
        return false
      end

    end

  end
end
