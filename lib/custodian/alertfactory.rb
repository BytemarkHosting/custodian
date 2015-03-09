

#
#
# Base class for custodian notifiers.
#
# Each subclass will register themselves, via the call to 'register_alert_type'.
#
# This class is a factory that will return the correct derived class.
#
#
module Custodian

  class AlertFactory

    #
    # The target for the alert.
    #
    # The meaning of the target is notifier-specific.
    #
    # In the case of the smtp-notifier the target is the
    # email address to notify, for example.
    #
    attr_reader :target


    #
    # The global configuration settings object.
    #
    attr_reader :settings



    #
    # The subclasses we have.
    #
    @@subclasses = { }



    #
    # Create an notifier object, based upon name given to us.
    #
    # The "obj" here is the test-case that will be generating the
    # raise/clear event.
    #
    def self.create( alert_type, obj )

      raise ArgumentError, 'The type of notifier to create cannot be nil' if  alert_type.nil? 
      raise ArgumentError, 'The type of notifier to create must be a string' unless  alert_type.kind_of? String 

      c = @@subclasses[alert_type]
      if c
        c.new( obj )
      else
        raise ArgumentError, "Bad alert type: '#{alert_type}'"
      end
    end


    #
    # Register a new type of notifier - this must be called by our derived classes
    #
    def self.register_alert_type name
      @@subclasses[name] = self
    end


    #
    # Return the notifiers we know about.
    #
    # i.e. Derived classes that have registered themselves.
    #
    def self.known_alerters
      @@subclasses
    end


    #
    # Get the friendly-type of derived-classes.
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



    #
    # Store a reference to the settings
    #
    def set_settings( obj )
      @settings = obj
    end



    #
    # Raise an alert.
    #
    def raise
      puts 'NOP'
    end



    #
    # Clear an alert.
    #
    def clear
      puts 'NOP'
    end


  end

end
