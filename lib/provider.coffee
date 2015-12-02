child_process = require 'child_process'

module.exports =
  selector: '.source.swift'

  getSuggestions: ({editor, bufferPosition, scopeDescriptor, prefix}) ->
    buffer = editor.getBuffer()
    text = buffer.getText()
    offset = buffer.characterIndexForPosition(bufferPosition)

    executable = '/usr/local/bin/sourcekitten'
    args = ['complete', '--text', text, '--offset', offset]
    response = child_process.execFileSync(executable, args)
    json = JSON.parse(response)
    completions = []
    for obj in json
      completions.push(@makeSuggestion(obj))

    completions
  # See https://github.com/atom/autocomplete-plus/wiki/Provider-API#suggestions

  makeSuggestion: (obj) ->
    snippet: obj['sourcetext']
    displayText: obj['name']
    description: obj['docBrief']
