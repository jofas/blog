+++
title = "Poor Man's On-Premise Backups of a Kubernetes Cluster"
template = "page.html"
date = 2023-07-11T15:00:00Z
authors = ["Jonas Fassbender"]
[taxonomies]
tags = ["devops", "k8s"]
[extra]
summary = "My setup for creating local backups of data from a kubernetes cluster"
+++

<div class="text-center">
<object class="block dark:hidden" data="diagram-light.svg" type="image/svg+xml"></object>
<object class="hidden dark:block" data="diagram-dark.svg" type="image/svg+xml"></object>

Figure 1: Diagram of my Backup Routine
</div>

While planning the sunset I realised I'd have to stop the backup cron job running 
on my server.
Because I was kind of proud of my setup and remembered that it took me some time
till I finally automated the whole process adequately and because I knew I 
couldn't just delete the job without immediately forgetting how I did it in the
first place, I decided to sum it all up in this article.

Even though I didn't have a single problem with my backups in over a 
year, looking at the code I couldn't bring myself to publish it like it was.
While technically working, this was all it did. 
The architecture and design was a complete mess.
Configuration was unnecessarily spread across multiple files and processes and
many things could've been handled more elegantly and in a more orthogonal way.

% TODO: configuration baked into the image vs. provided at runtime

% TODO: about the setup but also about the improvements

% TODO: diagram showing what is going on. 

## Links

* https://docs.docker.com/engine/reference/run/#network-host
