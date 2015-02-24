provider = require('../main').getProvider().providers[0]

describe "CSS Autocompletions", ->
  editor = null

  getCompletions = ->
    cursor = editor.getLastCursor()
    start = cursor.getBeginningOfCurrentWordBufferPosition()
    end = cursor.getBufferPosition()
    prefix = editor.getTextInRange([start, end])
    request =
      editor: editor
      cursor: cursor
      scope: cursor.getScopeDescriptor()
      prefix: prefix
    provider.requestHandler(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('language-css')
    waitsForPromise -> atom.workspace.open('test.css')
    runs -> editor = atom.workspace.getActiveTextEditor()

  it "returns no completions when not in a property list", ->
    editor.setText('')
    expect(getCompletions().length).toBe 0

    editor.setText('d')
    editor.setCursorBufferPosition([0, 0])
    expect(getCompletions().length).toBe 0
    editor.setCursorBufferPosition([0, 1])
    expect(getCompletions().length).toBe 0

  it "autocompletes property names without a prefix", ->
    editor.setText """
      body {

      }
    """
    editor.setCursorBufferPosition([1, 0])
    completions = getCompletions()
    expect(completions.length).toBe 209
    for completion in completions
      expect(completion.word.length).toBeGreaterThan 0

  it "autocompletes property names with a prefix", ->
    editor.setText """
      body {
        d
      }
    """
    editor.setCursorBufferPosition([1, 3])
    completions = getCompletions()
    expect(completions.length).toBe 2
    expect(completions[0].word).toBe 'direction: '
    expect(completions[1].word).toBe 'display: '

    editor.setText """
      body {
        d:
      }
    """
    editor.setCursorBufferPosition([1, 3])
    completions = getCompletions()
    expect(completions.length).toBe 2
    expect(completions[0].word).toBe 'direction: '
    expect(completions[1].word).toBe 'display: '

  it "autocompletes property values without a prefix", ->
    editor.setText """
      body {
        display:
      }
    """
    editor.setCursorBufferPosition([1, 10])
    completions = getCompletions()
    expect(completions.length).toBe 21
    for completion in completions
      expect(completion.word.length).toBeGreaterThan 0

  it "autocompletes property values with a prefix", ->
    editor.setText """
      body {
        display: i
      }
    """
    editor.setCursorBufferPosition([1, 12])
    completions = getCompletions()
    expect(completions.length).toBe 6
    expect(completions[0].word).toBe 'inline'
    expect(completions[1].word).toBe 'inline-block'
    expect(completions[2].word).toBe 'inline-flex'
    expect(completions[3].word).toBe 'inline-grid'
    expect(completions[4].word).toBe 'inline-table'
    expect(completions[5].word).toBe 'inherit'
