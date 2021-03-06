# fresh\_redis

Redis is great for managing data that expires on atomically (like caches). However, for data that expires gradually over time, built in commands don't get you all the way. 

For instance, how would you calculate _"count of login failures and successes for the last hour"_? The problem is while you can keep a count using a simple `incr` operation, you have to expire the entire total all at once, or not at all.

A common solution is to split the data up into buckets, say one for each minute, each with their own expiry. You write to the current bucket, set the expiry, then allow it to naturally expire and drop out of your result set over time. To obtain the total value, you `get` all the bucket values, and aggregate the values in some fashion.

That's pretty much what fresh\_redis does, except with less boilerplate, and a little more flexibility.

## Installation

Add this line to your application's Gemfile:

    gem 'fresh_redis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fresh_redis

## Usage

### Simple counts

Increment a counter, but gradually expire portions of that counter. Useful for *"find count of X for the last Y minutes"* type queries, where some event occurs occasionally over a period of time.

```ruby
require "redis"
require "fresh_redis"
fresh = FreshRedis.new(Redis.current)

fresh.fincr "failed_login"

# wait a bit...
fresh.fincr "failed_login"

# then straight away...
fresh.fincr "failed_login"

fresh.fsum "failed_login" # will return 3

# wait for the first incr to expire...
fresh.fsum "failed_login" # will return 2, cause the first incr has expired by now
```

### Hash operations

fresh_redis Hashes work similarly to existing Redis hashes, except that keys have individual expiry.

```ruby
require "redis"
require "fresh_redis"
fresh = FreshRedis.new(Redis.current)

fresh.fhset "temp_banned_users", "madlep", "too much cowbell"
# wait a bit
fresh.fhset "temp_banned_users", "normthegnome", "inappropriate office conduct"
fresh.fhset "temp_banned_users", "joeblogs", "suspected ninja"

# then straight away...
fresh.fhget "temp_banned_users", "madlep" # will return "threatening..."
fresh.fhget "temp_banned_users", "normthegnone" # will return "inappropriate..."
fresh.fhget "temp_banned_users", "joeblogs", # will return "suspected..."
fresh.fhgetall "temp_banned_users" # will return hash of {"madlep" => ..., "normthegnone" => ..., "joeblogs" => ...}

# wait for first fhset to expire

fresh.fhget "temp_banned_users", "madlep" # will return nil
fresh.fhget "temp_banned_users", "normthegnone" # will return "inappropriate..." - unchanged
fresh.fhget "temp_banned_users", "joeblogs", # will return "suspected..." - unchanged
fresh.fhgetall "temp_banned_users" # will return hash WITHOUT "madlep" as a key (just "normthegnone" and "joeblogs")

```

### Tweaking _"freshness"_ and _"granularity"_. 

Think of it like stock rotation at your local supermarket. Freshness is how long we'll keep food around for before throwing it out, granularity is what batches we'll throw old food out together as. Something like _"we'll keep food around for a week, but we'll throw out everything for the same day at the same time."_ This is a performance trade off. Smaller granularity means more precise expiration of data, at the expense of having to store, retrieve, and check more buckets of data to get the aggregate value.

```ruby
# lets track douch users spamming the forum so we can do something about it...
fresh = FreshRedis.new(Redis.current, :freshness => 600, :granularity => 30)

# store post count for a user for 10 minutes (600 seconds), in buckets of time duration 30 seconds
fresh.fincr "recent_posts:#{user.id}"

# do stuff
fresh.fsum "recent_posts:#{user.id}"
```

# Recipes

## Tracking user signin attempts count over the last hour
TODO

## Tracking dropped requests for the last day
TODO

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Who the hell?
I blame [@madlep](http://twitter.com/madlep) aka Julian Doherty. Send hate mail to [madlep@madlep.com](mailto:madlep@madlep.com), or deface [madlep.com](http://madlep.com) in protest

Thanks to [chendo](https://github.com/chendo) for initial hash operations.
