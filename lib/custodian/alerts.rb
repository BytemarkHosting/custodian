#
# This is just a helper which means that you'll only need to
# update the list of requires in one place if you add a new
# alert-type.
#


#
# The factory
#
require 'custodian/alertfactory'


#
# The individual alert-types.
#
require 'custodian/alerts/file'
require 'custodian/alerts/graphite'
require 'custodian/alerts/mauve'
require 'custodian/alerts/redis-state'
require 'custodian/alerts/smtp'


