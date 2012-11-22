require 'json'


#
#
# Base class for custodian protocol-tests
#
# Each subclass will register themselves, via the call
# to 'register_test_type'.
#
# This class is a factory that will return the correct
# derived class for a given line from our configuration
# file - or that line encoded as a JSON string.
#
#
module Custodian

  class TestFactory


    #
    # The subclasses we have.
    #
    @@subclasses = { }


    #
    # Create a test-type object given a line of text from our parser.
    #
    # The line will be like "target must run tcp|ssh|ftp|smtp .."
    #
    #
    def self.create( line )

      #
      # JSON ?
      #
      if ( line =~ /^\{(.*)\}$/ )
        begin
          obj = JSON.parse( line );
          raise ArgumentError, "JSON object was not a hash" unless obj.kind_of?(Hash)
          line = obj["line"]
          raise ArgumentError, "obj[:line] was nil" unless (!line.nil?)
        rescue =>ex
          raise ArgumentError, "Line did not deserialize from JSON: #{line} - #{ex}"
        end
      end


      #
      # If this is an obvious protocol test.
      #
      if ( line =~ /must\s+run\s+(\S+)(\s+|\.|$)/ )
        test_type = $1.dup
        test_type.chomp!( "." )

        c = @@subclasses[test_type]
        if c
          c.new( line )
        else
          raise ArgumentError, "Bad test type: #{test_type}"
        end
      else
        raise "Unknown line given - Failed to instantiate a suitable protocol-test."
      end
    end


    #
    # Register a new test type - this must be called by our derived classes
    #
    def self.register_test_type name
      @@subclasses[name] = self
    end


    #
    # Return an array of test-types we know about
    #
    # i.e. Derived classes that have registered themselves.
    #
    #
    def types
      @@subclasses
    end




    #
    # Return the target of this test.
    #
    def target
      @host
    end




    #
    #  Return the port of this test.
    #
    def port
      @port
    end




  end

end
