


#
#  The SMTP-alerter.
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


      def duration( seconds )
        puts "XXX: #{seconds}"
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
