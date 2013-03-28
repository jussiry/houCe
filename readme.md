houCe is a client oriented node.js framework that uses [CoffeeScript](http://coffeescript.org/) to build **templates** that have styles definitions and controllers in the same file next to the template definition. This is done by using [CoffeeKup](http://coffeekup.org/) to compile template HTML and [CCSS](https://github.com/aeosynth/ccss) to build CSS definitions.

In addition houCe has automatic route handler (aka `Pager`) that fires top templates `@open` controller with params specified in URL. E.g. `/#/list/limit=10/green` would execute `list.tmpl` files `@open` function with `{limit:10, green:true}`.

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


## commands

* `coffee start.coffee production` - Start in production mode.
* `cake update_houce` - Update to new version of houCe. *Warning*: you'll need to merge all the changes you've done to original houCe files. Also removes `intro.page` and `intro_api_access.templ`.
* `cake build_client` - Compile client files to public folder; normally done automatically.
* `cake build_docs` - Build documentation to /public/docs


## documentation

File by file documentation can be [found here](http://jussiry.github.com/houCe/index.html).
