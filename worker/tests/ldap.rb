require 'timeout'


#
# Run an LDAP test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def ldap_test ( params )

  #
  #  Get the hostname & port to test against.
  #
  host = params['target_host']
  port = params['test_port']

  puts "LDAP testing host #{host}:#{port}"


  begin
    timeout(3) do

      begin
        socket = TCPSocket.new( host, port )
        socket.close()
        return true
      rescue
        puts "LDAP exception on host #{host}:#{port} - #{$!}"
        return false
      end
    end
  rescue Timeout::Error => e
    puts "TIMEOUT: #{e}"
    return false
  end
  return false
end
