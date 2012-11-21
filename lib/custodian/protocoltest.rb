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
# file.
#
# TODO: We also wish to create from json.
#
class ProtocolTest


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
      obj = JSON.parse( line );
      line = obj["line"]
    end

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


end

