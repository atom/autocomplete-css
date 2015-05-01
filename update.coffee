# Run this to update the static list of properties stored in the properties.json
# file at the root of this repository.

path = require 'path'
fs = require 'fs'
request = require 'request'
Promise = require 'bluebird'
fetchPropertyDescriptions = require './fetch-property-docs'

PropertiesURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/CSSCodeHints/CSSProperties.json'

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

Promise.settle([propertiesPromise, propertyDescriptionsPromise]).then (results) ->
  properties = {}
  propertiesRaw = results[0].value()
  propertyDescriptions = results[1].value()
  sortedPropertyNames = JSON.parse(fs.readFileSync(path.join(__dirname, 'sorted-property-names.json')))
  for propertyName in sortedPropertyNames
    continue unless metadata = propertiesRaw[propertyName]
    metadata.description = propertyDescriptions[propertyName]
    properties[propertyName] = metadata
    console.warn "No description for property #{propertyName}" unless propertyDescriptions[propertyName]?

  for propertyName, d of propertiesRaw
    console.warn "Ignoring #{propertyName}; not in sorted-property-names.json" if sortedPropertyNames.indexOf(propertyName) < 0

  tags = JSON.parse(fs.readFileSync(path.join(__dirname, 'html-tags.json')))
  pseudoSelectors = JSON.parse(fs.readFileSync(path.join(__dirname, 'pseudo-selectors.json')))

  completions = {tags, properties, pseudoSelectors}
  fs.writeFileSync(path.join(__dirname, 'completions.json'), "#{JSON.stringify(completions, null, '  ')}\n")
