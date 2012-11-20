
require 'custodian/dnsutil'

require 'mauve/sender'
require 'mauve/proto'


require 'ipaddr'



#
#  This class encapsulates the raising and clearing of alerts via Mauve.
#
#  There is a helper method to update any alerts with details of whether the
# affected host is inside/outside the Bytemark network.
#
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
    #  Resolve the target to an IP, unless it is already an address.
    #
    if ( ( target =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( target =~ /^([0-9a-f:]+)$/ ) )
      resolved = target
    else
      resolved = DNSUtil.hostname_to_ip( target )
    end


    #
    # Did we get an error?
    #
    return "" unless ( !resolved.nil? )


    #
    # Make any HTTP target a link in the details.
    #
    if ( host =~ /^http/ )
        host = "<a href=\"#{host}\">#{host}</a>"
    end

    #
    #  Test trange, and format the appropriate message.
    #
    inside = false;
    if ( BYTEMARK_RANGES.any?{|range| range.include?(IPAddr.new(resolved.to_s))} )
      inside = true
    end


    if ( inside )
      if ( resolved == target )
        return "<p>#{host} is inside the Bytemark network.</p>"
      else
        return "<p>#{host} resolves to #{resolved} which is inside the Bytemark network.</p>"
      end
    else
      if ( resolved == target )
        return "<p>#{host} is OUTSIDE the Bytemark network.</p>"
      else
        return "<p>#{host} resolves to #{resolved} which is OUTSIDE the Bytemark network.</p>"
      end
    end

  end


  #
  # Raise the alert.
  #
  def raise( detail )

    #
    # Is this alert affecting a machine inside/outside our network
    #
    inside = expand_inside_bytemark( @details["target_host"] )


    #
    # Subject of the alert.
    #
    # If it is purely numeric then resolve it
    #
    subject = @details['target_host']
    if ( ( subject =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( subject =~ /^([0-9a-f:]+)$/ ) )
      res = DNSUtil.ip_to_hostname( subject )

      if ( res )
        subject = "#{subject} [#{res}]"
      end
    end



    #
    # Document the hostname if the alert relates to an IP address.
    #
    resolved = ""
    if ( ( @details["target_host"] =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( @details["target_host"] =~ /^([0-9a-f:]+)$/ ) )

      resolved = DNSUtil.ip_to_hostname( @details["target_host"] )
      if ( resolved.nil? )
        resolved = ""
      else
        resolved = "The IP address #{@details["target_host"]} resolves to #{resolved}."
      end
    end


    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false

    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = subject
    alert.summary    = @details['test_alert']
    alert.detail     = "#{inside} <p>The #{@details['test_type']} test failed against #{@details['target_host']}: #{detail}</p><p>#{resolved}</p>"
    alert.raise_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)

  end

  #
  #  Clear the alert.
  #
  def clear

    #
    # Is this alert affecting a machine inside/outside our network
    #
    inside = expand_inside_bytemark( @details["target_host"] )

    #
    # Subject of the alert.
    #
    # If it is purely numeric then resolve it
    #
    subject = @details['target_host']
    if ( ( subject =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( subject =~ /^([0-9a-f:]+)$/ ) )
      res = DNSUtil.ip_to_hostname( subject )

      if ( res )
        subject = "#{subject} [#{res}]"
      end
    end


    #
    # Document the hostname if the alert relates to an IP address.
    #
    resolved = ""
    if ( ( @details["target_host"] =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( @details["target_host"] =~ /^([0-9a-f:]+)$/ ) )

      resolved = DNSUtil.ip_to_hostname( @details["target_host"] )
      if ( resolved.nil? )
        resolved = ""
      else
        resolved = "The IP address #{@details["target_host"]} resolves to #{resolved}."
      end
    end


    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"

    # be explicit about raising/clearing
    update.replace = false


    alert            = Mauve::Proto::Alert.new

    # e.g. ping-example.vm.bytemark.co.uk
    # e.g. http-http://example.com/page1
    alert.id         = "#{@details['test_type']}-#{@details['target_host']}"

    alert.subject    = subject
    alert.summary    = @details['test_alert']
    alert.detail     = "#{inside} <p>The #{@details['test_type']} test succeeded against #{@details['target_host']}</p><p>#{resolved}</p>"
    alert.clear_time = Time.now.to_i
    update.alert << alert

    Mauve::Sender.new("alert.bytemark.co.uk").send(update)
  end

end
