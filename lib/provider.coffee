fs = require 'fs'
path = require 'path'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/
propertyNamePrefixPattern = /[a-zA-Z]+[-a-zA-Z]*$/
pesudoSelectorPrefixPattern = /:(:)?([a-z]+[a-z-]*)?/

module.exports =
  selector: '.source.css'

  getSuggestions: (request) ->
    if @isCompletingValue(request)
      @getPropertyValueCompletions(request)
    else if @isCompletingName(request)
      @getPropertyNameCompletions(request)
    else if @isCompletingPseudoSelector(request)
      @getPseudoSelectorCompletions(request)
    else
      null

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'property'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate')

  loadProperties: ->
    @properties = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@pseudoSelectors, @properties} = JSON.parse(content) unless error?
      return

  isCompletingValue: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    (scopes.indexOf('meta.property-value.css') isnt -1 and scopes.indexOf('punctuation.separator.key-value.css') is -1) or
    (scopes.indexOf('meta.property-value.scss') isnt -1 and scopes.indexOf('punctuation.separator.key-value.scss') is -1)

  isCompletingName: ({scopeDescriptor})->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('meta.property-list.css') isnt -1 or
    scopes.indexOf('meta.property-list.scss') isnt -1

  isCompletingPseudoSelector: ({scopeDescriptor}) ->
    scopes = scopeDescriptor.getScopesArray()
    scopes.indexOf('meta.selector.css') isnt -1 or
    scopes.indexOf('meta.selector.scss') isnt -1

  isPropertyValuePrefix: (prefix) ->
    prefix = prefix.trim()
    prefix.length > 0 and prefix isnt ':'

  getPreviousPropertyName: (bufferPosition, editor) ->
    {row} = bufferPosition
    while row >= 0
      line = editor.lineTextForBufferRow(row)
      propertyName = propertyNameWithColonPattern.exec(line)?[1]
      return propertyName if propertyName
      row--
    return

  getPropertyValueCompletions: ({bufferPosition, editor, prefix}) ->
    property = @getPreviousPropertyName(bufferPosition, editor)
    values = @properties[property]?.values
    return null unless values?

    completions = []
    if @isPropertyValuePrefix(prefix)
      lowerCasePrefix = prefix.toLowerCase()
      for value in values when value.indexOf(lowerCasePrefix) is 0
        completions.push(@buildPropertyValueCompletion(value))
    else
      for value in values
        completions.push(@buildPropertyValueCompletion(value))
    completions

  buildPropertyValueCompletion: (value) ->
    type: 'value'
    text: "#{value};"
    displayText: value

  getPropertyNamePrefix: (bufferPosition, editor) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    propertyNamePrefixPattern.exec(line)?[0]

  getPropertyNameCompletions: ({bufferPosition, editor}) ->
    prefix = @getPropertyNamePrefix(bufferPosition, editor)
    completions = []
    if prefix
      lowerCasePrefix = prefix.toLowerCase()
      for property, values of @properties when property.indexOf(lowerCasePrefix) is 0
        completions.push(@buildPropertyNameCompletion(property, prefix))
    else
      for property, values of @properties
        completions.push(@buildPropertyNameCompletion(property, ''))
    completions

  buildPropertyNameCompletion: (propertyName, prefix) ->
    type: 'property'
    text: "#{propertyName}: "
    displayText: propertyName
    replacementPrefix: prefix

  getPseudoSelectorCompletions: ({bufferPosition, editor}) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    prefix = line.match(pesudoSelectorPrefixPattern)?[0]
    return null unless prefix

    completions = []
    lowerCasePrefix = prefix.toLowerCase()
    for pseudoSelector, options of @pseudoSelectors when pseudoSelector.indexOf(lowerCasePrefix) is 0
      completions.push(@buildPseudoSelectorCompletion(pseudoSelector, prefix, options))
    completions

  buildPseudoSelectorCompletion: (pseudoSelector, prefix, {argument, description}) ->
    completion =
      type: 'pseudo-selector'
      replacementPrefix: prefix
      description: description
      descriptionMoreURL: "https://developer.mozilla.org/en-US/docs/Web/CSS/#{pseudoSelector}"

    if argument?
      completion.snippet = "#{pseudoSelector}(${1:#{argument}})"
    else
      completion.text = pseudoSelector
    completion
