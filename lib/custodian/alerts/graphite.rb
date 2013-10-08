require 'socket'

#
#  The graphite-alerter.
#
#  This only exists to record timing durations in the local
# graphite/carbon instance.  Updates are sent via UDP
# to localhost:2003.
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
        host.gsub!(/[\/\\.]/, "_")
        test = @test.get_type

        #
        # The payload
        #
        str  = "#{test}.#{host}"
        payload = "monitor.#{str} #{ms} #{Time.now.to_i}"

        #
        #  Send via UDP.
        #
	socket = UDPSocket.new()
	socket.send( payload, 0, "localhost", 2003 );
	socket.close()

      end

      register_alert_type "graphite"


    end
  end
end
