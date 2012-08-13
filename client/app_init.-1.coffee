
# -1 in app\_init.-1.coffee means that this file will be
# the last file executed in /public/client\_app.js

Houce.init_houce

  # Define client specific configs here. 'global.Config' is merged
  # from this and configs from '/server/config.coffee'.
  Config:
    data_config: {}
    storage_on: on
  # Initialize your data structure here to keep track of what exactly
  # are you storing into the 'global.Data' object.
  data_structure:
    config: {}
    cache_updated:
      coordinates: null
      last_stored: null
    misc:
      coord:
        latitude:  null
        longitude: null
      me: null
  # When structure of the Data changes increment data\_version to flush old cached
  # data from all clients. You can also type Houce.init\_data() in console of
  # a specific browser to empty its data and cache.
  data_version: 15

  # Name of the main page template; redirects from '/' to this page.
  main_page: 'intro'

  # 'before\_open\_page' functions is executed for all pages after 'close' event
  # of previous page and before 'open' event of new page.
  before_open_page: ->
    # init #page_content:
    pc = $('#page_content')
    pc.css
      opacity: 0
    pc.attr class: Pager.page_name
    $('body').scrollTop 0
    # Set app title
    $('head title').text "#{Houce.page_title()} - #{Config.app_name}"
  # 'after_open_page' is executed for every page after 'open' event of new page.
  after_open_page: ->
    reqAnimFrame -> $('#page_content').animate opacity: 1

  # 'init\_app' is executed only once when the application starts;
  # if you have some app specific stuff to initialize, here's the place to call them.
  init_app: ->
    $('body').render_top 'header'

