{properties} = require './package.json'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/

module.exports =
  selector: '.source.css'
  id: 'autocomplete-css-cssprovider'

  activate: ->

  getProvider: -> providers: [this]

  requestHandler: (request) ->
    if @isCompletingValue(request)
      @getPropertyValueCompletions(request)
    else if @isCompletingName(request)
      @getPropertyNameCompletions(request)
    else
      []

  isCompletingValue: ({scope}) ->
    scope.getScopesArray().indexOf('meta.property-value.css') isnt -1

  isCompletingName: ({scope})->
    scope.getScopesArray().indexOf('meta.property-list.css') isnt -1

  isCursorAfterColon: ({cursor, editor}) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    colonIndex = line.indexOf(':')
    cursor.getBufferColumn() > colonIndex >= 0

  isPropertyValuePrefix: (prefix) ->
    prefix = prefix.trim()
    prefix.length > 0 and prefix isnt ':'

  getPropertyNameOnCursorLine: (cursor, editor) ->
    line = editor.lineTextForBufferRow(cursor.getBufferRow())
    propertyNameWithColonPattern.exec(line)?[1]

  getPropertyValueCompletions: ({cursor, editor, prefix}) ->
    property = @getPropertyNameOnCursorLine(cursor, editor)
    values = properties[property]?.values
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
    if colonIndex > cursor.getBufferColumn()
      ''
    else
      ': '

  getPropertyNameCompletions: ({cursor, editor, prefix}) ->
    suffix = @getPropertyNameSuffix(cursor, editor)
    completions = []
    if prefix.trim().length > 0
      for property, values of properties when property.indexOf(prefix) is 0
        completions.push({word: property + suffix, prefix})
    else
      for property, values of properties
        completions.push({word: property + suffix, prefix: ''})
    completions
