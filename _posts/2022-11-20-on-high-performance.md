---
layout: post
title:  "On High-Performance API apps"
date:   2022-11-16 07:14:00 +0700
categories: performance
comments: true
published: true
---

In the last week, I do some experiments to compare some performance between stacks. Because I'm interested to see the performance of Golang compared to Ruby language.

I don't have the experience to write production Go so probably my Go code is not performant. 

But that's okay. 

My goal is just to see the different performances in common code. 

I'm using [Gin](https://github.com/gin-gonic/gin) as the Golang framework. For Ruby, I'm using [Rails](https://guides.rubyonrails.org/api_app.html) and [Roda](http://roda.jeremyevans.net/).

The feature that using for the comparison is simple, we have an API to store data in MySQL DB. You can see the detail of the code in [this repository](https://github.com/philiplambok/high-performance-bench).

And the result is really interesting:

![](https://raw.githubusercontent.com/philiplambok/high-performance-bench/main/result.png)

I found Ruby API is slightly better performance compared to Go. The _x-axis_ is the total request that runs, and the _y-axis_ is the time that needs to be done.

I don't wanna say that Ruby language is better than Golang in performance or speed case. Because it's weird if we can go to that conclusion just from this feature comparison. And also, we don't compare the memory consumption between those stacks in this benchmark.

But something that we can get from this experiment is that Ruby is not that slow right?

There is an even case Ruby can be faster than Golang. 

Of course, if [you see](https://github.com/philiplambok/high-performance-bench) Roda is not writing anything logs by default while Gin has logged. So Golang has input/output action to the console while Roda not. 

If we can disable logs in Gin probably performance will be better and faster than Roda's. 

Again, but that's okay.

In the end, I'm interested looking at and experimenting with Roda. It's probably a framework that is worth looking at if you're wanna build a simple API service and care about performance but still wanna write in Ruby language.

But again, using Roda instead of Rails has a trade-off. Roda and Rails use the same programming language, so Rails is slower it's because [Rails has a lot of features](https://guides.rubyonrails.org/api_app.html#why-use-rails-for-json-apis-questionmark). 

Rails also have a big community, big support, and a mature and trusted framework.

That's all for the article, I hope you can enjoy reading my plain text, see you in the next article!
