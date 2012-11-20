

#
# Interface for our queue.
#
# We'll use this rather than the beanstalk-client
#
class Queue

   #
   # Constructor
   #
   def initialize( server )
   end

   #
   # Put an object.
   #
   # The object is serialized via JSON
   #
   def put( object )
   end

   #
   # Retrieve a native object from the Queue.
   #
   # The object is deserialized using JSON.
   #
   # This method will not return until there is an object present.
   #
   def fetch
   end

end
