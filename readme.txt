

## INSTALL
* nmp install coffee-script -g
* nmp install node-dev -g


## START
node-dev start.coffee




## WASTELAND

r log 'cookie: ' + req.cookies['likematch.sid'] + '  sessionID: ' + req.sessionID


### OLD start.sh scripts:
coffee -w -c -o server/javascripts/ server/ | egrep --color "error|$" &
coffee -w -c *.coffee ./javascripts | egrep --color "error|$" &
coffee -w -c */*.coffee | egrep --color "error|$" &





