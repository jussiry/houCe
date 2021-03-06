
class Models.person
  C = @
  
  constructor: (data)->
    merge @, data

  # Instance methods:

  get_friends: (callback=(->)) ->
    if @friends?
      callback @friends
    else # TODO: deferring
      Houce.apis.fb_get "#{@id}/friends", (res)=>
        @friends = []
        for person_data in res.data
          @friends.push C.new_data person_data
        callback @friends

  get_likes: (callback=(->)) ->
    if @likes?
      callback @likes
    else
      Houce.apis.fb_get "#{@id}/likes", (res)=>
        @likes = []
        for item_data in res.data
          # create item:
          @likes.push item = Models.item.new_data item_data
          # add current person as 'a fan' of the liked item
          item.fans ?= {}
          item.fans[@id] = @
        callback @likes
    return


  # Class methods:

  Houce.model_new_data C
  
  C.plural = 'people'

  C.get = (fb_id='me', callback=(->))->
    # 'me' is a special value in Facebook Open Graph,
    # store it normally to Data.people[id], but also link Data.misc.me to that object.
    person = if fb_id is 'me' then Data.misc.me else Data.people[whose]
    if person?
      callback person
    else
      Houce.apis.fb_get fb_id, (data)->
        person = C.new_data data
        Data.misc.me = person if fb_id is 'me'
        callback person
    return