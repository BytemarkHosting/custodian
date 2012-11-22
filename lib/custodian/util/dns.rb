

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
      def DNS.ip_to_hostname( ip )
        resolved = nil
        begin
          timeout( 4 ) do
            begin
              Socket.getaddrinfo(ip, 'echo').each do |a|
                resolved = a[2] if ( a )
              end
            rescue SocketError
              resolved = nil
            end
          end
        rescue Timeout::Error => e
          resolved = nil
        end
        resolved
      end


      #
      # Convert a hostname to an IP address, return nil on failure.
      #
      def DNS.hostname_to_ip( hostname )

        resolved = nil

        begin
          timeout( 4 ) do
            begin
              Socket.getaddrinfo(hostname, 'echo').each do |a|
                resolved = a[3] if ( a )
              end
            rescue SocketError
              resolved = nil
            end
          end
        rescue Timeout::Error => e
          resolved = nil
        end
        resolved
      end

    end

  end
end




if __FILE__ == $0 then

  %w( ssh.steve.org.uk ipv6.steve.org.uk ).each do |name|
    puts "Hostname test: #{name} #{Custodian::Util::DNS.hostname_to_ip(name) }"
  end

  %w( 80.68.85.46 80.68.85.48 2001:41c8:125:46::22 ).each do |name|
    puts "Hostname test: #{name} #{Custodian::Util::DNS.ip_to_hostname(name) }"
  end
end
