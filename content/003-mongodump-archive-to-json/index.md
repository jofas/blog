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

I was hoping to be able to extract the data from the archive file without
having to spin up a local MongoDB instance, which in my mind sounded like too
much overhead for such a benign task. 
But it turns out my use-case described above is less common than anticipated.
The process of extracting documents from an archive created with `mongodump` 
requires more tools and resources than I initially expected.
I thought that I must be able to use `mongodump` itself or at least its 
counterpart `mongorestore` to query the data from an archive file and print the 
documents in a human-readable format to a file or stdout.
Looking through the documentation quickly revealed that this is not the case.
The MongoDB database tools are split between binary and text import/export 
tools.
On the binary side you have `mongodump` and `mongorestore` with the equivalent 
tools `mongoexport` and `mongoimport` for working with the text formats Json,
CSV and TSV.
Even though it turned out that I can't use only the binary tools to retrieve the 
data from an archive in text format, I can't argue with such a clean and 
consistent design.

There is a third CLI tool for working with binary data dumps in the MongoDB 
database tools, `bsondump`.
`bsondump` is able to convert Bson files to Json, which sounds very much like 
what we are looking for.
Unfortunately `bsondump` is only able to work with uncompressed Bson files,
which we don't have, as we are writing our dumps to an archive instead of the
file system directly.
`bsondump` is not able to work with the archives, a feature exclusive to 
`mongodump` and `mongorestore`.
Last thing I checked was whether it is possible to extract the files from the
archive using an available decompression program.
It is not an uncommon pattern to base domain-specific archives on general-purpose
formats like Tar or Zip.
For example, [`cargo package`](https://doc.rust-lang.org/cargo/commands/cargo-package.html)
creates simple Tarballs from Cargo packages while Java's `.jar` files are
just Zip archives with a metadata file in a specific location.
Unfortunately this is [not true](https://stackoverflow.com/a/56519349/20665825) 
for the archives created by `mongodump`.
So extracting the binary file containing the documents from a collection and
subsequently using `bsondump` to read the file was not possible either.
This means the only way we can extract the data in a human-readable format from
an archive is by starting a MongoDB instance, restoring the archive by running
`mongorestore --archive=foo.dump` and lastly downloading the data again with
`mongoexport`.

# Docker and Bash to the Rescue

What sounded like another overly complex Ops process turned out to be nothing
more than a simple and idempotent bash script, thanks to Docker and the 
[`mongo`](https://hub.docker.com/_/mongo) image.
All that is necessary is (I) to create a container with the `mongo` image,
(II) copy the archive file to the container, (III) restore it to the MongoDB 
instance running locally inside the container, (IV) export the collection
we want to extract to a file, (V) copy the file from the container to the local 
machine, (VI) finally delete the container again *et voilà*, we extracted a 
collection from our binary archive into a human-readable form.
Without further ado, here is the bash script:

TODO: script

TODO: describe arguments shortly

# Optional: Slap On a Rudimentary CLI 

TODO: optional CLI
