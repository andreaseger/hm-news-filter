hm-services
=====

Just a  few little services for the University of Applied Science Munich.
available services:

- a nice search for the news in the bulletin board
- a room search to quickly get a place for your study group
- a current menu of the mensa

Installation
----

Dependencies are managed trough bundler

    $ bundle install

Add a file env.rb to the root dir, for dev an empty one will do(its for stuff like Database settings)

Database
----

hm-news-filter will connect to Redis on localhost on the default port. You can specify an other setup if you set REDIS_URL in your environment, i.e.:

    $ REDIS_URL='redis://:secret@1.2.3.4:9000/3' ruby service.rb

This would connect to host 1.2.3.4 on port 9000, uses database number 3 using the password 'secret'.


Usage
---

Start the server via

    rackup -p4567

and go to

    localhost:4567/


Problems
----

- I absolutly cant figure out witch markup language is used,

Meta
----

Created by Eger Andreas

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png" /></a><br /><span xmlns:dct="http://purl.org/dc/terms/" property="dct:title">hm-news-filter</span> is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License</a>.
