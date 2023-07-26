+++
title = "Extract a Collection from a Mongodump Archive"
template = "page.html"
date = 2023-07-20T15:00:00Z
authors = ["Jonas Fassbender"]
[taxonomies]
tags = ["devops", "mongodb"]
[extra]
summary = "If you need to look up data from your backups"
+++

Since I started using MongoDB two years ago as my database of choice
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
JavaScript is a versatile tool making database administration, document updates
and data retrieval for one-off jobs and analytics tasks a breeze.
But this post is about a different set of developer tools from the MongoDB world,
the [database tools](https://www.mongodb.com/docs/database-tools/).
The MongoDB database tools are a set of cli programs you can use to interact
with your deployment.
In this article I will show you how you can use the data import and export tools, 
namely [`mongodump`](https://www.mongodb.com/docs/database-tools/mongodump/),
[`mongorestore`](https://www.mongodb.com/docs/database-tools/mongorestore/) and 
[`mongoexport`](https://www.mongodb.com/docs/database-tools/mongoexport/), to 
extract a collection from a `mongodump` archive file.

# But Why?

Good question.
First though, what is a `mongodump` archive and why do I have a lot of them lying
around on various hard drives?
`mongodump` is a utility that creates a binary dump of your standalone MongoDB
instance, replica set or sharded cluster.
You provide it with a connection string and it will dump every database with 
every collection in a binary format ([Bson](https://www.mongodb.com/basics/bson)) 
to your local disk.
Each collection will be dumped to its own Bson file, along with a Json file
containing metadata about the collection.
Let's say you have a MongoDB server running locally with a single database
called `my_database` containing the collections `my_collection_1` and 
`my_collection_2`.
When you run `mongodbump` without any arguments it will create a sub-directory 
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

Okay, I got a bunch of `foo.dump` files now in case I screw up and destroy
the production data and need to restore it to a proper state.
Why do I need offline access?
In my case I need offline access, because the service storing the data got 
retired and does not exist anymore.
Without an immediate successor system, the data is no longer available online.
The only place the data can be retrieved from are the backup archives.
Even though the service got retired, the data still needs to be accessible 
for various operations beyond the original reason for collection.
This includes operations like analytics, regulatory ones 
([right of access](https://gdpr-info.eu/art-15-gdpr/)) and maybe one day 
migration to a new system.
The backups themselves are stored in a binary format.
Their only purpose is to be machine-interpretable in order to restore the
contents to a MongoDB deployment.
But to fulfill the ongoing business needs, the data must be actionable
for people and therefore human-readable.
So we need to extract it from the archive somehow.

{% admonition(type="note") %}

Before retiring the service I thought long and hard about how I intent to 
retain access to the data offline.
I did not delete the service only to realize later that I lost necessary business 
information, scrambling to restore it somehow, coming up with the solution 
presented here.
Instead of the obvious other way of getting offline access through an extra dump 
of the data in a human-readable format like Json or CSV, I thought that I 
must be able to get the data from the backups instead.
I deemed retrieving the data from the backups preferable, mainly for two 
reasons:

* *Replication:* Backups were made daily and twice a week the backup device was 
  changed.
  Every hard drive not connected to the server is stored in a secure location
  off-site. 
  Before shutting down the service completely, there was a grace period where 
  write access was revoked and people could only read the existing data.
  During that grace period the final, immutable state of the data was replicated 
  onto every backup hard drive.
  Getting the same replication for an extra dump seemed like a lot of unnecessary
  manual work. 
  I could've changed the backup routine to dump human-readable data and
  let it run for another three weeks to populate every device with at least one
  copy of the data, but that would've meant unnecessarily paying for the hosting 
  of a useless shell of a service.
 
* *History:*  All the backups together make up a coarsely grained history of 
  the data and the changes that were made to it.
  If it turns out that a document is broken in the final data dump and we need 
  to find the correct version somewhere in the older backups, I'd need to be 
  able to sift through the backups anyway.
  Might as well write the script for it now when I can use it for other
  operations that require offline access and kill two (one being hypothetical) 
  birds with one stone.
  
{% end %}

{% admonition(type="caution") %}

Note that while this backup strategy is good enough for the scale I operate
at, it might not be suitable for your use-case.
`mongodump`and `mongorestore` are not meant to back up larger MongoDB deployments.
While `mongdump` can connect to sharded clusters and create binary data dumps,
it should not be used to create backups, as `mongodump` does not maintain the
atomicity guarantees of transactions across shards.
Read more about it 
[here](https://www.mongodb.com/docs/manual/core/backups/#std-label-backup-with-mongodump).

{% end %}

# Required Steps

TODO: describe setup

TODO: describe my thought process (restore -> export to `bsondump` and back)

# Docker and Bash to the Rescue

TODO: script

# Optional: Slap on a Rudimentary CLI 

TODO: optional CLI
