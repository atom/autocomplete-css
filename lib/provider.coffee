fs = require 'fs'
path = require 'path'

propertyNameWithColonPattern = /^\s*(\S+)\s*:/
propertyNamePrefixPattern = /[a-zA-Z]+[-a-zA-Z]*$/
pesudoSelectorPrefixPattern = /:(:)?([a-z]+[a-z-]*)?$/
tagSelectorPrefixPattern = /(^|\s|,)([a-z]+)?$/
importantPrefixPattern = /(![a-z]+)$/
cssDocsURL = "https://developer.mozilla.org/en-US/docs/Web/CSS"

module.exports =
  selector: '.source.css, .source.sass'
  disableForSelector: '.source.css .comment, .source.css .string, .source.sass .comment, .source.sass .string'

  # Tell autocomplete to fuzzy filter the results of getSuggestions(). We are
  # still filtering by the first character of the prefix in this provider for
  # efficiency.
  filterSuggestions: true

  getSuggestions: (request) ->
    completions = null
    scopes = request.scopeDescriptor.getScopesArray()
    isSass = hasScope(scopes, 'source.sass')

    if @isCompletingValue(request)
      completions = @getPropertyValueCompletions(request)
    else if @isCompletingPseudoSelector(request)
      completions = @getPseudoSelectorCompletions(request)
    else
      if isSass and @isCompletingNameOrTag(request)
        completions = @getPropertyNameCompletions(request)
          .concat(@getTagCompletions(request))
      else if not isSass and @isCompletingName(request)
        completions = @getPropertyNameCompletions(request)

    if not isSass and @isCompletingTagSelector(request)
      tagCompletions = @getTagCompletions(request)
      if tagCompletions?.length
        completions ?= []
        completions = completions.concat(tagCompletions)

    completions

  onDidInsertSuggestion: ({editor, suggestion}) ->
    setTimeout(@triggerAutocomplete.bind(this, editor), 1) if suggestion.type is 'property'

  triggerAutocomplete: (editor) ->
    atom.commands.dispatch(atom.views.getView(editor), 'autocomplete-plus:activate', {activatedManually: false})

  loadProperties: ->
    @properties = {}
    fs.readFile path.resolve(__dirname, '..', 'completions.json'), (error, content) =>
      {@pseudoSelectors, @properties, @tags} = JSON.parse(content) unless error?
      return

  isCompletingValue: ({scopeDescriptor, bufferPosition, prefix, editor}) ->
    scopes = scopeDescriptor.getScopesArray()

    previousBufferPosition = [bufferPosition.row, Math.max(0, bufferPosition.column - prefix.length - 1)]
    previousScopes = editor.scopeDescriptorForBufferPosition(previousBufferPosition)
    previousScopesArray = previousScopes.getScopesArray()

    (hasScope(scopes, 'meta.property-value.css') and not hasScope(scopes, 'punctuation.separator.key-value.css')) or
    (hasScope(scopes, 'meta.property-list.scss') and prefix.trim() is ":") or
    (hasScope(scopes, 'meta.property-value.scss')) or
    (hasScope(scopes, 'source.sass') and (hasScope(scopes, 'meta.property-value.sass') or
      (not hasScope(previousScopesArray, "entity.name.tag.css.sass") and prefix.trim() is ":")
    ))

  isCompletingName: ({scopeDescriptor, bufferPosition, prefix, editor}) ->
    scopes = scopeDescriptor.getScopesArray()
    lineLength = editor.lineTextForBufferRow(bufferPosition.row).length
    isAtTerminator = prefix.endsWith(';')
    isAtParentSymbol = prefix.endsWith('&')
    isInPropertyList = not isAtTerminator and
      (hasScope(scopes, 'meta.property-list.css') or
      hasScope(scopes, 'meta.property-list.scss'))

    return false unless isInPropertyList
    return false if isAtParentSymbol

    previousBufferPosition = [bufferPosition.row, Math.max(0, bufferPosition.column - prefix.length - 1)]
    previousScopes = editor.scopeDescriptorForBufferPosition(previousBufferPosition)
    previousScopesArray = previousScopes.getScopesArray()

    return false if hasScope(previousScopesArray, 'entity.other.attribute-name.class.css') or
      hasScope(previousScopesArray, 'entity.other.attribute-name.id.css') or
      hasScope(previousScopesArray, 'entity.other.attribute-name.id') or
      hasScope(previousScopesArray, 'entity.other.attribute-name.parent-selector.css') or
      hasScope(previousScopesArray, 'entity.name.tag.reference.scss') or
      hasScope(previousScopesArray, 'entity.name.tag.scss')

    isAtBeginScopePunctuation = hasScope(scopes, 'punctuation.section.property-list.begin.css') or
      hasScope(scopes, 'punctuation.section.property-list.begin.bracket.curly.scss')
    isAtEndScopePunctuation = hasScope(scopes, 'punctuation.section.property-list.end.css') or
      hasScope(scopes, 'punctuation.section.property-list.end.bracket.curly.scss')

    if isAtBeginScopePunctuation
      # * Disallow here: `canvas,|{}`
      # * Allow here: `canvas,{| }`
      prefix.endsWith('{')
    else if isAtEndScopePunctuation
      # * Disallow here: `canvas,{}|`
      # * Allow here: `canvas,{ |}`
      not prefix.endsWith('}')
    else
      true

  isCompletingNameOrTag: ({scopeDescriptor, bufferPosition, editor}) ->
    scopes = scopeDescriptor.getScopesArray()
    prefix = @getPropertyNamePrefix(bufferPosition, editor)
    return @isPropertyNamePrefix(prefix) and
      hasScope(scopes, 'meta.selector.css') and
      not hasScope(scopes, 'entity.other.attribute-name.id.css.sass') and
      not hasScope(scopes, 'entity.other.attribute-name.class.sass')

  isCompletingTagSelector: ({editor, scopeDescriptor, bufferPosition}) ->
    scopes = scopeDescriptor.getScopesArray()
    tagSelectorPrefix = @getTagSelectorPrefix(editor, bufferPosition)
    return false unless tagSelectorPrefix?.length

    if hasScope(scopes, 'meta.selector.css')
      true
    else if hasScope(scopes, 'source.css.scss') or hasScope(scopes, 'source.css.less')
      not hasScope(scopes, 'meta.property-value.scss') and
        not hasScope(scopes, 'meta.property-value.css') and
        not hasScope(scopes, 'support.type.property-value.css')
    else
      false

  isCompletingPseudoSelector: ({editor, scopeDescriptor, bufferPosition}) ->
    scopes = scopeDescriptor.getScopesArray()
    if hasScope(scopes, 'meta.selector.css') and not hasScope(scopes, 'source.sass')
      true
    else if hasScope(scopes, 'source.css.scss') or hasScope(scopes, 'source.css.less') or hasScope(scopes, 'source.sass')
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

  isPropertyNamePrefix: (prefix) ->
    return false unless prefix?
    prefix = prefix.trim()
    prefix.length > 0 and prefix.match(/^[a-zA-Z-]+$/)

  getImportantPrefix: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    importantPrefixPattern.exec(line)?[1]

  getPreviousPropertyName: (bufferPosition, editor) ->
    {row} = bufferPosition
    while row >= 0
      line = editor.lineTextForBufferRow(row)
      propertyName = propertyNameWithColonPattern.exec(line)?[1]
      return propertyName if propertyName
      row--
    return

  getPropertyValueCompletions: ({bufferPosition, editor, prefix, scopeDescriptor}) ->
    property = @getPreviousPropertyName(bufferPosition, editor)
    values = @properties[property]?.values
    return null unless values?

    scopes = scopeDescriptor.getScopesArray()

    completions = []
    if @isPropertyValuePrefix(prefix)
      for value in values when firstCharsEqual(value, prefix)
        completions.push(@buildPropertyValueCompletion(value, property, scopes))
    else
      for value in values
        completions.push(@buildPropertyValueCompletion(value, property, scopes))

    if importantPrefix = @getImportantPrefix(editor, bufferPosition)
      # attention: règle dangereux
      completions.push
        type: 'keyword'
        text: '!important'
        displayText: '!important'
        replacementPrefix: importantPrefix
        description: "Forces this property to override any other declaration of the same property. Use with caution."
        descriptionMoreURL: "#{cssDocsURL}/Specificity#The_!important_exception"

    completions

  buildPropertyValueCompletion: (value, propertyName, scopes) ->
    text = value
    text += ';' unless hasScope(scopes, 'source.sass')

    {
      type: 'value'
      text: text
      displayText: value
      description: "#{value} value for the #{propertyName} property"
      descriptionMoreURL: "#{cssDocsURL}/#{propertyName}#Values"
    }

  getPropertyNamePrefix: (bufferPosition, editor) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    propertyNamePrefixPattern.exec(line)?[0]

  getPropertyNameCompletions: ({bufferPosition, editor, scopeDescriptor, activatedManually}) ->
    # Don't autocomplete property names in SASS on root level
    scopes = scopeDescriptor.getScopesArray()
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    return [] if hasScope(scopes, 'source.sass') and not line.match(/^(\s|\t)/)

    prefix = @getPropertyNamePrefix(bufferPosition, editor)
    return [] unless activatedManually or prefix

    completions = []
    for property, options of @properties when not prefix or firstCharsEqual(property, prefix)
      completions.push(@buildPropertyNameCompletion(property, prefix, options))
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
    for pseudoSelector, options of @pseudoSelectors when firstCharsEqual(pseudoSelector, prefix)
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

  getTagSelectorPrefix: (editor, bufferPosition) ->
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition])
    tagSelectorPrefixPattern.exec(line)?[2]

  getTagCompletions: ({bufferPosition, editor, prefix}) ->
    completions = []
    if prefix
      for tag in @tags when firstCharsEqual(tag, prefix)
        completions.push(@buildTagCompletion(tag))
    completions

  buildTagCompletion: (tag) ->
    type: 'tag'
    text: tag
    description: "Selector for <#{tag}> elements"

hasScope = (scopesArray, scope) ->
  scopesArray.indexOf(scope) isnt -1

firstCharsEqual = (str1, str2) ->
  str1[0].toLowerCase() is str2[0].toLowerCase()
