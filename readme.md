
# houCe - the 100% CoffeeScript web framework

houCe is client oriented web framework designed with conventions that help you get ready and going in seconds, while providing structure that supports complex desktop like applications. houCe uses one language for everything it does, and that language is [CoffeeScript](http://coffeescript.org/). Here's the list of technologies that make it possible:

* Server: [Node.js](http://nodejs.org/), with [Express.js](http://expressjs.com/).
* Templates: [CoffeeKup](http://coffeekup.org/).
* Stylesheets: [CCSS](https://github.com/aeosynth/ccss), for unenchanted [LESS](http://lesscss.org/) as backup.


## features

* Start coding your app right away, no configuration required.
* Automatic localStorage caching of the application state and data.
* Clean Ajax deferring for retrieving data from external API's and storing that data locally.
* Connect to OAuth2 enabled API's (Facebook, Google, etc.) instantly.
* Clean, but flexible folder structure:
 * **client**: Client side code, templates and stylesheets.
 * **common**: Common code that get executed both on client and server.
 * **server**: Server code and configuration files.
 * **public**: Compiled client code, JS libraries and images.


## get started

If you don't have Node.js installed, [get it here](http://nodejs.org/#download). You'll also need [git](http://git-scm.com/).

    mkdir name_of_your_project
    cd name_of_your_project
    git init
    git pull git://github.com/jussiry/houCe.git
    npm install -g coffee-script node-dev
    nmp install
    node-dev start.coffee
    Open [http://localhost:3001/](http://localhost:3001/) in your browser.


## commands

* `coffee start.coffee production` - Start server in production mode
* `cake build_docs` - Build documentation
* `cake build_client` - Compile client files to public folder (CS and LESS to JS and CSS). Normally done automatically.


## documentation

File by file documentation can be [found here](http://jussiry.github.com/houCe/index.html).


## update to new version of houCe

    cake update_houce

Be **warned**: you'll need to merge all the changes you've done to the original houCe files, which might not be pretty. In the future versions I'll try to make houCe more like a library that's completeley separated from the project code.