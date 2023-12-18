+++
title = "Sum Types in Dart"
template = "page.html"
date = 2023-12-05T15:00:00Z
authors = ["Jonas Fassbender"]
[taxonomies]
tags = ["dart", "rust"]
[extra]
summary = "Rewrite it in Rust™"
+++

Every developer's journey is unique.
We have different interests. 
Different starting points.
Different reasons.
Different minds.
But there is one thing that unites us all in the struggle.
Each of us continuously faces perilous fights and dangerous altercations, 
always pushing onwards, discovering new problems that need to be solved with 
every step.
(All while being perfectly safe in a well climatised room with a hot beverage 
at hand, of course.)
During these intense battles of mind versus the machines we try to tame and 
bend to our will, we transform.
With every crafted solution, we pick up knowledge, experience, concepts, 
structures and patterns.
Our minds sharpened and sensitised to protect us from the imminent doom that 
faces those that aren't vigilant enough.
(I might be having dark thoughts right now.)
We turn the things we gain into weapons we carry around with us, smirkingly
daring a problem to show up, knowing the lessons we've learned give us the 
power to be victorious again and again.

But like I said, every journey is unique.
Everybody has their own idea of what a good weapon has to look like.
Some people think the crossbow is the ultimate weapon.
Sword fighters only scoff at that.
What happens when a sword fighter is forced to use a crossbow?
Exactly, they will add a bayonet to it and start charging the enemy while 
ululating like a madman.
Well, hopefully not.
They might win the fight, but it won't be pretty.

TODO: you fall in love with one technology => you apply the concepts to other
technologies as well

TODO: my journey (segue to why I need sum types in dart)

TODO: Ergonomics / strong typing of Rust impacting other languages

TODO: what are sum types or tagged unions

TODO: base class

TODO: Enhanced Enums not the same (as notification)

# Privacy of the `value` and `tag` Fields

TODO: discuss library (<https://dart.dev/language/libraries>) private (<https://github.com/dart-lang/sdk/issues/33383>). 

TODO: private vs. public vs. public + meta.protected

TODO: Dart 3 Pattern matching

# Example: [`Option<T>`](https://doc.rust-lang.org/std/option/enum.Option.html)

# Example: [`Result<T, E>`](https://doc.rust-lang.org/std/result/enum.Result.html)

# Example: [`serde_json::Value`](https://docs.rs/serde_json/latest/serde_json/enum.Value.html)
