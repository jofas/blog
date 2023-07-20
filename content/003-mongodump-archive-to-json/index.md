+++
title = "Extract Collection as Json from a Mongodump Archive"
template = "page.html"
date = 2023-07-20T15:00:00Z
authors = ["Jonas Fassbender"]
[taxonomies]
tags = ["devops", "mongodb"]
[extra]
summary = "If you need to look up data from your backups"
+++

Since I started using MongoDB in two years ago as my database of choice
when building web services, it has been a pleasure.
Everything has been easy and there was never a fuzz.
The [Rust client](https://crates.io/crates/mongodb) is amazing and building 
RESTful web services in Rust with MongoDB for persistent storage has taken me a 
long way.
Only for full-text search I had to bring in a database that is more
advanced in that regard (Elasticsearch).
Besides the great integration into the Rust ecosystem, another positive aspect 
is the tooling and scripting capabilities.
The [`mongosh`](https://www.mongodb.com/docs/mongodb-shell/) REPL for 
JavaScript is a versatile tool making database administration, document changes
and data retrieval for one-off jobs and analytics tasks a breeze.
But this post is about a different set of developer tools from the MongoDB world,
the [database tools](https://www.mongodb.com/docs/database-tools/).
The MongoDB database tools are a set of cli programs you can use to interact
with your deployment.
We will use the data import and export tools, namely `mongodump`,
`mongorestore` and `mongoexport` to extract a collection from a `mongodump` 
archive file as Json.

# But Why?

TODO: what is a `mongodump` archive and why do I have it (mention that this
backup strategy might not scale but is good enough for the scale I operate at)

TODO: inspect backup 

TODO: why offline? (in my case because the service got retired, but might be
useful for analytics)

# Required Steps

TODO: describe setup

TODO: describe my thought process (restore -> export to `bsondump` and back)

# Docker and Bash to the Rescue

TODO: script

# Optional: Enhance Script with a CLI 

TODO: optional CLI
