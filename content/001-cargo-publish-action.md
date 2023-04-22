+++
title = "Publishing your Crates to Crates.io with GitHub Actions"
template = "page.html"
date = 2023-04-21T15:00:00Z
[taxonomies]
tags = ["devops", "rust", "software", "cargo"]
[extra]
summary = "Automatically publish your crates when you push a tag to your repository that looks like a SemVer version"
+++

<div style="text-align: center">

[![Automation](https://imgs.xkcd.com/comics/automation.png)](https://xkcd.com/1319/) 

*I also think that if the task is not time-consuming at all*

</div>

I wouldn't be able to call myself a DevOps Engineer[^1] if I wouldn't automate even
the silliest and most banal of tasks.
Not even when I know that I will spend considerably more time writing the
code than it will ever save me.
In this post, we will have a look at how much[^2] effort it takes to automate 
publishing your Rust crate to crates.io.
Publishing your crate is one of the most complex deployments out there. 
On par with publishing your app in the Apple App Store or updating your
Kubernetes deployment across availability zones, I'd say.
It requires you to run this command:

```bash
> cargo publish 
```

I know, I know. It's all very scary looking. 
You can easily screw it up when you type or make a mistake when 
copy-pasting it. 
You'll always have to look it up, forgetting it the instance it finished 
executing.
It consists of a whopping two words containing a grand total of twelve 
characters. 
Twelve characters! 
Who in the world has the mental capacity to remember such a lengthy and
completely convoluted command?

All jokes and irony aside, I am a firm believer that every software project 
should have a sound CI/CD setup.
And I think that this setup should contain the seemingly trivial tasks, even 
when the automation looks a lot more complex than the task itself.
A late adopter of the CD (continuous deployment) part of CI/CD, I learned that
there is more to a release than meets the eye.
Even with seemingly simple deployments like a crate or binary distributed via 
Cargo.
I started automating crate publishing inside my CI/CD pipeline, because it is 
coupled to a second command.
Namely creating and pushing a Git [tag](https://git-scm.com/book/en/v2/Git-Basics-Tagging) 
with the current version number of my crate to my repository.
Say I just committed the last change of the next release of my crate (`v0.2.1`
for example), I would run the following commands:

```bash
> cargo publish
> git tag -a v0.2.1 -m "v0.2.1"
> git push --tags
```

Keeping a reference within Git to the state my crate was in when I published it 
allows me and others to easily revisit the source code of the published version 
later.
This can come in handy for backporting bug fixes, for example.
Having a easily accessible tag for reference is a lot simpler than having to
look through potentially thousands of commits to find the one that contains the
exact code of the published package.
It enables me to navigate quickly and conveniently between different released 
versions of my crate with my favorite source control system (or GitHub's web 
UI).
Having a tag denoting the commit containing the published version of your 
library or package is all pretty standard and common procedure, I'd say.

**TODO:** here add some context 

<sub>
These commands and the whole procedure are ingrained in my head and I only 
recall forgetting to push the tag once in the hundreds of times I executed 
these exact commands listed above.
Still, for a notorious over-thinker and perfectionist like me the thought 
of forgetting to create and push the tag after publishing my crate weighs heavy 
on my heart. 
Thinking about leaving my repository in such a subtly inconsistent state makes me 
shiver.
Luckily there are other neurotic people out there that came up with the idea
of CI/CD and convenient and powerful tools like GitHub Actions.
</sub>

* now describe why this coupling may fail (forgetting to tag commit)
* integration into a bigger release-setup

In this post I'll give a step-by-step tutorial on how to set up a GitHub Action
that publishes your crate to [crates.io](https://crates.io) when you push a
tag to your GitHub repository that looks like a [SemVer](https://semver.org/) 
version (without extensions).
This tutorial expects you to have a basic knowledge of 
[GitHub Actions](https://docs.github.com/en/actions) and a GitHub repository 
containing a crate you wish to publish to crates.io, of course.
Except the first part (where we get an access token from crates.io which we 
store as a secret in our repository), this tutorial extends to publishing a 
crate to [registries](https://doc.rust-lang.org/cargo/reference/registries.html) 
other than crates.io as well.

[^1]: I don't call me that, but I enjoy dabbling with modern concepts of DevOps
  like CI/CD, artifact registries, containerisation, Kubernetes and cloud 
  computing. 
  I also love writing my own CLI programs and scripts to make Ops as easy and 
  convenient for me as possible.

[^2]: Actually rather little effort is needed.
