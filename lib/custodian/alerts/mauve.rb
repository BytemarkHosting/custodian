


#
#  The Mauve-alerter.
#
module Custodian

  module Alerter

    class Mauve < AlertFactory

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



      register_alert_type "mauve"




    end
  end
end
