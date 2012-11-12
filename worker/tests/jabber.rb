require 'timeout'


#
# Run a Jabber test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def jabber_test ( params )

  #
  #  Get the hostname & port to test against.
  #
  host = params['target_host']
  port = 5222

  puts "Jabber testing host #{host}:#{port}"


  begin
    timeout(3) do

      begin
        socket = TCPSocket.new( host, port )
        socket.puts( "QUIT")

        banner = socket.gets(nil)
        banner = banner[0,20]

        socket.close()

        if ( banner =~ /xml version/i )
          puts "Jabber alive: #{banner}"
          return true
        end
      rescue
        puts "Jabber exception on host #{host}:#{port} - #{$!}"
        return false
      end
    end
  rescue Timeout::Error => e
    puts "TIMEOUT: #{e}"
    return false
  end

  return false
end
