+++
title = "Publishing your Crates to crates.io with GitHub Actions"
template = "page.html"
date = 2023-04-21T15:00:00Z
[taxonomies]
tags = ["devops", "rust", "software", "cargo"]
[extra]
summary = "Automatically publish your crates when you push a tag to your repository that looks like a SemVer version"
+++

<div style="text-align: center">

[![Automation](https://imgs.xkcd.com/comics/automation.png)](https://xkcd.com/1319/) 

Figure 1: *I also think that if the task is not time-consuming at all*

</div>

I wouldn't be able to call myself a DevOps Engineer[^1] if I wouldn't automate even
the silliest and most banal of tasks.
Not even when I know that I will spend considerably more time writing the
code (and debugging it!) than it will ever save me.
In this post, we will have a look at how much[^2] effort it takes to automate 
publishing your Rust crate to [crates.io](https://crates.io).

Publishing your crate is one of the most complex deployments out there. 
On par with publishing your app in the Apple App Store or updating your
Kubernetes deployment across availability zones, I'd say.
It requires you to run this command:

```bash
> cargo publish 
```

I know, I know. It's all very scary looking. 
Hard not to screw up.
It requires you to type a whopping two words containing a grand total of twelve 
characters. 
Twelve characters! 
Who in the world has the mental capacity to remember such a lengthy and
completely convoluted command?

All jokes and irony aside, I am a firm believer that every software project 
should have a sound CI/CD setup and I think that this setup should contain the 
seemingly trivial tasks, even when the automation looks a lot more complex than 
the task itself.
A late adopter of the CD (continuous deployment) part of CI/CD, I learned that
there is more to a release than meets the eye, even with seemingly simple 
deployments like a crate distributed via Cargo.
A release always consists of more than just a single command.
There are simple things that need to be done, like tagging the release commit. 
But publishing a crate can also be embedded in a bigger and more 
complex release setup that consists of multiple deployments to different 
registries and other places like package managers or app stores.

The moment you have to execute more than a single instruction to complete a 
task, you enter the land of automation. 
I've messed up releases before. 
So far just annoying little things like forgetting to create the Git tag or 
creating a tag that has the wrong version.
But as a notorious over-thinker and perfectionist, the thought of leaving a 
project in such a subtly inconsistent state makes me shiver.
Luckily there are other neurotic people out there that came up with the idea
of CI/CD and convenient and powerful tools like GitHub Actions.

This post contains a step-by-step tutorial on how to set up a GitHub Action
workflow that publishes your crate to crates.io  when you push a tag that looks 
like a [SemVer](https://semver.org/) version (without extensions).
This tutorial expects you to have a basic knowledge of 
[GitHub Actions](https://docs.github.com/en/actions), a GitHub repository with
a crate you wish to publish and an account on crates.io.
Except the first part (where we get an API token from crates.io), this 
tutorial extends to publishing a crate to 
[registries](https://doc.rust-lang.org/cargo/reference/registries.html) other 
than crates.io as well.

# 1. Get an API Token from crates.io

<div style="text-align: center">

![crates.io: navigate to API tokens](/images/crates_io_1.jpg)

Figure 2: *How to navigate to* 
[`https://crates.io/settings/tokens`](https://crates.io/settings/tokens) 
*from within the webapp*

</div>

First, we need to authenticate ourselves with crates.io.
The registry needs to know who we are and if we in fact have the right to 
publish our crate.
For this, crates.io offers API tokens.
You can generate a new API token in the web UI.
To do that, make sure you are signed into crates.io in your browser (I registered with 
crates.io with my GitHub account which makes SSO nice and easy).
Once you are signed in, navigate to [`https://crates.io/settings/tokens`](https://crates.io/settings/tokens).
In the web UI you have a drop-down menu in the upper right corner, next to your 
avatar and username. 
It contains an entry "Account Settings". 
The account settings contain the page "API Tokens" where we can manage our
tokens. 

<div style="text-align: center">

![crates.io: create new API token](/images/crates_io_2.jpg)

Figure 3: *Create a new API token*

</div>

There's a button on the API tokens page that says "New Token".
Click on it.
A new text field will open below.
Type in the name you want to associate with the new token.
I normally use the crate name, that way I know where I used the token.
This'd make deleting the token after it accidentally got leaked easier.
Once you've typed the token's name, click on the "Create" button next to the
text input.
The token will be displayed below.
Copy the token and don't close the page until you have successfully stored
the token safely (you'll never be able to see the token again after closing the
page!).

# 2. Store the API Token in a GitHub Secret

<div style="text-align: center">

<a name="fig-navigate-to-secret"></a>

![GitHub: navigate to new Action secret](/images/github_secrets_1.jpg)

Figure 4: *How to navigate to* `https://github.com/{user or orga}/{repo}/settings/secrets/actions/new`
*from within the webapp*

</div>

Once we have copied our API token from crates.io to our clipboard, we have to
make it available to our workflow.
The token must stay a secret (otherwise people could publish malicious content
to crates.io using our credentials or [yank](https://doc.rust-lang.org/cargo/reference/publishing.html#cargo-yank) 
our crates).
We can store the token securely on GitHub in an [Action secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets).
You can create a new secret for the repository containing your crate under
`https://github.com/{user or orga}/{repo}/settings/secrets/actions/new`.
You can navigate to the page from your repository.
You can find it under *Settings > Secrets and variables > Actions* (see
Figure [4](#fig-navigate-to-secret)).

<div style="text-align: center">

<a name="fig-create-secret"></a>

![GitHub: create new Action secret](/images/github_secrets_2.jpg)

Figure 5: *Create a new GitHub Action secret*

</div>

The page you'll see is depicted in Figure [5](#fig-create-secret). 
You have two text inputs, one for the name of the secret, one for the secret
itself.
Type in the name of your secret.
I use `CARGO_REGISTRY_TOKEN` for the secret name, as it is the name of the
[environment variable](https://doc.rust-lang.org/cargo/reference/config.html#registrytoken) 
Cargo uses to look up the token during publishing.
We'll use the secret name explicitly in our workflow, mapping it to the 
environment variable, so you can name the secret however you like.
Paste the secret from the clipboard into the second text input labeled 
"Secret".
Click on the "Add secret" button below to create the secret.

#### Using the GitHub CLI to Create the Secret

Instead of using GitHub's web UI, you can also use [GitHub CLI](https://cli.github.com/),
which you may find more convenient.
Open your console and navigate to your repository.
Inside your repository, run the following command to create the secret:

```bash
gh secret set CARGO_REGISTRY_TOKEN -b "$TOKEN"
```

`$TOKEN` is your API token from crates.io. 
On Linux with X11, you can insert the token from your clipboard easily with:

```bash
gh secret set CARGO_REGISTRY_TOKEN -b "$(xclip -o)"
```

You can find the documentation for the `gh secret set` command 
[here](https://cli.github.com/manual/gh_secret_set).

# 3. Write the Workflow

Now that we have our API token in place, we can finally get to the fun part:
writing the actual workflow.

% TODO: located under `.github/workflows`

% TODO: basic setup `name, on`

% TODO: job: checkout repo

% TODO: job: publish

#### Permissions for Private Repositories

# 4. Optional: Comparing Cargo.toml Version with Tag 

# 5. Optional: Speed up Workflow with Caching

# 6. Final Workflow

[^1]: I don't call me that, but I enjoy dabbling with modern concepts of DevOps
  like CI/CD, artifact registries, containerisation, Kubernetes and cloud 
  computing. 
  I also love writing my own CLI programs and scripts to make Ops as easy and 
  convenient for me as possible.

[^2]: Actually rather little effort is needed.
