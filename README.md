# Custodian

Custodian is a distributed protocol-tester written in portable Ruby,
which can easily scale to covering the needs of a large network.

Here are some quick-links:

* Source:
   * https://gitlab.bytemark.co.uk/open-source/custodian

* Github Mirror:
   * https://github.com/BytemarkHosting/custodian

* Copyright:
   *  Copyright (c) 2012-2016 Bytemark Computer Consulting Ltd

* Bug Tracker:
   * https://github.com/BytemarkHosting/custodian/issues
   * https://gitlab.bytemark.co.uk/open-source/custodian/issues

* Licence:
   *  This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.




## About Custodian

Custodian is a simple, scalable, and reliable protocol-tester that allows
a number of services to be tested across a network.

The core design is based upon a work queue, which is manipulated by two
main tools:

* `custodian-enqueue`
    * A parser that reads a list of hosts and tests to apply.  These tests are broken down into individual jobs, serialized and stored in a central queue.

* `custodian-dequeue`
    * A tool that pulls jobs from the queue, executing them in turn, and raises/clears alerts based upon the result of the test.

Custodian uses class-factories to ensure that protocol tests, and notification
objects, are only loosely tied to the core.  This is done so that custodian
may be extended or adapted more easily to your environment.



## Configuration

The software is configured by the main configuration file located at:

   /etc/custodian/custodian.cfg

This file contains the alerting mechanism to use, the IP:port of the queue
the two scripts mentioned above use, and similar static things.

Each of the available configuration options has a sensible default which
is documented in that same file.


## Dependencies

The software is written in Ruby and has successfully been deployed in
production under:

* Ruby 1.8
* Ruby 1.9.x
* Ruby 2.1.x

The software has not yet been tested upon JRuby, or similar.

Dependencies, beyond ruby, are limited to the following gems:

* For HTTP/HTTPS testing: curb
* For communication with the queue: redis


