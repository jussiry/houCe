
# houCe

houCe is client oriented web framework designed with conventions that help you get ready and going in seconds, while providing structure that supports complex desktop like applications. houCe aspires to use one language for everything it does, and that language is [CoffeeScript](http://coffeescript.org/). Here's the list of other technologies:

* [Node.js](http://nodejs.org/)
* [Express.js](http://expressjs.com/)
* [CoffeeKup](http://coffeekup.org/)
* [Sugar.js](http://sugarjs.com/)
* [LESS](http://lesscss.org/) ([CCSS](https://github.com/aeosynth/ccss) implementation coming later)


## features

* Start coding your app instantly, no configuration required.
* Automatic localStorage caching of the application state and data.
* Clean Ajax deferring for retrieving data from external API's and storing that data locally.
* Connect to Facebook (TODO: also Twitter) instantly.
* Clean and flexible folder structure:
 * **client**: Client side code, templates and stylesheets.
 * **common**: Common code that get executed both on client and server.
 * **server**: Server code and configuration files.
 * **public**: Compiled client code, JS libraries and images


## get started

If you don't have Node.js installed, [get it here](http://nodejs.org/#download). You'll also need [git](http://git-scm.com/).

    mkdir name_of_your_project
    cd name_of_your_project
    git init
    git pull git://github.com/jussiry/houCe.git
    npm install -g coffee-script
    npm install -g node-dev
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

Simply make the git pull request again in your project folder:

    git pull git://github.com/jussiry/houCe.git

Be **warned**: you'll need to merge all the changes you've done to the original houCe files, which might not be pretty. In the future versions I'll try to make houCe more like a library that's completeley separated from the project code.