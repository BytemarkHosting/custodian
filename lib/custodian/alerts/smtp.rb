


#
#  The SMTP-alerter.
#
module Custodian

  module Alerter

    class SMTP < AlertFactory

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




      def raise
        puts "Sould raise an alert via EMAIL"
        puts "Subject: #{test.target} failed #{test.get_type}-test - #{test.error()}"
        puts "TO: #{@target}"
      end




      def clear
        puts "Should clear an alert via EMAIL"
        puts "Subject: #{test.target} passed #{test.get_type}-test"
        puts "TO: #{@target}"
      end




      register_alert_type "smtp"




    end
  end
end
