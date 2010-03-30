Couchdb-Wiki
===========

A [Sinatra][1] application providing a very basic wiki which stores its documents in [CouchDB][2].
It supports separating pages into Spaces, tagging pages and the [Markdown][3] format.

Spaces are a way to divide pages into separate namespaces. Spaces are not stored as separate
documents but generated from existing document declarations.

To create a document, attempt to navigate to it through the input field or the address bar or link
to it.


Getting Started
---------------

- Configure the config.yml file with the name of the CouchDB *database*.
- Ensure the database is created in your CouchDB instance.
- Add the view design documents to CouchDB found in the *couchdb_design_docs.json* file.
- Start the Sinatra server in any Rack-supporting environment and navigate to the home page
  (eg. http://localhost:4567/)


Required Gems
-------------

- Sinatra
- CouchRest
- JSON
- Maruku


LICENSE
-------

Couchdb-Wiki is Copyright (c) 2010 Ashley Richardson and distributed under the MIT license. See the
COPYING file for more info.


[1]: http://www.sinatrarb.com/
[2]: http://couchdb.apache.org
[3]: http://daringfireball.net/projects/markdown/
