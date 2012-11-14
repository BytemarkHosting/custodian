
require 'getoptlong'
require 'socket'



class MultiPing

  #
  # The hostname we'll ping, and the resolved address.
  #
  attr_reader :hostname, :resolved

  def initialize( hostname )
    @hostname = hostname
    @resolved = resolve_hostname( hostname )
  end


  #
  #
  #
  def resolve_hostname( hostname )
    res = nil

    begin
      Socket.getaddrinfo(hostname, 'echo').each do |a|
       res = a[3]
      end
    rescue SocketError
    end

    res
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
    if ( ( ! @resolved.nil? ) && ( @resolved =~  /^2001/ ) )
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

