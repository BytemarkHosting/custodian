require 'timeout'


#
# Run an rsync test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def rsync_test ( params )

  #
  #  Get the hostname
  #
  host = params['target_host']
  port = 873

  puts "rsync testing host #{host}:#{port}"


  begin
    timeout(3) do

      begin
        socket = TCPSocket.new( host, port )
        socket.puts( "QUIT")
        banner = socket.gets(nil)
        socket.close()

        banner = banner[0,20]
        if ( banner =~ /rsyncd/i )
          puts "rsync alive: #{banner}"
          return true
        end
      rescue
        puts "Exception on host #{host}:#{port} - #{$!}"
        return false
      end
    end
  rescue Timeout::Error => e
    puts "TIMEOUT: #{e}"
    return false
  end
  return false
end
