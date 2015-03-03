fs = require 'fs'
path = require 'path'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/
propertyNamePrefixPattern = /[a-zA-Z]+[-a-zA-Z]*$/

module.exports =
  selector: '.source.css'
  id: 'autocomplete-css-cssprovider'

  requestHandler: (request) ->
    if @isCompletingValue(request)
      @getPropertyValueCompletions(request)
    else if @isCompletingName(request)
      @getPropertyNameCompletions(request)
    else
      []

  loadProperties: ->
    @properties = {}
    fs.readFile path.resolve(__dirname, '..', 'properties.json'), (error, content) =>
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
      lowerCasePrefix = prefix.toLowerCase()
      for value in values when value.indexOf(lowerCasePrefix) is 0
        completions.push({word: value, prefix})
    else
      for value in values
        completions.push({word: value, prefix: ''})
    completions

  getPropertyNamePrefix: (cursor, editor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    line = line.substring(0, cursor.getBufferColumn())
    propertyNamePrefixPattern.exec(line)?[0]

  getPropertyNameSuffix: (cursor, editor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    colonIndex = line.indexOf(':')
    if colonIndex >= cursor.getBufferColumn()
      ''
    else
      ': '

  getPropertyNameCompletions: ({cursor, editor}) ->
    suffix = @getPropertyNameSuffix(cursor, editor)
    prefix = @getPropertyNamePrefix(cursor, editor)
    completions = []
    if prefix
      lowerCasePrefix = prefix.toLowerCase()
      for property, values of @properties when property.indexOf(lowerCasePrefix) is 0
        completions.push({word: property + suffix, prefix})
    else
      for property, values of @properties
        completions.push({word: property + suffix, prefix: ''})
    completions
