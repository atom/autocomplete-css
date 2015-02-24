# Run this to update the static list of properties stored in this package's
# package.json file.

fs = require 'fs'
request = require 'request'
metadata = require './package.json'

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

  metadata.properties = properties
  fs.writeFileSync(require.resolve('./package.json'), JSON.stringify(metadata, null, 2))
