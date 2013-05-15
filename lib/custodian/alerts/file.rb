


#
#  The file-alerter.
#
#  This alert just writes events to a flat-file.
#
module Custodian

  module Alerter

    class AlertFile < AlertFactory

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
      # Record a raise event for the given test.
      #
      def raise
        write_message( "RAISE: #{test.target} failed #{test.get_type}-test - #{test.error()}" )
      end


      #
      # Record the duration of the given test.
      #
      def duration( seconds )
        write_message( "#{test.get_type}-test against #{test.target} took #{seconds}ms to complete" )
      end


      #
      # Record a clear event for the given test.
      #
      def clear
        write_message( "CLEAR: #{test.target} failed #{test.get_type}-test" )
      end


      #
      # Write the actual message to our target.
      #
      def write_message( msg )
        file = File.open(@target, "a")
        file.puts( "#{Time.now} #{msg}" )
        file.close

      end




      register_alert_type "file"




    end
  end
end
