Pebblebed
=========

[![Build Status](https://semaphoreapp.com/api/v1/projects/0e497128541445910ba532d3ea1990799ae4e2a6/28288/badge.png)](https://semaphoreapp.com/projects/1582/branches/28288)

This gem contains a number of tools for ruby that wants to be a good pebble.

Usage
=====

In your Gemfile:

    gem "pebblebed"


Sinatra
=======

Pebblebed provides a lot of its functionality as a Sinatra extension which is useful for Sinatra
apps that need to talk to other pebbles - or to conform to the basic pebble-spec.

In you app:

    require "pebblebed/sinatra"
    
    class MyPebbleV1 < Sinatra::Base
      register Sinatra::Pebblebed

      # Declare the name of this pebble
      i_am :my_pebble

      # Declare which pebbles I need to talk to
      declare_pebbles do 
        service :checkpoint, :version => 1
        service :parlor, :version => 1
      end

      ... your stuff ...

    end

The extension provide a helper method `pebbles` that can be used to talk to the declared pebbles in this 
manner:

    pebbles.checkpoint.get("/identities/me")

If the result is valid json, it is parsed and wrapped as a [DeepStruct](https://github.com/simen/deepstruct) record.
Otherwise it is returned as a string. If an error is returned by the server, the `Pebblebed::HttpError` exception is raised. 
This exception has the fields `status` and `message`.

Other helper methods provided by this extension:

    part(partspec, params = {})                       # Include a part from a kit (See https://github.com/benglerpebbles/kits)
    parts_script_include_tags                         # All script tags required by the kits
    parts_stylesheet_include_tags                     # All stylesheet-tags required by the kits
    current_session                                   # The hash string that identifies the current browser session
    pebbles                                           # Common entrypoint for the Pebblebed::Connector
    current_identity                                  # Returns the a DeepStruct record with the vital data for the current user
    require_identity                                  # Halts with 403 if there is no current user
    require_god                                       # Halts with 403 if the current user is not a god
    require_access_to_path(path)                      # Halts with 403 if the current user is not a member of a checkpoint access group with privileged access to that path
    require_action_allowed(action, uid, options={})   # Halts with 403 if the current user is not allowed by checkpoint to perform this action for that uid. If a response :allowed => "default" (no policy found) is returned from checkpoint, options[:default] => [bool] is evaluated. options[:default] => true will allow the action on 'default'. Bool false will halt by 403. If no options is given, the method will halt 403 on everything but true.
    require_parameters(parameters, *keys)             # Halts with 409 if the at least one of the provided keys is not in the params-hash

### Testing Sinatra APIs

To use the handy (but very, very dirty) helpers for the Pebbles Checkpoint authorization,
you must require `pebblebed/rspec_helper` (this is not included by default in the pebblebed gem)
and include `Pebblebed::RSpecHelper` in your test context:


```ruby
require 'pebblebed/rspec_helper'

describe Something do
  include Pebblebed::RSpecHelper
end
```

You can set the current identity to be either god, a regular logged in user, or a guest user.

If you call either `god!` or `user!`, the sinatra app's
current session defaults to the string 'validsession'.
The current realm defaults to the string 'testrealm'.

You can override default values for :id or :session or :realm,
or add additional identity values on god or user by passing them in:

```ruby
user!(:id => 7, :session => 'abc', :realm => 'area51', :profile => {:a => 'b'})
```

There are two convenience methods that are added to the context:
```ruby
current_identity # => the god or user, or nil if you've called guest!
another_identity # => a non-god user with an id of (current_user.id + 1)
```

```ruby
  context "when god" do
    before(:each) { god! }
    it "has stuff in the test context" do
      current_identity.god # => true
      current_identity.id # => 1

      other_identity.id # => 2
    end
  end
```

Not Sinatra
===========

If you want to talk to pebbles from other ruby projects, you may use the Pebblebed::Connector directly. To set it up:

    Pebblebed.config do
      host "mypebbleapp.org" # The host where all your pebbles are mapped
      service :checkpoint, :version => 1
      service :grove, :version => 1
    end

To create a connector do this:

    pebbles = Pebblebed::Connector.new(optional_session_hash)    

If you need to "be" a specific user when you talk to the pebbles you need a session from checkpoint. You provide this
to your connector when you create it and connector will take care of propagating this information to any pebble you 
talk to. If you don't plan on doing any authorized request you can omit the session hash.

Then you can start making requests:

    pebbles.checkpoint.get("/identities/1")
    pebbles.grove.post("/posts/post:mittap.blogs.blog1", :post => {:document => {:body => "This is my blog post"}})

Uid
===

Objects in the Pebblesphere are identified using Uids which must be unique across the whole pebblesphere. The Uid 
consists of three parts: The klass of the object, the path and the object id. The format is like this:

    klass:path.of.the.object$object_id

## Klass

The `klass` specifies the type of the object. The klass of the object must map to exactly one pebble that has 
the responsibility of maintining that specific klass of objects. Currently Parlor maintains `topic` and `comment`, 
Checkpoint maintains `identity`, `account` and `session`, Grove maintains `post` and Origami maintains `organization`,
`associate` and more. (Presently there is no registry of which klass belongs in which pebble.)

## Path

The three first nodes of the paths have defined uses: 

The first is the `realm` of the object. A realm corresponds 
to one installation of an application and no data is supposed to leak between realms. E.g. checkpoint maintains
a separate list of identities and accounts for each realm, and no identity from one realm is able to log in to another
realm. 

The second node is the `box`. It roughly corresponds to a 'site' or 'location' in your application. It could typically be
a website or subsection of your application. E.g. 'forums', 'blogs', 'workspaces'.

The third noe is `collection` and will typically represent a blog, a forum or other closely related collection of objects.

More nodes may be supported by a pebble where applicable. Only the realm is required.

## Object id

The object id is a pebble-internal identification and is to be treated as an opaque string by all other services except 
for the pebble responsible for maintaining the specific klass. Typically the object_id will be equal to the id of the 
database-record used internally by the pebble to store that specific object.

Some examples:

    trackers:mittap.user1232$1983
    post:dittforslag.suggestions.theme1$332
    topic:playground$post:playground.blogs.blog1$1213  # The object-id can be a full uid. Not presently valid, but TODO

Pebblebed provides a class for processing uids: `Pebblebed::Uid`:

    klass, path, oid = Pebblebed::Uid.parse(an_uid)

It currenty provides no help in building uids, but TODO.

Pebble Clients
==============

When talking to pebbles, Pebblebed provides a generic http client with the common http-methods get, post, put, delete.

    pebbles.grove.get("/posts/post:mittap.blogs.*")
    pebbles.parlor.delete("/comments/comment:playground.forums.1$3423")

There is also a special "virtual" pebble that lets you ask all declared pebbles the same thing:

    pebbles.quorum.get("/ping")

It will return a hash with each pebble as the key and the result as the value. If an error occured the value for that 
pebble is a HttpError object with status and message.

    
For some pebbles Pebblebed may furnish a richer client with helper methods. This is implemented by sticking the 
augmented client in the `/lib/pebblebed/clients` folder and naming the class `Pebblebed::<YourPebbleName>Client`. For
an example of this see `CheckpointClient` which in addition to the common http-methods provides the method `me` which
returns the logged in user and `god?` which checks whether she's a god(dess).

Troubleshooting
===============

When something fails, say you're trying to post to grove using a pebblebed connector, it might be a good idea to try the same thing from command line first:

	curl -XPOST 'http://example.com/api/grove/v1/posts/post.todo:dna.org.a.b' --data '{"session":"session_name","post":{"document": {"body": "Hello Grove!"},"tags": ["welcome", "tutorial"]}}' -H "Content-Type: application/json"
