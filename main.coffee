fs = require 'fs'
path = require 'path'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/
propertyNamePrefixPattern = /[a-z]/

module.exports =
  selector: '.source.css'
  id: 'autocomplete-css-cssprovider'

  activate: -> @loadProperties()

  getProvider: -> providers: [this]

  requestHandler: (request) ->
    if @isCompletingValue(request)
      @getPropertyValueCompletions(request)
    else if @isCompletingName(request)
      @getPropertyNameCompletions(request)
    else
      []

  loadProperties: ->
    @properties = []
    fs.readFile path.join(__dirname, 'properties.json'), (error, content) =>
      @properties = JSON.parse(content) unless error?
      return

  isCompletingValue: ({scope}) ->
    scopes = scope.getScopesArray()
    (scopes.indexOf('meta.property-value.css') isnt -1 and scopes.indexOf('punctuation.separator.key-value.css') is -1) or
    (scopes.indexOf('meta.property-value.scss') isnt -1 and scopes.indexOf('punctuation.separator.key-value.scss') is -1)

  isCompletingName: ({scope})->
    scopes = scope.getScopesArray()
    scopes.indexOf('meta.property-list.css') isnt -1 or
    scopes.indexOf('meta.property-list.scss') isnt -1

  isPropertyValuePrefix: (prefix) ->
    prefix = prefix.trim()
    prefix.length > 0 and prefix isnt ':'

  isPropertyNamePrefix: (prefix) ->
    prefix = prefix.trim()
    propertyNamePrefixPattern.test(prefix[0])

  getPreviousPropertyName: (cursor, editor) ->
    row = cursor.getBufferRow()
    while row >= 0
      line = editor.lineTextForBufferRow(row)
      propertyName = propertyNameWithColonPattern.exec(line)?[1]
      return propertyName if propertyName
      row--
    return

  getPropertyValueCompletions: ({cursor, editor, prefix}) ->
    property = @getPreviousPropertyName(cursor, editor)
    values = @properties[property]?.values
    return [] unless values?

    completions = []
    if @isPropertyValuePrefix(prefix)
      for value in values when value.indexOf(prefix) is 0
        completions.push({word: value, prefix})
    else
      for value in values
        completions.push({word: value, prefix: ''})
    completions

  getPropertyNameSuffix: (cursor, editor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    colonIndex = line.indexOf(':')
    if colonIndex >= cursor.getBufferColumn()
      ''
    else
      ': '

  getPropertyNameCompletions: ({cursor, editor, prefix}) ->
    suffix = @getPropertyNameSuffix(cursor, editor)
    completions = []
    if @isPropertyNamePrefix(prefix)
      for property, values of @properties when property.indexOf(prefix) is 0
        completions.push({word: property + suffix, prefix})
    else
      for property, values of @properties
        completions.push({word: property + suffix, prefix: ''})
    completions
