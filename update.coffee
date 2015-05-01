# Run this to update the static list of properties stored in the properties.json
# file at the root of this repository.

path = require 'path'
fs = require 'fs'
request = require 'request'
Promise = require 'bluebird'
fetchPropertyDescriptions = require './fetch-property-docs'

PropertiesURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/CSSCodeHints/CSSProperties.json'
TagsURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/HTMLCodeHints/HtmlTags.json'

propertyDescriptionsPromise = fetchPropertyDescriptions()
propertiesPromise = new Promise (resolve) ->
  request {json: true, url: PropertiesURL}, (error, response, properties) ->
    if error?
      console.error(error.message)
      resolve(null)
    if response.statusCode isnt 200
      console.error("Request for CSSProperties.json failed: #{response.statusCode}")
      resolve(null)
    resolve(properties)
tagsPromise = new Promise (resolve) ->
  request {json: true, url: TagsURL}, (error, response, properties) ->
    if error?
      console.error(error.message)
      resolve(null)
    if response.statusCode isnt 200
      console.error("Request for HtmlTags.json failed: #{response.statusCode}")
      resolve(null)
    resolve(properties)

Promise.settle([tagsPromise, propertiesPromise, propertyDescriptionsPromise]).then (results) ->
  tagsRaw = results[0].value()
  tags = Object.keys(tagsRaw)

  properties = results[1].value()
  propertyDescriptions = results[2].value()
  for propertyName, metadata of properties
    metadata.description = propertyDescriptions[propertyName]
    unless propertyDescriptions[propertyName]?
      console.warn "No description for property #{propertyName}"

  pseudoSelectors = JSON.parse(fs.readFileSync(path.join(__dirname, 'pseudo-selectors.json')))

  completions = {tags, properties, pseudoSelectors}
  fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(completions, null, '  ')}\n")
