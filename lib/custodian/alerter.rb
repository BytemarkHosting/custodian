
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


  #
  # Details of the test case which we're going to raise/clear.
  #
  attr_reader :details


  #
  # The currently allocated IP-ranges which belong to Bytemark.
  #
  # These are used to test if an alert refers to a machine outwith our
  # network.
  #
  BYTEMARK_RANGES = %w(80.68.80.0/20 89.16.160.0/19 212.110.160.0/19 46.43.0.0/18 91.223.58.0/24 213.138.96.0/19 5.153.224.0/21 2001:41c8::/32).collect{|i| IPAddr.new(i)}



  #
  # Constructor.
  #
  # Save the details away.
  #
  def initialize( test_details )
    @details = test_details
  end



  #
  # Is the named target inside the Bytemark IP-range?
  #
  def inside_bytemark?( target )

    #
    #  Test trange, and format the appropriate message.
    #
    inside = false

    if ( BYTEMARK_RANGES.any?{|range| range.include?(IPAddr.new(target))} )
      inside = true
    end

    inside
  end




  #
  # Expand to a message indicating whether a hostname is inside the Bytemark network.
  # or not.
  #
  #
  def expand_inside_bytemark( host )

    #
    #  If the host is a URL then we need to work with the hostname component alone.
    #
    #  We'll also make the host a link that can be clicked in the alert we raise.
    #
    target = host
    if ( target =~ /https?:\/\/([^\/]+)/ )
      target = $1.dup
      host   = "<a href=\"#{host}\">#{host}</a>"
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
    #  Return the formatted message
    #
    if ( inside_bytemark?( resolved.to_s ) )
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
  # Generate an alert-message which will be raised via mauve.
  #
  def raise( detail )

    #
    #  Get ready to send to mauve.
    #
    update         = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"
    update.replace = false

    #
    # Construct an alert with our test details.
    #
    alert = get_alert()

    #
    #  We're raising this alert.
    #
    alert.raise_time = Time.now.to_i

    #
    #  Update it and send it
    #
    update.alert << alert
    Mauve::Sender.new("alert.bytemark.co.uk").send(update)
  end



  #
  # Generate an alert-message which will be cleared via mauve.
  #
  def clear

    #
    #  Get ready to send to mauve.
    #
    update = Mauve::Proto::AlertUpdate.new
    update.alert   = []
    update.source  = "custodian"
    update.replace = false


    #
    # Construct an alert with our test details.
    #
    alert = get_alert()

    #
    #  We're clearing this alert.
    #
    alert.clear_time = Time.now.to_i

    #
    #  Update it and send it
    #
    update.alert << alert
    Mauve::Sender.new("alert.bytemark.co.uk").send(update)
  end




  #
  # Using the test-data-hash which was set in the constructor
  # generate a useful alert that can be fired off to mauve.
  #
  # Most of the mess of this method is ensuring there is some
  # "helpful" data in the detail-field of the alert.
  #
  def get_alert

    #
    # Is this alert affecting a machine inside/outside our network?
    #
    inside = expand_inside_bytemark( @details["target_host"] )


    #
    # The subject of an alert should be one of:
    #
    #   1.  Hostname.
    #
    #   2.  IP address
    #
    #   3.  A URL.
    #
    #
    # We attempt to resolve the alert to the hostname, as that is readable.
    #
    #
    subject = @details['target_host']
    if ( ( subject =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
         ( subject =~ /^([0-9a-f:]+)$/ ) )
      res = DNSUtil.ip_to_hostname( subject )
      if ( res )
        subject = res
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


    alert         = Mauve::Proto::Alert.new
    alert.id      = "#{@details['test_type']}-#{@details['target_host']}"
    alert.subject = subject
    alert.summary = @details['test_alert']
    alert.detail  = "#{inside} <p>The #{@details['test_type']} test succeeded against #{@details['target_host']}</p><p>#{resolved}</p>"

    #
    # Return the alert to the caller.
    #
    alert
  end


end
