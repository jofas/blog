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
We will use the data import and export tools, namely 
[`mongodump`](https://www.mongodb.com/docs/database-tools/mongodump/),
[`mongorestore`](https://www.mongodb.com/docs/database-tools/mongorestore/) and 
[`mongoexport`](https://www.mongodb.com/docs/database-tools/mongoexport/) to 
extract a collection from a `mongodump` archive file as Json.

# But Why?

Good question.
But first, what is a `mongodump` archive and why do I have a lot of them lying
around on various hard drives?
`mongodump` is a utility that creates a binary dump of your standalone MongoDB
instance, replica set or shared cluster.
You provide it with a connection string and it will dump every database with 
every collection in a binary format ([`bson`](https://www.mongodb.com/basics/bson)) 
to your local disk.
Each collection will be dumped to its own bson file, along with a json file
containing metadata about the collection.
Let's say you have a MongoDB server running locally with a single database
called `my_database` containing the collections `my_collection_1` and 
`my_collection_2`.
When you run `mongodbump` without any arguments it will create a directory 
`dump/` in your current work directory with the following files:

```
.
├── admin
│   ├── system.version.bson
│   └── system.version.metadata.json
└── my_database
    ├── my_collection_1.bson
    ├── my_collection_1.metadata.json
    ├── my_collection_2.bson
    └── my_collection_2.metadata.json
```

Nice. We have a bunch of files containing the documents of our collections
saved locally on disk.
This is very helpful for creating backups of our production database, but
`mongodump` can do even better.
Instead of creating a directory it can also create an archive instead, making
the backup more self-contained and space efficient.
Running `mongodump --archive=foo.dump` will create the `foo.dump` archive
containing the files from the listing above.
Perfect. My backup strategy for my MongoDB servers.

TODO: mention that this backup strategy might not scale but is good enough for 
the scale I operate at

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
