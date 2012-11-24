

#
#
# Base class for custodian alerters.
#
# Each subclass will register themselves, via the call
# to 'register_alert_type'.
#
# This class is a factory that will return the correct
# derived class.
#
#
module Custodian

  class AlertFactory

    #
    # The target for the alert.
    #
    attr_reader :target

    #
    # The subclasses we have.
    #
    @@subclasses = { }


    #
    # Create an alerter object, based upon the type
    #
    def self.create( alert_type, obj )

      c = @@subclasses[alert_type]
      if c
        c.new( obj )
      else
        raise ArgumentError, "Bad alert type: '#{alert_type}'"
      end
    end


    #
    # Register a new test type - this must be called by our derived classes
    #
    def self.register_alert_type name
      @@subclasses[name] = self
    end


    #
    # Return an array of test-types we know about
    #
    # i.e. Derived classes that have registered themselves.
    #
    #
    def self.known_alerters
      @@subclasses
    end


    #
    # Get the friendly-type of this class
    #
    def get_type
      @@subclasses.each do |name,value|
        if ( value == self.class  )
          return name
        end
      end
      nil
    end



    #
    # Set the target for this alert.
    #
    def set_target( target )
      @target = target
    end



    def raise
      puts "NOP"
    end



    def clear
      puts "NOP"
    end


  end

end
