fs = require 'fs'
path = require 'path'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/
propertyNamePrefixPattern = /[a-zA-Z]+[-a-zA-Z]*$/
pesudoSelectorPrefixPattern = /:(:)?([a-z]+[a-z-]*)?$/
cssDocsURL = "https://developer.mozilla.org/en-US/docs/Web/CSS"

module.exports =
  selector: '.source.css'

  getSuggestions: (request) ->
    if @isCompletingPseudoSelector(request)
      @getPseudoSelectorCompletions(request)
    else if @isCompletingValue(request)
      @getPropertyValueCompletions(request)
    else if @isCompletingName(request)
      @getPropertyNameCompletions(request)
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

  isCompletingPseudoSelector: ({editor, scopeDescriptor, bufferPosition}) ->
    scopes = scopeDescriptor.getScopesArray()
    if hasScope(scopes, 'meta.selector.css')
      true
    else if hasScope(scopes, 'source.css.scss') or hasScope(scopes, 'source.css.less')
      prefix = @getPseudoSelectorPrefix(editor, bufferPosition)
      if prefix
        previousBufferPosition = [bufferPosition.row, Math.max(0, bufferPosition.column - prefix.length - 1)]
        previousScopes = editor.scopeDescriptorForBufferPosition(previousBufferPosition)
        previousScopesArray = previousScopes.getScopesArray()
        not hasScope(previousScopesArray, 'meta.property-name.scss') and
          not hasScope(previousScopesArray, 'meta.property-value.scss') and
          not hasScope(previousScopesArray, 'support.type.property-name.css') and
          not hasScope(previousScopesArray, 'support.type.property-value.css')
      else
        false
    else
      false

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
        completions.push(@buildPropertyValueCompletion(value, property))
    else
      for value in values
        completions.push(@buildPropertyValueCompletion(value, property))
    completions

  buildPropertyValueCompletion: (value, propertyName) ->
    type: 'value'
    text: "#{value};"
    displayText: value
    description: "#{value} value for the #{propertyName} property"
    descriptionMoreURL: "#{cssDocsURL}/#{propertyName}#Values"

  getPropertyNamePrefix: (bufferPosition, editor) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    propertyNamePrefixPattern.exec(line)?[0]

  getPropertyNameCompletions: ({bufferPosition, editor}) ->
    prefix = @getPropertyNamePrefix(bufferPosition, editor)
    completions = []
    if prefix
      lowerCasePrefix = prefix.toLowerCase()
      for property, options of @properties when property.indexOf(lowerCasePrefix) is 0
        completions.push(@buildPropertyNameCompletion(property, prefix, options))
    else
      for property, options of @properties
        completions.push(@buildPropertyNameCompletion(property, '', options))
    completions

  buildPropertyNameCompletion: (propertyName, prefix, {description}) ->
    type: 'property'
    text: "#{propertyName}: "
    displayText: propertyName
    replacementPrefix: prefix
    description: description
    descriptionMoreURL: "#{cssDocsURL}/#{propertyName}"

  getPseudoSelectorPrefix: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    line.match(pesudoSelectorPrefixPattern)?[0]

  getPseudoSelectorCompletions: ({bufferPosition, editor}) ->
    prefix = @getPseudoSelectorPrefix(editor, bufferPosition)
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
      descriptionMoreURL: "#{cssDocsURL}/#{pseudoSelector}"

    if argument?
      completion.snippet = "#{pseudoSelector}(${1:#{argument}})"
    else
      completion.text = pseudoSelector
    completion

hasScope = (scopesArray, scope) ->
  scopesArray.indexOf(scope) isnt -1
