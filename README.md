Admin Tools
===========

AdminTools where build to make my day more easy.

TODO
----

* finish documentation
* finish file transfer to mx and relay servers
* include some other tools I was thinking of
* include the syslog server which isnt part of the frontend atm

Installation
-----------

	git clone git@github.com:marvin/AdminTools.git

Dependencies 
-----------

	gem install sinatra mongo_mapper data_mapper dm-sqlite-adapter whois haml 

If you don't want any Documentation add 
	
	--no-rdoc --no-ri

Configuration
-------------

Configure those two line in admintools.rb and in logserver.rb for your needs
Make sure the database is the same as the logviewer in admintools will read that data from logserver.rb

	MongoMapper.connection = Mongo::Connection.new('localhost',27017, :pool_size => 5, :timeout => 5)
	MongoMapper.database = 'admintools'

Line 102 in admintools.rb change username/password for admin

	  username == 'admin' && password == 'secret'

In logserver.rb line 109 you can change the default udp port

	server = UDPServer.new(514)

Start
-----

### start webinterface

	ruby admintools.rb

### start the logserver

	ruby logserver.rb 

Login
-----

Login to
	
	http://localhost:4567	

Logserver
--------

To receive data in the logserver you need to configure your syslog system within your OS.

In arch linux this is by default syslog-ng. So just add at the end of your syslog-ng.conf 
the following lines and make sure you set the right IP. Restart syslog-ng

	destination logserver { udp("127.0.0.1" port(514)); };
	log { source(src); destination(logserver); };

