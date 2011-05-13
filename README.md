# Cruller

Cruller is a gem for nicely dealing with [CoffeeScript](http://coffeescript.org) files in a 
Sinatra app that you might want to deploy on a production system, and thus
don't want CoffeeScript compiling all the time, or your evil sysadmin might
not want to install Node (no idea why!).

It deals best in the following situation:

- In development, all requests are being handled directly by Sinatra including
  static files
- In production, some requests (e.g. for /public/ files) are handled by
  the web server in front of Sinatra.

In this ideal situation it will nicely compile cached copies for you in
development, but be bypassed in production.

## Usage

First, you'll need to **configure Cruller** (unless you are happy with it's defaults):

    Cruller.configure {:source => "path/to/coffeescripts",
                       :destination => "path/to/javascript/output",
                       :compile => "auto"}

Cruller takes 3 parameters:

 - `source`: the location where your CoffeeScript files are located.
 - `destination`: where you want the compiled Javascript to be written to. Any
   existing Javascript files will be served from here too.
 - `compile`: Whether you want to **always** compile CoffeeScript when a request
   is made, **auto**matically compile it based on modified time, or **never**
   compile the CoffeeScript and only ever serve cached files.

Now, you can brew CoffeeScript! The command is simple:

    Cruller.brew("name_of_js")

It doesn't matter if the name has .coffee or .js in it. Cruller will strip that
away. The command returns either the string of CoffeeScript, or `false` if 
Cruller couldn't find anything to brew or return to you.

## Example usage

In a Sinatra app you might do something like this:

    configure do
      Cruller.configure({:source => "views/coffeescripts",
                         :destination => "public/javascripts"})
    end
    
    get '/javascripts/:name.js' do
      result = Cruller.brew(params[:name])
      pass if !result
      result
    end

## Contributing to Cruller
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 David Somers. See LICENSE.txt for
further details.

