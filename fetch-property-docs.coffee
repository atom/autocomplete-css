path = require 'path'
fs = require 'fs'
request = require 'request'
Promise = require 'bluebird'

mdnCSSURL = 'https://developer.mozilla.org/en-US/docs/Web/CSS'
mdnJSONAPI = 'https://developer.mozilla.org/en-US/search.json'
propertiesURL = 'https://raw.githubusercontent.com/adobe/brackets/master/src/extensions/default/CSSCodeHints/CSSProperties.json'

fetch = ->
  propertiesPromise = new Promise (resolve) ->
    request {json: true, url: propertiesURL}, (error, response, properties) ->
      if error?
        console.error(error.message)
        resolve(null)

      if response.statusCode isnt 200
        console.error("Request for CSSProperties.json failed: #{response.statusCode}")
        resolve(null)

      resolve(properties)

  docsPromise = propertiesPromise.then (properties) ->
    return unless properties?

    MAX = 10
    queue = Object.keys(properties)
    running = []
    docs = {}

    new Promise (resolve) ->
      checkEnd = ->
        resolve(docs) if queue.length is 0 and running.length is 0

      removeRunning = (propertyName) ->
        index = running.indexOf(propertyName)
        running.splice(index, 1) if index > -1

      runNext = ->
        checkEnd()
        if queue.length isnt 0
          propertyName = queue.pop()
          running.push(propertyName)
          run(propertyName)

      run = (propertyName) ->
        url = "#{mdnJSONAPI}?q=#{propertyName}"
        request {json: true, url}, (error, response, searchResults) ->
          if !error? and response.statusCode is 200
            handleRequest(propertyName, searchResults)
          else
            console.error "Req failed #{url}; #{response.statusCode}, #{error}"
          removeRunning(propertyName)
          checkEnd()
          runNext()

      handleRequest = (propertyName, searchResults) ->
        if searchResults.documents?
          for doc in searchResults.documents
            if doc.url is "#{mdnCSSURL}/#{propertyName}"
              docs[propertyName] = filterExcerpt(propertyName, doc.excerpt)
              break
        return

      runNext() for i in [0..MAX]
      return

FixesForCrappyDescriptions =
  border: 'Specifies all borders on an HTMLElement.'
  clear: 'Specifies whether an element can be next to floating elements that precede it or must be moved down (cleared) below them.'

filterExcerpt = (propertyName, excerpt) ->
  return FixesForCrappyDescriptions[propertyName] if FixesForCrappyDescriptions[propertyName]?
  beginningPattern = /^the (css )?[a-z-]+ (css )?property (is )?(\w+)/i
  excerpt = excerpt.replace(/<\/?mark>/g, '')
  excerpt = excerpt.replace beginningPattern, (match) ->
    matches = beginningPattern.exec(match)
    firstWord = matches[4]
    firstWord[0].toUpperCase() + firstWord.slice(1)
  periodIndex = excerpt.indexOf('.')
  excerpt = excerpt.slice(0, periodIndex + 1) if periodIndex > -1
  excerpt

# Save a file if run from the command line
if require.main is module
  fetch().then (docs) ->
    if docs?
      fs.writeFileSync(path.join(__dirname, 'property-docs.json'), "#{JSON.stringify(docs, null, '  ')}\n")
    else
      console.error 'No docs'

module.exports = fetch
