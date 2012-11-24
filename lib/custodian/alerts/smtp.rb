


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
      # Constructor
      #
      def initialize( obj )
        @test = obj
      end



      register_alert_type "smtp"




    end
  end
end
