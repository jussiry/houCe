
# These helper functions and variables are available to objects
# defined in templates (mainly for @style).
# TODO: store them also in Tempalates.helpers ?
# TODO: make these availabe for @html and @init? Would it slow down rendering?


@rgb = @rgba = (r,g,b,a)->
  switch arguments.length
    when 3 then "rgb(#{r},#{g},#{b})"
    when 4 then "rgba(#{r},#{g},#{b},#{a})"
    when 1 then "rgb(#{r},#{r},#{r})"
    when 2 then "rgba(#{r},#{r},#{r},#{g})"

@hsl = (h,s,l,opacity)-> # not working?
  if arguments.length is 1
    # show only lightness
    l = h
    h = s = 0
  h = h / 360 if h >= 1
  s = s / 100 if s >= 1
  l = l / 100 if l >= 1
  if s is 0
    r = g = b = l * 255 # achromatic
  else
    hue2rgb = (p, q, t)->
      t += 1 if t < 0
      t -= 1 if t > 1
      if      t < 1/6 then p + (q - p) * 6 * t
      else if t < 1/2 then q
      else if t < 2/3 then p + (q - p) * (2/3 - t) * 6
      else                 p
    q = if l < 0.5 then l * (1 + s)  \
                   else l + s - l * s
    p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3) * 255
    g = hue2rgb(p, q, h)       * 255
    b = hue2rgb(p, q, h - 1/3) * 255

  rgb_s = "#{r.round()},#{g.round()},#{b.round()}"
  if opacity? then "rgba(#{ rgb_s },#{ opacity })" \
              else "rgb(#{ rgb_s })"




# COLORS
@primary_hue = 223

@font_black = @hsl @primary_hue, 23, 23
@font_gray  = @hsl @primary_hue, 10, 33

@light_gray  = @hsl @primary_hue, 10, 50




# EXTRA CLASSES

@secondary_font =
  font_family: 'Arial,Helvetica,sans-serif'
  font_weight: 'normal'


# FUNCTIONS

# for one liners
@row_height = (height, font_multiplier=0.8)->
  font_size:   height * font_multiplier
  line_height: height
  height:      height
  overflow:    'hidden'

# for multi liners
@line_height = (height, font_multiplier=0.8)->
  font_size:   height * font_multiplier
  line_height: height
  #height:      height
  #overflow: 'hidden'

@per_padding = (vert_padding, hor_padding, width=100)->
  padding: "#{vert_padding}% #{hor_padding}%"
  width: width - 2*hor_padding + '%'

# Calculate percentage based layout with given margins and paddings
@per_layout = (args={})->
  args.margins  ?= [0,0]
  args.paddings ?= [0,0]
  args.height   ?= 100
  args.width    ?= 100

  margin:  args.margins .join('% ') + '%'
  padding: args.paddings.join('% ') + '%'
  height: args.height - 2*args.margins[0] - 2*args.paddings[0] + '%'
  width:  args.width  - 2*args.margins[1] - 2*args.paddings[1] + '%'


@border_radius = (str)->
  str = str + 'px' if typeof str is 'number'
  MozBorderRadius:    str
  WebkitBorderRadius: str
  borderRadius:       str

@box_shadow = (str)->
  MozBoxShadow:    str
  WebkitBoxShadow: str
  boxShadow:       str


@gradient = (from, to)->
  # TODO: ERROR: CCSS fails to make multiple declarations with same name
  # (temporary hack: use background_image for the other)
  background: "-ms-linear-gradient(90deg, #{to}, #{from})"
  #background: "-moz-linear-gradient(90deg, #{to}, #{from})"
  background_image: "-webkit-gradient(linear, 0 0, 0 100%, from(#{from}), to(#{to}))"

# transition time
@transition = (str)->
  str = "all #{str} ease-out"
  WebkitTransition: str
  MozTransition:    str
  OTransition:      str
  MSTransition:     str
  transition:       str

# transform size or shape
@transform = (str)->
  WebkitTransform:  str
  MozTransform:     str
  MSTransform:      str
  transform:        str

