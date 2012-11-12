require 'timeout'


#
# Run an SMTP test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def smtp_test ( params )

  #
  #  Get the hostname & port to test against.
  #
  host = params['target_host']
  port = 25

  puts "SMTP testing host #{host}:#{port}"


  begin
    timeout(3) do

      begin
        socket = TCPSocket.new( host, port )
        socket.puts( "QUIT\n\n")

        banner = socket.gets(nil)
        banner = banner[0,20]

        socket.close()

        if ( banner =~ /SMTP/i )
          puts "SMTP alive: #{banner}"
          return true
        end
      rescue
        puts "SMTP exception on host #{host}:#{port} - #{$!}"
        return false
      end
    end
  rescue Timeout::Error => e

    puts "SMTP TIMEOUT: #{e}"
    return false
  end
  puts "SMTP Misc Failure"
  return false
end
