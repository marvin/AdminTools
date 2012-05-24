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

Configure those two line in admintools.rb for your needs

	MongoMapper.connection = Mongo::Connection.new('localhost',27017, :pool_size => 5, :timeout => 5)
	MongoMapper.database = 'admintools'

Line 102 in admintools.rb change username/password for admin

	  username == 'admin' && password == 'secret'


Start
-----

	ruby admintools.rb

Login
-----

Login to
	
	http://localhost:4567	