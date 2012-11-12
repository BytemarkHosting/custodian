
#
# Run a PING test.
#
#
# Return value
#   TRUE:  The host is up
#
#  FALSE:  The host is not up
#
def ping_test( params )

  #
  # Find the binary
  #
  binary = nil
  binary = "./util/multi-ping"  if ( File.exists?( "./util/multi-ping" ) )
  binary = "../util/multi-ping" if ( File.exists?( "../util/multi-ping" ) )

  if ( binary.nil? )
    puts "Failed to find 'multi-ping'"
    exit 1
  end

  #
  # Is it IPv6 or IPv4a
  #
  host = params['target_host']
  if ( system( "#{binary} #{host}" ) == true )
    puts "PING OK"
    return  true
  else
    puts "PING FAILED"
    return false
  end
end
