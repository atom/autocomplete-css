# Run this to update the static list of properties stored in the properties.json
# file at the root of this repository.

path = require 'path'
fs = require 'fs'
request = require 'request'

requestOptions =
  url: 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/CSSCodeHints/CSSProperties.json'
  json: true

request requestOptions, (error, response, properties) ->
  if error?
    console.error(error.message)
    return process.exit(1)

  if response.statusCode isnt 200
    console.error("Request for CSSProperties.json failed: #{response.statusCode}")
    return process.exit(1)
  
  # put popular properties first in the list - only needs to include ones which
  # have an alphabetically preferred sibling (i.e. width and whitespace)
  popular_props = [
    'background', 'border', 'bottom', 'box-sizing', 'box-shadow',
    'color', 'cursor', 'content', 'clear', 'columns',
    'display', 
    'float', 'font', 'font-size', 'font-family', 'font-weight',
    'opacity', 'overflow',
    'padding', 'position', 
    'top', 'text-align', 'text-decoration', 
    'visibility', 
    'width', 
  
  ]
  ordered = {}
  
  for key, value of properties
    if key in popular_props
      ordered[key] = value
  
  for key, value of properties
    if key not in popular_props
      ordered[key] = value
        
  properties = ordered
  
  fs.writeFileSync(path.join(__dirname, 'properties.json'), "#{JSON.stringify(properties, null, 0)}\n")
