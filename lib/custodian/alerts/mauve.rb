

require 'custodian/util/bytemark'
require 'custodian/util/dns'



#
#  This class encapsulates the raising and clearing of alerts via Mauve.
#
#  There is a helper method to update any alerts with details of whether the
# affected host is inside/outside the Bytemark network.
#
#  This is almost Bytemark-specific, although the server it talks to is
# indeed Open Source:
#
#    https://projects.bytemark.co.uk/projects/mauvealert
#
#
module Custodian

  module Alerter

    class AlertMauve < AlertFactory


      #
      # The test this alerter cares about
      #
      attr_reader :test




      #
      # Constructor
      #
      def initialize( obj )
        @test = obj

        begin
          require 'mauve/sender'
          require 'mauve/proto'
        rescue LoadError
          raise  "ERROR Loading mauvealert libraries!"
        end
      end




      #
      # Generate an alert-message which will be raised via mauve.
      #
      def raise()


        #
        # Get ready to send to mauve.
        #
        update         = Mauve::Proto::AlertUpdate.new
        update.alert   = []
        update.source  = "custodian"
        update.replace = false

        #
        # Construct a new alert structure.
        #
        alert = _get_alert( true )

        #
        #  We're raising this alert.
        #
        alert.raise_time = Time.now.to_i

        #
        #  Update it and send it
        #
        update.alert << alert
        Mauve::Sender.new( @target ).send(update)
      end



      #
      # Generate an alert-message which will be cleared via mauve.
      #
      def clear

        #
        # Get ready to send to mauve.
        #
        update = Mauve::Proto::AlertUpdate.new
        update.alert   = []
        update.source  = "custodian"
        update.replace = false

        #
        # Construct a new alert structure.
        #
        alert = _get_alert( false )

        #
        #  We're clearing this alert.
        #
        alert.clear_time = Time.now.to_i

        #
        #  Update it and send it
        #
        update.alert << alert
        Mauve::Sender.new( @target ).send(update)
      end






      #
      # Using the test object, which was set in the constructor,
      # generate a useful alert that can be fired off to mauve.
      #
      # Most of the mess of this method is ensuring there is some
      # "helpful" data in the detail-field of the alert.
      #
      def _get_alert( failure )

        #
        # The subject of an alert MUST be one of:
        #
        #   1.  Hostname.
        #   2.  IP address
        #   3.  A URL.
        #
        # We attempt to resolve the alert to the hostname, as that is more
        # readable, if we have been given an IP address.
        #
        subject = @test.target

        if ( ( subject =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/ ) ||
             ( subject =~ /^([0-9a-f:]+)$/ ) )
          res = Custodian::Util::DNS.ip_to_hostname( subject )
          if ( res )
            subject = res
          end
        end


        #
        #  The test type + test target
        #
        test_host = test.target
        test_type = test.get_type


        alert         = Mauve::Proto::Alert.new
        alert.id      = "#{test_type}-#{test_host}"
        alert.subject = subject
        alert.summary = "#{test_type}-#{test_host}"
        alert.detail  = "<p>The #{test_type} test failed against #{test_host}.</p>"

        #
        #  If we're raising then add the error
        #
        if ( failure )
          alert.detail = "#{alert.detail}\n#{test.error()}"
        end

        #
        #  Determine if this is inside/outside the bytemark network
        #
        location = expand_inside_bytemark( test_host )
        if ( !location.nil? && location.length )
          alert.detail = "#{alert.detail}\n#{location}"
        end

        #
        # Return the alert to the caller.
        #
        alert
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
        if ( target =~ /^([a-z]+):\/\/([^\/]+)/ )
          target = $2.dup
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


      register_alert_type "mauve"




    end
  end
end
