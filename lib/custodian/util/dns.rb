

require 'custodian/settings'
require 'ipaddr'
require 'socket'
require 'timeout'



#
#  This class is responsible for doing forward/reverse DNS lookups
#
module Custodian

  module Util

    class DNS


      #
      # Return the reverse DNS for the specified IP address, nil on failure.
      #
      def DNS.ip_to_hostname(ip)
        resolved = nil

        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance
        period   = settings.timeout

        begin
          timeout(period) do
            begin
              resolved = Socket.getnameinfo(Socket.sockaddr_in(80, ip)).first
            rescue SocketError
              resolved = nil
            end
          end
        rescue Timeout::Error => _e
          resolved = nil
        end
        resolved
      end


      #
      # Convert a hostname to an IP address, return nil on failure.
      #
      def DNS.hostname_to_ip(hostname)

        resolved = nil

        #
        # Get the timeout period.
        #
        settings = Custodian::Settings.instance
        period   = settings.timeout

        begin
          timeout(period) do
            begin
              Socket.getaddrinfo(hostname, 'echo').each do |a|
                resolved = a[3] if  a
              end
            rescue SocketError
              resolved = nil
            end
          end
        rescue Timeout::Error => _e
          resolved = nil
        end
        resolved
      end

    end

  end
end
