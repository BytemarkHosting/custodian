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
        message = "Subject: SMTP Relay check\nThis is a test for OPEN SMTP relays."
        
        begin

          Net::SMTP.start(@host,25) do |smtp|
            sent = smtp.send_message message, "noreply@bytemark.co.uk", "noreply@bytemark.co.uk"

            @status = sent.status.to_s
            
            if @inverted === true
              @success = true
              @failure = false
            else 
              @success = false
              @failure = true
            end
            
            if @status === "250" #and @inverted == true
              @error = "NOT OK: message sent on #{@host} with status #{@status}"
              return @success
            else 
              @error = "OK: message not sent on #{@host} with status #{@status}"
              return @failure
            end
            
          end # Net SMTP

        rescue Exception => ex # for if we fail to send a message; this is a good thing
        
          @error = "OK: Timed out or connection refused on #{@host} with status #{@status}"
          return @failure
        end

      end


      # if the test failed return a suitable error message
      def error
        @error
      end

      # register ourselves with the factory so we're invoked for lines of the form:
      #  TARGET must (not) run xxx otherwise ...
      register_test_type "smtprelay"
    end
  end
end
