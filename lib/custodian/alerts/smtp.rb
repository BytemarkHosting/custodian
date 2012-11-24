
require 'net/smtp'

#
#  The SMTP-alerter.
#
module Custodian

  module Alerter

    class AlertSMTP < AlertFactory

      #
      # The test this alerter cares about
      #
      attr_reader :test



      #
      # Constructor - save the test-object away.
      #
      def initialize( obj )
        @test = obj
      end



      #
      # Raise an alert by email.
      #
      def raise
        subject = "#{test.target} failed #{test.get_type}-test - #{test.error()}"
        body    = "The alert has cleared\nRegards\n";

        _send_mail( @target, subject, body )
      end



      #
      # Clear an alert by email.
      #
      def clear
        subject = "#{test.target} failed #{test.get_type}-test"
        body    = "The alert has raised, with the following details:\n#{test.error()}\nRegards\n";

        _send_mail( @target, subject, body )
      end



      #
      # Send an email
      #
      def _send_mail( to, subject, body )
        msg = <<END_OF_MESSAGE
From: #{to}
To: #{to}
Subject: #{subject}

#{body}
END_OF_MESSAGE

        Net::SMTP.start("127.0.0.1") do |smtp|
          smtp.send_message( msg, to, to)
        end

      end


      register_alert_type "smtp"




    end
  end
end
