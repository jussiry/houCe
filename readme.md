
# houCe - the 100% CoffeeScript web framework

houCe is client oriented web framework designed with conventions that help you get ready and going in seconds, while providing structure that supports complex desktop like applications. houCe uses one language for everything it does, and that language is [CoffeeScript](http://coffeescript.org/). Here's the list of technologies that make it possible:

* Server: [Node.js](http://nodejs.org/), with [Express.js](http://expressjs.com/).
* Templates: [CoffeeKup](http://coffeekup.org/).
* Stylesheets: [CCSS](https://github.com/aeosynth/ccss), for unenchanted [LESS](http://lesscss.org/) as backup.


## features

* Clean, but flexible folder structure:
 * **client**: Client side code, templates and stylesheets.
 * **common**: Common code that get executed both on client and server.
 * **server**: Server code and configuration files.
 * **public**: Compiled client code, JS libraries and images.
* Modular templating system that allows you to write HTML, CS and styles of that module in single file.
* Automatic localStorage caching of the application state and data.
* Connect to OAuth2 enabled API's (Facebook, Google, etc.) instantly.
* Clean Ajax deferring for retrieving data from external API's and storing that data locally.


## get started

If you don't have Node.js installed, [get it here](http://nodejs.org/#download). You'll also need [git](http://git-scm.com/).

    mkdir name_of_your_project
    cd name_of_your_project
    git init
    git pull git://github.com/jussiry/houCe.git
    npm install -g coffee-script node-dev
    nmp install
    node-dev start.coffee

Now open [http://localhost:3001/](http://localhost:3001/) in your browser.


## future plans

* Move parts of models in `/common` and implement similar (but better) data stroage to server with [Redis](http://redis.io/) as in client with localCahce?
* Integration with [Backbone.js](http://documentcloud.github.com/backbone/)?


## commands

* `coffee start.coffee production` - Start in production mode.
* `cake update_houce` - Update to new version of houCe. *Warning*: you'll need to merge all the changes you've done to original houCe files. Also removes `intro.page` and `intro_api_access.templ`.
* `cake build_client` - Compile client files to public folder; normally done automatically.
* `cake build_docs` - Build documentation to /public/docs


## documentation

File by file documentation can be [found here](http://jussiry.github.com/houCe/index.html).
