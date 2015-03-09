

require 'custodian/util/bytemark'
require 'custodian/util/dns'

require 'digest/sha1'


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
      # Was this class loaded correctly?
      #
      attr_reader :loaded




      #
      # Constructor
      #
      def initialize(obj)
        @test = obj

        begin
          require 'mauve/sender'
          require 'mauve/proto'
          @loaded = true
        rescue
          puts 'ERROR Loading mauve libraries!'
          @loaded = false
        end
      end




      #
      # Generate an alert-message which will be raised via mauve.
      #
      def raise

        return unless @loaded

        #
        # Get ready to send to mauve.
        #
        update         = Mauve::Proto::AlertUpdate.new
        update.alert   = []
        update.source  = @settings.alert_source
        update.replace = false

        #
        # Construct a new alert structure.
        #
        alert = _get_alert(true)

        #
        #  We're raising this alert.
        #
        alert.raise_time = Time.now.to_i

        #
        # The supression period varies depending on the time of day.
        #
        hour = Time.now.hour
        wday = Time.now.wday

        #
        # Is this inside the working day?
        #
        working = false

        #
        # Lookup the start of the day.
        #
        day_start = @settings.key('day_start').to_i || 10
        day_end   = @settings.key('day_end').to_i   || 18

        #
        #  In hour suppress
        #
        working_suppress = @settings.key('working_suppress').to_i || 4
        oncall_suppress  = @settings.key('oncall_suppress').to_i  || 10

        #
        # If we're Monday-Friday, between the start & end time, then
        # we're in the working day.
        #
        if  ((wday != 0) && (wday != 6)) &&
             (hour >= day_start && hour < day_end)
          working = true
        end

        #
        # The suppression period can now be determined.
        #
        period = working ? working_suppress : oncall_suppress

        #
        # And logged.
        #
        puts "Suppression period is #{period}m"

        #
        # We're going to suppress this alert now
        #
        alert.suppress_until = Time.now.to_i + (period * 60)

        #
        #  Update it and send it
        #
        update.alert << alert
        Mauve::Sender.new(@target).send(update)

      end



      #
      # Generate an alert-message which will be cleared via mauve.
      #
      def clear

        return unless @loaded

        #
        # Get ready to send to mauve.
        #
        update = Mauve::Proto::AlertUpdate.new
        update.alert   = []
        update.source  = @settings.alert_source
        update.replace = false

        #
        # Construct a new alert structure.
        #
        alert = _get_alert(false)

        #
        #  We're clearing this alert.
        #
        alert.clear_time = Time.now.to_i

        #
        #  Update it and send it
        #
        update.alert << alert
        Mauve::Sender.new(@target).send(update)

      end






      #
      # Using the test object, which was set in the constructor,
      # generate a useful alert that can be fired off to mauve.
      #
      # Most of the mess of this method is ensuring there is some
      # "helpful" data in the detail-field of the alert.
      #
      def _get_alert(failure)

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

        if  (subject =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/) ||
             (subject =~ /^([0-9a-f:]+)$/)
          res = Custodian::Util::DNS.ip_to_hostname(subject)
          if  res
            subject = res
          end
        end


        #
        #  The test type + test target
        #
        test_host = test.target
        test_type = test.get_type

        alert         = Mauve::Proto::Alert.new

        #
        # Mauve only lets us use IDs which are <= 255 characters in length
        # hash the line from the parser to ensure it is short enough.
        # (IDs must be unique, per-source)
        #
        # Because there might be N-classes which implemented the test
        # we need to make sure these are distinct too.
        #
        id_key  = test.to_s
        id_key += test.class.to_s

        alert.id = Digest::SHA1.hexdigest(id_key)

        alert.subject = subject
        alert.summary = "The #{test_type} test failed against #{test_host}"

        #
        #  If we're raising then add the error
        #
        if  failure

          alert.detail  = "<p>The #{test_type} test failed against #{test_host}.</p>"

          #
          #  The text from the job-defition
          #
          user_text = test.get_notification_text

          #
          # Add the user-detail if present
          #
          alert.detail = "#{alert.detail}<p>#{user_text}</p>" if  !user_text.nil?

          #
          # Add the test-failure message
          #
          alert.detail = "#{alert.detail}<p>#{test.error}</p>"

          #
          #  Determine if this is inside/outside the bytemark network
          #
          location = expand_inside_bytemark(test_host)
          if  !location.nil? && location.length
            alert.detail = "#{alert.detail}\n#{location}"
          end
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
      def expand_inside_bytemark(host)

        #
        #  If the host is a URL then we need to work with the hostname component alone.
        #
        #  We'll also make the host a link that can be clicked in the alert we raise.
        #
        target = host
        if  target =~ /^([a-z]+):\/\/([^\/]+)/
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
        if  (target =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/) ||
             (target =~ /^([0-9a-f:]+)$/)
          resolved = target
        else
          resolved = Custodian::Util::DNS.hostname_to_ip(target)
        end


        #
        # Did we get an error?
        #
        return '' unless  !resolved.nil?


        #
        #  Return the formatted message
        #
        if  Custodian::Util::Bytemark.inside?(resolved.to_s)
          if (resolved == target)
            return "<p>#{host} is inside the Bytemark network.</p>"
          else
            return "<p>#{host} resolves to #{resolved} which is inside the Bytemark network.</p>"
          end
        else
          if (resolved == target)
            return "<p>#{host} is OUTSIDE the Bytemark network.</p>"
          else
            return "<p>#{host} resolves to #{resolved} which is OUTSIDE the Bytemark network.</p>"
          end
        end

      end


      register_alert_type 'mauve'




    end
  end
end
