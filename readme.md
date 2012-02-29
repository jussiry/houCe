
--- houCe ---

houCe is client oriented web framework designed with conventions that help you get ready and going in seconds, while providing structure that supports complex desktop like applications. houCe aspires to use one language for everything it does, and that language is CoffeeScript. Here's the list of other technologies:

* Node.js
* Express.js
* CoffeeKup
* Sugar.js
* LESS (CCSS implementation coming later)


--- features ---

* Start coding your app instantly, no configuration required.
* Clean distinction to 'client', 'server' and 'common' folders. Common code gets executed both on client and on the server. 
* Automatic localStorage caching of the application state and data.
* Clean Ajax deferring for retrieving data from external API's and storing that data locally.
* Connect to Facebook (TODO: also Twitter) instantly.


--- get started ---

    git clone https://jussiry@github.com/jussiry/houCe.git
    npm install -g coffee-script
    npm install -g node-dev
    cd houCe
    nmp install
    node-dev start.coffee
    Open http://localhost:3001/ on your browser.


--- start production ---

coffee start.coffee production