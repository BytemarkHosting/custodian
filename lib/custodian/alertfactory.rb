

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



    def raise
      raise NoMethod, "This should be implemented in a derived class"
    end



    def clear
      raise NoMethod, "This should be implemented in a derived class"
    end
  end

end
