## Information
CouchDB running in a minimal OpenSUSE Docker Image

Building CouchDB from scratch using Erlang OTP and Fauxton sources. Everything put into a minimal Container image built from an OpenSUSE tumbleweed image

## Run the image

You can run the image via Docker
```
docker run -dit ghcr.io/svenbeisiegel/couchdb:3.3.3-r0-tumbleweed
```
## Configuration

The following can be configured via environment variables

* COUCHDB_USER
* COUCHDB_PASSWORD
* COUCHDB_SECRET
* NODENAME

Any additional configuration can be applied by mounting an ini file into the container.
```
-v /path/to/local.ini:/opt/couchdb/etc/local.d/local.ini
```
