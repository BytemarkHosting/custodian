
require 'singleton'


#
# A class which encapsulates some global-settings which are read from the
# global configuration file.
#
# The configuration file is optional, and we have defaults for every value.
#
# This class is a singleton to avoid having to re-parse the configuration file more than
# once per program-launch.
#
module Custodian

  class Settings

   include Singleton


    #
    # The parsed key=values store
    #
    attr_reader :settings


    #
    # Holder to mark whether we've loaded our file.
    #
    attr_reader :parsed




    #
    # Load the configuration file; called only once.
    #
    def _load( file = "/etc/custodian/custodian.cfg" )

      @parsed   = true
      @settings = Hash.new()

      #
      # The global configuration file.
      #
      return unless( File.exists?( file ) )

      #
      # Load and "parse" the key=value content.
      #
      File.open( file, "r").each_line do |line|
        next if ( line.nil? || line =~ /^#/ )
        if ( line =~ /^(.*)=(.*)$/ )
          key = $1.dup
          val = $2.dup
          key.strip!
          val.strip!
          @settings[key] = val
        end
      end
    end


    #
    #  Privately set the value for a named key.
    #
    #  Used by the test-suite.
    #
    def _store( key, val )
      @settings[key] = val
      @parsed = true
    end


    #
    # Have we loaded our data?
    #
    def _loaded?
      @parsed
    end


    #
    # Retrieve an arbitrary key
    #
    def key( name )
      _load() unless( _loaded? )
      @settings[name]
    end


    #
    # The timeout period for each individual test.
    #
    def timeout
      _load() unless( _loaded? )

      if ( @settings['timeout'] )
        @settings['timeout'].to_i
      else
        30
      end
    end



    #
    # The number of times to re-execute a failing test
    # before raising an alert.
    #
    def retries
      _load() unless( _loaded? )

      if ( @settings['retries'] )
        @settings['retries'].to_i
      else
        5
      end
    end


    #
    # When a test fails we repeat it up to five times.
    #
    # (The retries() method will return the number of repeats, but we default to five.)
    #
    # Here we configure a delay between those repeats.
    #
    # A delay of zero is permissable.
    #
    def retry_delay
      _load() unless( _loaded? )

      if ( @settings['retry_delay'] )
        @settings['retry_delay'].to_i
      else
        0
      end
    end


    #
    # The address of the queue.
    #
    def queue_server
      _load() unless( _loaded? )

      @settings['queue_server'] || "127.0.0.1:11300"
    end



    #
    # The filename for the logfile.
    #
    def log_file
      _load() unless( _loaded? )

      @settings['log_file'] || "custodian-dequeue.log"
    end


    #
    # The alerter to use
    #
    def alerter
      _load() unless( _loaded? )

      @settings['alerter'] || "file"
    end


    #
    # The alert-source we send.  Only used when the notifier is set to mauve.
    #
    def alert_source
      _load() unless( _loaded? )

      @settings['alert_source'] || "Custodian"
    end


    #
    # The target for the alert.
    #
    # When the alerter is "smtp" the target is the mail address.
    #
    # When the alerter is "file" the target is the logfile.
    #
    # When the alerter is "mauve" the target is the destination for the alerts.
    #
    # When the alerter is "redis" the target is the redis-server address.
    #
    def alerter_target( alert )
      _load() unless( _loaded? )


      #
      # Find the alerting method.
      #
      # if we have something setup then use it.
      if ( @settings["#{alert}_target"] )
        return( @settings["#{alert}_target"] )
      end

      # otherwise per-test defaults.
      case alert
        when "smtp"
          "root"
        when "mauve"
          "alert.bytemark.co.uk"
        when "file"
          "alerts.log"
        when "redis"
          "127.0.0.1:6379"
        else
          nil
      end
    end


  end
end
