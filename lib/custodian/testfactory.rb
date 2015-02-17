

#
#
# Base class for custodian protocol-tests
#
# Each subclass will register themselves, via the call
# to 'register_test_type'.
#
# This class is a factory that will return the correct
# derived class for a given line from our configuration
# file.
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


      raise ArgumentError, "The type of test to create cannot be nil" if ( line.nil? )
      raise ArgumentError, "The type of test to create must be a string" unless ( line.kind_of? String )

      #
      #  The array we return.
      #
      result = Array.new()


      #
      # If this is an obvious protocol test.
      #
      if ( line =~ /must\s+(not\s+)?run\s+(\S+)(\s+|\.|$)/ )

        test_type = $2.dup
        test_type.chomp!( "." )

        #
        #  For each of the test-classes that implement the type
        #
        @@subclasses[test_type].each do |impl|

          if impl
            obj = impl.new( line )

            #
            # Get the notification text, which is not specific to the test-type
            #
            # We do this only after we've instantiated the test.
            #
            if ( line =~ /\s+otherwise\s+'([^']+)'/ )
              obj.set_notification_text( $1.dup )
            end

            result.push(obj)
          else
            raise ArgumentError, "Bad test type: '#{test_type}'"
          end
        end

        # return the test-types.
        return( result )

      else
        raise "Unknown line given - Failed to instantiate a suitable protocol-test: '#{line}'"
      end
    end


    #
    # Register a new test type - this must be called by our derived classes
    #
    def self.register_test_type name
      @@subclasses[name] ||=  Array.new()
      @@subclasses[name].push(self)
    end


    #
    # Return an array of test-types we know about
    #
    # i.e. Derived classes that have registered themselves.
    #
    #
    def self.known_tests
      @@subclasses
    end


    #
    # Get the friendly-type of this class
    #
    def get_type
      # get each registed type
      @@subclasses.keys.each do |name|

        # for each handler ..
        @@subclasses[name].each do |impl|
          if ( impl == self.class )
            return name
          end
        end
      end
      nil
    end


    #
    # Return the target of this test.
    #
    def target
      @host
    end




    #
    # Return the user-text which is returned on error
    #
    def get_notification_text
      @notification_text
    end




    #
    # Set the user-text which is returned on error.
    #
    def set_notification_text( str )
      @notification_text = str
    end




    #
    #  Is this test inverted?
    #
    def inverted
      @inverted
    end



    #
    #  Return the port of this test.
    #
    def port
      @port
    end




  end

end
