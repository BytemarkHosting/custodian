#
#  The graphite-alerter.
#
#  This only exists to record timing durations in the local graphite/carbon
# instance.
#
module Custodian

  module Alerter

    class GraphiteAlert < AlertFactory

      #
      # The test this alerter cares about
      #
      attr_reader :test


      #
      # Constructor - save the test-object away.
      #
      def initialize( obj )
        @test  = obj
      end



      #
      # NOP.
      #
      def raise
      end



      #
      # NOP.
      #
      def clear
      end



      #
      # Send the test test-duration to graphite/carbon
      #
      def duration( ms )

        #
        # hostname + test-type
        #
        host = @test.target
        test = @test.get_type

        #
        #  The key we'll send
        #
        str  = "#{test}-#{host}"
        str.gsub!(/\\\./, "-")
        str  = "monitor.#{str}"

        system( "/bin/echo '#{str} #{ms} #{Time.now.to_i}' | nc localhost 2003" )
      end

      register_alert_type "graphite"


    end
  end
end
