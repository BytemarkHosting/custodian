

require 'mauve/sender'
require 'mauve/proto'

require 'ipaddr'
require 'socket'



#
#  This class encapsulates the raising and clearing of alerts via Mauve.
#
class Alerter


  attr_reader :details

  BYTEMARK_RANGES = %w(80.68.80.0/20 89.16.160.0/19 212.110.160.0/19 46.43.0.0/18 91.223.58.0/24 213.138.96.0/19 5.153.224.0/21 2001:41c8::/32).collect{|i| IPAddr.new(i)}

  def initialize( test_details )
    @details = test_details
  end


  #
  # Expand to a message indicating whether a hostname is inside bytemark.
  #
  def expand_inside_bytemark( host )

    target = host
    if ( target =~ /https?:\/\/([^\/]+)/ )
      target = $1.dup
    end


    #
    #  Resolved IP of the target
    #
    resolved = nil

    #
    #  Resolve the target to an IP
    #
    begin
      Socket.getaddrinfo(target, 'echo').each do |a|
       resolved = a[3] if ( a )
      end
    rescue SocketError
    end

    return "" unless ( !resolved.nil? )

    #
    #  Test trange
    #
    if ( BYTEMARK_RANGES.any?{|range| range.include?(IPAddr.new(resolved.to_s))} )
      return "<p>#{host} resolves to #{target} which is inside the Bytemark network.</p>"
    else
      return "<p>#{host} resolves to #{target} which <b>is not</b> inside the Bytemark network.</p>"
    end

  end


  #
  # Raise the alert.
  #
  def raise( detail )

    inside = expand_inside_bytemark( @details["target_host"] )


    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false

    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = @details['target_host']
    alert.summary    = @details['test_alert']
    alert.detail     = "#{inside} <p>The #{@details['test_type']} test failed against #{@details['target_host']}: #{detail}</p>"
    alert.raise_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)

  end

  #
  #  Clear the alert.
  #
  def clear

    inside = expand_inside_bytemark( @details["target_host"] )

    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false


    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = @details['target_host']
    alert.summary    = @details['test_alert']
    alert.detail     = "#{inside} <p>The #{@details['test_type']} test succeeded against #{@details['target_host']}</p>"
    alert.clear_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)
  end

end
