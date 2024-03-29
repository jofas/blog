+++
title = "How to Extract a Collection from a Mongodump Archive"
template = "page.html"
date = 2023-07-28T15:00:00Z
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
Another useful set of developer tools from the MongoDB world are
the [database tools](https://www.mongodb.com/docs/database-tools/).
The MongoDB database tools are a set of cli programs you can use to interact
with your deployment.
In this article I will show you how you can use the data import and export tools, 
namely [`mongodump`](https://www.mongodb.com/docs/database-tools/mongodump/),
[`mongorestore`](https://www.mongodb.com/docs/database-tools/mongorestore/) and 
[`mongoexport`](https://www.mongodb.com/docs/database-tools/mongoexport/), to 
extract a collection from a `mongodump` archive file.

# Why?

Good question.
First though, what is a `mongodump` archive and why do I have a lot of them 
on various hard drives?
`mongodump` is a utility that creates a binary dump of your MongoDB deployment,
no matter whether the deployment is a standalone instance, replica set or 
sharded cluster.
You provide `mongodump` with a connection string to the deployment and it will 
dump every database with every collection in a binary format 
([Bson](https://www.mongodb.com/basics/bson)) to your local disk.
Each collection will be dumped to its own Bson file, along with a Json file
containing metadata about the collection.
Let's say you have a MongoDB server running locally with a single database
called `my_database` containing the collections `my_collection_1` and 
`my_collection_2`.
When running `mongodbump` without any arguments, it will create a sub-directory 
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
This is very helpful for creating backups of our production database.
But `mongodump` can do even better.
Instead of creating a directory, it can also create an archive file, making
the backup more self-contained and space efficient.
Running `mongodump --archive=foo.dump` will create the `foo.dump` archive
with the files from the listing above.
Perfect. My backup strategy for my MongoDB servers.

Why do I need offline access to the data stored in the backups?
In my case I need offline access, because the service storing the data got 
retired and does not exist anymore.
Without an immediate successor system, the data is no longer available online.
The only place the data can be retrieved from are the backup archives.
Even though the service got retired, the data still needs to be accessible 
for various (manual) operations beyond the original reason for collection.
This includes operations like user support, analytics, regulatory ones 
([right of access](https://gdpr-info.eu/art-15-gdpr/)) and maybe one day 
migration to a new system.
The backups themselves are stored in a binary format.
Their only purpose is to be machine-interpretable in order to restore the
contents to a MongoDB deployment.
But to fulfill the ongoing business needs, the data must be accessed by people 
and therefore needs to be human-readable.
So we need to extract it from the archive somehow.

{% admonition(type="note") %}

Before retiring the service I thought long and hard about how I intent to 
retain access to the data offline.
I did not delete the service only to realize later that I lost necessary business 
information, scrambling to restore it, coming up with the solution 
presented here.
Instead of the obvious other way of getting offline access through an extra dump 
of the data in a human-readable format like Json or CSV, I thought that I 
must be able to get the data from the backups instead.
I deemed retrieving the data from the backups preferable, mainly for two 
reasons:

* *Replication:* Backups were made daily and twice a week the backup device was 
  changed.
  Every hard drive not currently connected to the server is stored in a secure 
  location off-site. 
  Before shutting down the service completely, there was a grace period where 
  write access was revoked and people could only read the existing data.
  During that grace period the final, immutable state of the data was replicated 
  onto every backup hard drive.
  Getting the same replication for an extra dump seemed like a lot of unnecessary
  manual work, requiring me to get every hard drive, drive to my server's 
  location and one by one plug them in and copy the final dump to every drive.
  Another possibility would've been to change the backup routine to dump 
  human-readable data and let it run for another three weeks to populate every 
  device with at least one copy of the data.
  But that would've meant unnecessarily paying for the hosting of a useless 
  shell of a service.
 
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
spinning up a local MongoDB instance.
In my mind this sounded like too much overhead for such a benign task. 
But it turns out my use-case described above is less common than anticipated.
I thought that I must be able to use `mongodump` itself or at least its 
counterpart `mongorestore` to query the data from an archive file and print the 
documents in a human-readable format to a file or stdout.
Looking through the documentation quickly revealed that this is not the case.
The MongoDB database tools are split between binary and text import/export 
tools.
On the binary side you have `mongodump` and `mongorestore` with the equivalent 
tools `mongoexport` and `mongoimport` for working with the text formats Json,
CSV and TSV.
Even though it turns out that we can't use only the binary tools to retrieve the 
data from an archive in text format, condemning such a clean and consistent 
design would be preposterous.

There is a third CLI tool for working with binary data dumps in the MongoDB 
database tools, `bsondump`.
`bsondump` is able to convert Bson files to Json, which sounds very much like 
what we are looking for.
Unfortunately `bsondump` is only able to work with uncompressed Bson files.
We don't have these, as we are writing our dumps to an archive instead of the
file system directly.
`bsondump` is not able to work with the archives, a feature exclusive to 
`mongodump` and `mongorestore`.
Last thing I checked was whether it is possible to extract the files from the
archive using an available decompression program.
It is not an uncommon pattern to base domain-specific archive formats on 
general-purpose formats like Tar or Zip.
For example, [`cargo package`](https://doc.rust-lang.org/cargo/commands/cargo-package.html)
creates simple Tarballs from Cargo packages while Java's `.jar` files are
just Zip archives with a metadata file in a specific location within the 
archive.
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
more than a simple and idempotent Bash script, thanks to Docker and the 
[`mongo`](https://hub.docker.com/_/mongo) image.
The necessary steps are:

1. Create a container from the `mongo` image
2. Copy the archive file to the container 
3. Restore it to the MongoDB instance running inside the container
4. Export the collection we want to extract to a file 
5. Copy the file from the container to the local machine
6. Delete the container again 

*Et voilà*, we extracted a collection from our binary archive into a 
human-readable format.
Without further ado, here is the Bash script:

```bash
#!/bin/bash

# CLI arguments 
ARCHIVE=$1
DB=$2
COLLECTION=$3
OUT=$4

# spin up container
docker run -d --name mongodump_to_json mongo:latest

# copy archive into container
docker cp $ARCHIVE mongodump_to_json:archive.dump

# extract archive
docker exec -t mongodump_to_json mongorestore --archive=archive.dump

# export collection to json file
docker exec -t mongodump_to_json mongoexport --pretty --db=$DB --collection=$COLLECTION -o=$OUT
docker cp mongodump_to_json:$OUT $OUT

# gracefully shut down container again
docker stop mongodump_to_json
docker rm mongodump_to_json
```

All we need to do is provide four arguments to the script.
The path to the archive file we want to use, which collection from which 
database we want to retrieve and finally where to store the extracted data.
If we wanted to retrieve `my_collection_2` from the `foo.dump` archive from the 
example above, we'd call the script like this:

```bash
sh mongodump_to_json.sh foo.dump my_database my_collection_2 my_collection_2.json
```

This command creates a `my_collection_2.json` file in the current work directory 
on the host machine with the documents of `my_collection_2` formatted as a 
Json array.
Human-readable and actionable, ready to be put to use.

While I was hoping to accomplish extracting a collection from a `mongodump` 
archive file without first recreating the collection in a local MongoDB instance
before downloading it again in a different format, it turned out that the 
database tools were not meant for that.
`bsondump` exists, but it is unable to work with archive files, only with
standalone Bson files.
But thanks to Docker and the `mongo` container, it is not necessary to create
a complex local MongoDB installation.
Just a simple, self-contained and most importantly idempotent Bash script that
only calls various Docker commands under the hood is needed to do the job and 
I'm happy with the solution.

{% admonition(type="note") %}

The script creates a container from the latest version of the `mongo` image.
As of July 2023, if your production system is running MongoDB version 4.0 or 
earlier, you may run into compatibility issues when using the database tools 
installed in the image. 
If that's the case you should use an earlier version of the `mongo` image and
try again.
See i.e. [here](https://www.mongodb.com/docs/database-tools/mongodump/#mongodb-server-compatibility).

{% end %}

# Optional: Slap On a Rudimentary CLI 

To hide the fact that deep down I'm a thoughtless savage, I like to keep up 
the pretense of being a sane and stable person by adding a rudimentary CLI to 
my Bash scripts if they need to be executed with arguments.
I'm not going as far as writing a help or man page (Rust's 
[`clap`](https://docs.rs/clap/latest/clap/) has ruined CLI programming for me 
with its incredible API for creating interfaces with zero effort). 
But being able to provide named arguments whose existence is checked before 
anything weird can happen, or providing sensible default values for optional 
arguments gives me a better feeling about the whole script.
Here's the final version of the script I use, with the logic abstracted into a 
function and a crude little CLI added on top: 

```bash
#!/bin/bash

mongodump_to_json() {
  ARCHIVE=$1
  DB=$2
  COLLECTION=$3
  OUT=$4

  # spin up container
  docker run -d --name mongodump_to_json mongo:latest

  # copy archive into container
  docker cp $ARCHIVE mongodump_to_json:archive.dump

  # extract archive
  docker exec -t mongodump_to_json mongorestore --archive=archive.dump

  # export collection to json file
  docker exec -t mongodump_to_json mongoexport --pretty --db=$DB --collection=$COLLECTION -o=$OUT
  docker cp mongodump_to_json:$OUT $OUT

  # gracefully shut down container again
  docker stop mongodump_to_json
  docker rm mongodump_to_json
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--archive)
      ARCHIVE=$2
      shift
      shift
      ;;
    --db)
      DB=$2
      shift
      shift
      ;;
    --collection)
      COLLECTION=$2
      shift
      shift
      ;;
    -o|--out)
      OUT=$2
      shift
      shift
      ;;
    *)
      echo "UNKNOWN ARGUMENT: $1"
      exit 1
  esac
done

# required arguments

if [ -z ${ARCHIVE+x} ]; then
  echo "MISSING ARGUMENT: -a/--archive"
  exit 1
fi

if [ -z ${DB+x} ]; then
  echo "MISSING ARGUMENT: --db"
  exit 1
fi

if [ -z ${COLLECTION+x} ]; then
  echo "MISSING ARGUMENT: --collection"
  exit 1
fi

# optional arguments

if [ -z ${OUT+x} ]; then
  OUT="$DB-$COLLECTION.json"
fi

mongodump_to_json $ARCHIVE $DB $COLLECTION $OUT
```

The interface is now more flexible and harder to misuse.
Executing the script looks a lot nicer and less random than before as well:

```bash
sh mongodump_to_json.sh -a foo.dump --db my_database --collection my_collection_2 -o my_collection_2.json
``` 

Not a proper CLI ready for major distribution, but good enough for myself.
