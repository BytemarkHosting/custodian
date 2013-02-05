require 'net/smtp'



module Custodian

  module ProtocolTest

    class SMTPRelayTest < TCPTest

      # save away state from the configuration line.
      def initialize( line )
        @line = line
        @host  = line.split( /\s+/)[0]

        if ( line =~ /must\s+not\s+run\s+/ )
          @inverted = true
        else
          @inverted = false
        end
      end


      # run the test for open relays of SMTP protocol - return true on success.
      # false on fail.
      # this requires love, just trying to get it to run for now..
      def run_test
        @error = nil # for if we've run the test before
        message = "This is a test for OPEN SMTP relays."
        
        begin
          Net::SMTP.start(@host,25) do |smtp|
            smtp.send_message message, "foo@bar.com", "foo@bar.com"
            @error = "Sent message, that's bad."
          end # Net SMTP

        rescue Exception => ex # for if we fail to send a message; this is a good thing
          return false
        end

      end


      # if the test failed return a suitable error message
      def error
        @error = "Couldn't send message; that's good, really."
      end

      # register ourselves with the factory so we're invoked for lines of the form:
      #  TARGET must (not) run xxx otherwise ...
      register_test_type "smtprelay"
    end
  end
end
