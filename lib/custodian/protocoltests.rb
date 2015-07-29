#
# This is just a helper which means that you'll only need to
# update the list of requires in one place if you add a new
# test-type.
#
#



#
# The individual protocol tests.
#
require 'custodian/protocoltest/tcp'
require 'custodian/protocoltest/dns'
require 'custodian/protocoltest/dnsbl'
require 'custodian/protocoltest/ftp'
require 'custodian/protocoltest/http'
require 'custodian/protocoltest/imap'
require 'custodian/protocoltest/mx'
require 'custodian/protocoltest/jabber'
require 'custodian/protocoltest/ldap'
require 'custodian/protocoltest/mysql'
require 'custodian/protocoltest/ping'
require 'custodian/protocoltest/pop3'
require 'custodian/protocoltest/postgresql'
require 'custodian/protocoltest/rdp'
require 'custodian/protocoltest/redis'
require 'custodian/protocoltest/rsync'
require 'custodian/protocoltest/openproxy'
require 'custodian/protocoltest/ssh'
require 'custodian/protocoltest/ssl'
require 'custodian/protocoltest/smtp'
require 'custodian/protocoltest/telnet'


#
# The factory
#
require 'custodian/testfactory'
