
## Require libs

task_name = process.argv[2]

# In docs_to_github we need to delete all code from gh-pages branch, so we must
# skip requiring most libraries when making docs.
unless task_name in ['build_docs', 'docs_to_github']
  require 'sugar'
  Object.extend()
  # require './common/common_utils' # not so sure if it's such a good idea to load these in the first place. only used for log-shorthand
  
  # less_options  = paths: ['./client', './client/styles']
  
  # LESS          = require 'less'
  # CoffeeScript  = require 'coffee-script'
  # CoffeeKup     = require 'coffeekup'
  # ccss          = require 'ccss'
  # ccss_helpers  = require './client/styles/ccss_helpers.s.coffee'
  houce = require "./server/houce.coffee"

fs     = require 'fs'
{exec} = require 'child_process'

# standard_exec_func = (err, stdout, stderr)->
#   throw err if err
#   console.log stdout + stderr


## Build client

task 'build_client', ->
  houce.build_client()
  houce.compile_index()


### Pull new version of houCe from github ###

task 'update_houce', ->
  exec "git pull git://github.com/jussiry/houCe.git", (err, stdout, stderr)->
    console.log stdout
    console.log "\n\n#{err}\n#{stderr}" if err
    # remove intro.page and intro_api_access.templ
    exec "rm ./client/intro.page ./client/intro_api_access.templ", (rm_err, rm_stdout, rm_stderr)->
      log "houCe updated! #{'Remember to merge files!' if err}"
    


## Build documentation under /docs

task 'build_docs', ->
  exec "./node_modules/.bin/docco-husky start.coffee client common server", (err, stdout, stderr)->
    if err then console.log err    \
           else console.log stdout



## Create docs to gh-branch and push them to Github pages

task 'docs_to_github', ->  
  log = (m)-> console.log m         
  exec "git branch -D gh-pages", (err, stdout, stderr)->
    # causes error if branch don't exist; no need to log it.
    exec "git symbolic-ref HEAD refs/heads/gh-pages", (err, stdout, stderr)->
      return log err if err
      exec "cake 'build_docs'", (err, stdout, stderr)->
        return log err if err
        log "docs built"
        exec "rm -R client common public server", (err, stdout, stderr)->
          return log err if err
          log "code removed"
          exec "mv ./public/docs/** .", (err, stdout, stderr)->
            return log err if err
            log "docs moved/linked"
            exec "git add .", (err, stdout, stderr)->
              return log err if err
              log "git add done"
              exec "git commit -a -m 'Docs updated'", (err, stdout, stderr)->
                return log err if err
                log "git commit done"
                exec "git push -f origin gh-pages", (err, stdout, stderr)->
                  return log err if err
                  log "git push done"
                  exec "git checkout master", (err, stdout, stderr)->
                    return log err if err
                    log "Done. Will take a while for http://jussiry.github.com/houCe to be refreshed."
