require 'timeout'


#
# Run an FTP test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def ftp_test ( params )

  #
  #  Get the hostname & port to test against.
  #
  host = params['target_host']
  port = params['test_port']

  puts "FTP testing host #{host}:#{port}"


  begin
    timeout(3) do

      begin
        socket = TCPSocket.new( host, port )
        socket.puts( "QUIT")

        banner = socket.gets(nil)
        banner = banner[0,20]

        socket.close()

        if ( banner =~ /^220/ )
          puts "FTP alive: #{banner}"
          return true
        end
      rescue
        puts "FTP exception on host #{host}:#{port} - #{$!}"
        return false
      end
    end
  rescue Timeout::Error => e
    puts "TIMEOUT: #{e}"
    return false
  end

  return false
end
