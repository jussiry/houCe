

# index.ck will become the index.html file of your app, and it is not included
# in window.Templates, like normal templates and pages.

doctype 5

html_attrs = if @env is 'production' then manifest:'appcache.mf' else {}

html html_attrs, ->

  head ->
    meta charset: 'utf-8'
    title ''
    link href:"/stylesheets/less_styles.css", media:"screen", rel:"stylesheet", type:"text/css"
    link href:"/stylesheets/ccss_styles.css", media:"screen", rel:"stylesheet", type:"text/css"

  body ->

    # here comes header
    div '#page_content', ''
    div '#overflows', ''
    
    div '#scripts', ->
      script "window.client_config_from_server = #{JSON.stringify @config};"
      srcs = [
        '/preload.js'
        '/lib/modernizr.custom.js'
        '/lib/jquery-1.7.1.min.js'
        '/lib/jquery.animate-enhanced.min.js'
        '/lib/sugar-1.2.1.min.js'
        '/lib/coffeekup.js'
        '/templates.js'
        '/client_app.js'
      ]
      for src in srcs
        script src:src, type:'text/javascript'
    