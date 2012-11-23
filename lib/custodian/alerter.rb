
require 'custodian/util/bytemark'
require 'custodian/util/dns'



#
#  This class encapsulates the raising and clearing of alerts via Mauve.
#
#  There is a helper method to update any alerts with details of whether the
# affected host is inside/outside the Bytemark network.
#
#
module Custodian

  class Alerter

    #
    # Details of the test case which we're going to raise/clear.
    #
    attr_reader :test

    #
    #  Is this alerter available?
    #
    attr_reader :available


    #
    # Constructor.
    #
    # Save the details away.
    #
    def initialize( test_class )
      @test = test_class


      @available = true

      begin
        require 'mauve/sender'
        require 'mauve/proto'
      rescue LoadError
        @available = false
      end

      puts "ALERTER DISABLED: Steve"
      @available = false
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
        resolved = Custodian::Util::DNS.hostname_to_ip( target )
      end


      #
      # Did we get an error?
      #
      return "" unless ( !resolved.nil? )


      #
      #  Return the formatted message
      #
      if ( Custodian::Util::Bytemark.inside?( resolved.to_s ) )
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

      if ( !@available )
        puts "Should raise alert for test: #{test}"
        return
      end

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
      alert = get_alert(detail)

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

      if ( !@available )
        puts "Should clear alert for test: #{test}"
        return
      end

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
      alert = get_alert( "" )

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
    def get_alert( detail )

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
        res = Custodian::Util::DNS.ip_to_hostname( subject )
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

        resolved = Custodian::Util::DNS.ip_to_hostname( @details["target_host"] )
        if ( resolved.nil? )
          resolved = ""
        else
          resolved = "The IP address #{@details["target_host"]} resolves to #{resolved}."
        end
      end


      alert         = Mauve::Proto::Alert.new
      alert.id      = "#{@details['test_type']}-#{@details['target_host']}"
      alert.subject = subject
      alert.summary = "#{@details['test_alert']} to #{subject} failed #{detail}"
      alert.detail  = "#{inside} <p>The #{@details['test_type']} test failed against #{@details['target_host']}: #{detail}</p><p>#{resolved}</p>"

      #
      # Return the alert to the caller.
      #
      alert
    end

  end

end
