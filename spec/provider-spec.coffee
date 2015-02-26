packagesToTest =
  CSS:
    name: 'language-css'
    file: 'test.css'
  SCSS:
    name: 'language-sass'
    file: 'test.scss'
  Less:
    name: 'language-less'
    file: 'test.less'

describe "CSS property name and value autocompletions", ->
  [editor, provider] = []

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
    waitsForPromise -> atom.packages.activatePackage('autocomplete-css')

    runs ->
      [provider] = atom.packages.getActivePackage('autocomplete-css').mainModule.getProvider().providers

    waitsFor -> Object.keys(provider.properties).length > 0

  Object.keys(packagesToTest).forEach (packageLabel) ->
    describe "#{packageLabel} files", ->
      beforeEach ->
        waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
        waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
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
        expect(completions[0].word).toBe 'direction'
        expect(completions[1].word).toBe 'display'

        editor.setText """
          body {
            border-
          }
        """
        editor.setCursorBufferPosition([1, 9])
        completions = getCompletions()
        expect(completions.length).toBe 32
        expect(completions[0].word).toBe 'border-collapse: '

        editor.setText """
          body {
            border-bot
          }
        """
        editor.setCursorBufferPosition([1, 12])
        completions = getCompletions()
        expect(completions.length).toBe 6
        expect(completions[0].word).toBe 'border-bottom: '
        expect(completions[1].word).toBe 'border-bottom-color: '

        editor.setText """
          body {
            border-bottom-
          }
        """
        editor.setCursorBufferPosition([1, 16])
        completions = getCompletions()
        expect(completions.length).toBe 5
        expect(completions[0].word).toBe 'border-bottom-color: '

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

        editor.setText """
          body {
            display:

          }
        """
        editor.setCursorBufferPosition([2, 0])
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

        editor.setText """
          body {
            display:
              i
          }
        """
        editor.setCursorBufferPosition([2, 5])
        completions = getCompletions()
        expect(completions.length).toBe 6
        expect(completions[0].word).toBe 'inline'
        expect(completions[1].word).toBe 'inline-block'
        expect(completions[2].word).toBe 'inline-flex'
        expect(completions[3].word).toBe 'inline-grid'
        expect(completions[4].word).toBe 'inline-table'
        expect(completions[5].word).toBe 'inherit'
