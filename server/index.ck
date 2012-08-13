
# requiring index.ck will throw error and show this line on it. No worries.

# index.ck will become the index.html file of your app, and it is not included
# in window.Templates, like normal templates and pages.

doctype 5

# Manifest DISABLED
html_attrs = {} #if @config.env is 'production' then manifest:'appcache.mf' else {}

html html_attrs, ->

  head ->
    meta charset: 'utf-8'
    title 'houCe'

  body ->

    div '#wrapper', -> # IE prefers single child on body
      div '#page_content', ''

      div '#overflows', ''

      div '#scripts', ->

        coffeescript ->

          # PRELOAD IMGS
          temp_image = new Image()
          temp_image.src = src for src in [] # add images here

          # CSS
          el_scripts = document.getElementById 'scripts'
          add_link = (attrs)->
            link = document.createElement 'link'
            link[key] = val for key, val of attrs
            el_scripts.appendChild link

          for style in ['less_styles','ccss_styles'] # ,'less_styles'
            add_link href:"stylesheets/#{style}.css", media:"screen", rel:"stylesheet", type:"text/css"


        # SERVER CONFIG TO CLIENT

        js_files = @config.js_files
        delete @config.js_files
        script """
          window.client_config_from_server = #{JSON.stringify @config};
          window.global = window;
        """

        # LOAD JS FILE(S)
        srcs = if @config.env is 'production' then [[null, 'minified.js']] \
                                              else js_files

        script src: src[1], type: 'text/javascript' for src in srcs







