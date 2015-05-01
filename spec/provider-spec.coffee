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
      bufferPosition: end
      scopeDescriptor: cursor.getScopeDescriptor()
      prefix: prefix
    provider.getSuggestions(request)

  beforeEach ->
    waitsForPromise -> atom.packages.activatePackage('autocomplete-css')

    runs ->
      provider = atom.packages.getActivePackage('autocomplete-css').mainModule.getProvider()

    waitsFor -> Object.keys(provider.properties).length > 0

  Object.keys(packagesToTest).forEach (packageLabel) ->
    describe "#{packageLabel} files", ->
      beforeEach ->
        waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
        waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
        runs -> editor = atom.workspace.getActiveTextEditor()

      it "returns tag completions when not in a property list", ->
        editor.setText('')
        expect(getCompletions()).toBe null

        editor.setText('d')
        editor.setCursorBufferPosition([0, 0])
        expect(getCompletions()).toBe null

        editor.setCursorBufferPosition([0, 1])
        completions = getCompletions()
        expect(completions).toHaveLength 9
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.type).toBe 'tag'

      it "autocompletes property names without a prefix", ->
        editor.setText """
          body {

          }
        """
        editor.setCursorBufferPosition([1, 0])
        completions = getCompletions()
        expect(completions.length).toBe 209
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.type).toBe 'property'
          expect(completion.descriptionMoreURL.length).toBeGreaterThan 0

      it "autocompletes property names with a prefix", ->
        editor.setText """
          body {
            d
          }
        """
        editor.setCursorBufferPosition([1, 3])
        completions = getCompletions()
        expect(completions[0].text).toBe 'direction: '
        expect(completions[0].displayText).toBe 'direction'
        expect(completions[0].type).toBe 'property'
        expect(completions[0].replacementPrefix).toBe 'd'
        expect(completions[0].description.length).toBeGreaterThan 0
        expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0
        expect(completions[1].text).toBe 'display: '
        expect(completions[1].displayText).toBe 'display'
        expect(completions[1].type).toBe 'property'
        expect(completions[1].replacementPrefix).toBe 'd'

        editor.setText """
          body {
            D
          }
        """
        editor.setCursorBufferPosition([1, 3])
        completions = getCompletions()
        expect(completions.length).toBe 2
        expect(completions[0].text).toBe 'direction: '
        expect(completions[1].text).toBe 'display: '
        expect(completions[1].replacementPrefix).toBe 'D'

        editor.setText """
          body {
            d:
          }
        """
        editor.setCursorBufferPosition([1, 3])
        completions = getCompletions()
        expect(completions[0].text).toBe 'direction: '
        expect(completions[1].text).toBe 'display: '

        editor.setText """
          body {
            border-
          }
        """
        editor.setCursorBufferPosition([1, 9])
        completions = getCompletions()
        expect(completions.length).toBe 32
        expect(completions[0].text).toBe 'border-collapse: '
        expect(completions[0].displayText).toBe 'border-collapse'
        expect(completions[0].replacementPrefix).toBe 'border-'

        editor.setText """
          body {
            border-bot
          }
        """
        editor.setCursorBufferPosition([1, 12])
        completions = getCompletions()
        expect(completions.length).toBe 6
        expect(completions[0].text).toBe 'border-bottom: '
        expect(completions[1].text).toBe 'border-bottom-color: '

        editor.setText """
          body {
            border-bottom-
          }
        """
        editor.setCursorBufferPosition([1, 16])
        completions = getCompletions()
        expect(completions.length).toBe 5
        expect(completions[0].text).toBe 'border-bottom-color: '

      it "triggers autocomplete when an property name has been inserted", ->
        spyOn(atom.commands, 'dispatch')
        suggestion = {type: 'property', text: 'whatever'}
        provider.onDidInsertSuggestion({editor, suggestion})

        advanceClock 1
        expect(atom.commands.dispatch).toHaveBeenCalled()

        args = atom.commands.dispatch.mostRecentCall.args
        expect(args[0].tagName.toLowerCase()).toBe 'atom-text-editor'
        expect(args[1]).toBe 'autocomplete-plus:activate'

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
          expect(completion.text.length).toBeGreaterThan 0
          expect(completion.description.length).toBeGreaterThan 0
          expect(completion.descriptionMoreURL.length).toBeGreaterThan 0

        editor.setText """
          body {
            display:

          }
        """
        editor.setCursorBufferPosition([2, 0])
        completions = getCompletions()
        expect(completions.length).toBe 21
        for completion in completions
          expect(completion.text.length).toBeGreaterThan 0

      it "autocompletes property values with a prefix", ->
        editor.setText """
          body {
            display: i
          }
        """
        editor.setCursorBufferPosition([1, 12])
        completions = getCompletions()
        expect(completions[0].text).toBe 'inline;'
        expect(completions[0].description.length).toBeGreaterThan 0
        expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0
        expect(completions[1].text).toBe 'inline-block;'
        expect(completions[2].text).toBe 'inline-flex;'
        expect(completions[3].text).toBe 'inline-grid;'
        expect(completions[4].text).toBe 'inline-table;'
        expect(completions[5].text).toBe 'inherit;'

        editor.setText """
          body {
            display: I
          }
        """
        editor.setCursorBufferPosition([1, 12])
        completions = getCompletions()
        expect(completions.length).toBe 6
        expect(completions[0].text).toBe 'inline;'
        expect(completions[1].text).toBe 'inline-block;'
        expect(completions[2].text).toBe 'inline-flex;'
        expect(completions[3].text).toBe 'inline-grid;'
        expect(completions[4].text).toBe 'inline-table;'
        expect(completions[5].text).toBe 'inherit;'

        editor.setText """
          body {
            display:
              i
          }
        """
        editor.setCursorBufferPosition([2, 5])
        completions = getCompletions()
        expect(completions[0].text).toBe 'inline;'
        expect(completions[1].text).toBe 'inline-block;'
        expect(completions[2].text).toBe 'inline-flex;'
        expect(completions[3].text).toBe 'inline-grid;'
        expect(completions[4].text).toBe 'inline-table;'
        expect(completions[5].text).toBe 'inherit;'

      describe "tags", ->
        it "autocompletes with a prefix", ->
          editor.setText """
            ca {
            }
          """
          editor.setCursorBufferPosition([0, 2])
          completions = getCompletions()
          expect(completions.length).toBe 2
          expect(completions[0].text).toBe 'canvas'
          expect(completions[0].type).toBe 'tag'
          expect(completions[0].description).toBe 'Selector for <canvas> elements'
          expect(completions[1].text).toBe 'caption'

          editor.setText """
            canvas,ca {
            }
          """
          editor.setCursorBufferPosition([0, 9])
          completions = getCompletions()
          expect(completions.length).toBe 2
          expect(completions[0].text).toBe 'canvas'

          editor.setText """
            canvas ca {
            }
          """
          editor.setCursorBufferPosition([0, 9])
          completions = getCompletions()
          expect(completions.length).toBe 2
          expect(completions[0].text).toBe 'canvas'

          editor.setText """
            canvas, ca {
            }
          """
          editor.setCursorBufferPosition([0, 10])
          completions = getCompletions()
          expect(completions.length).toBe 2
          expect(completions[0].text).toBe 'canvas'

        it "does not autocompletes when prefix is preceded by class or id char", ->
          editor.setText """
            .ca {
            }
          """
          editor.setCursorBufferPosition([0, 3])
          completions = getCompletions()
          expect(completions).toBe null

          editor.setText """
            #ca {
            }
          """
          editor.setCursorBufferPosition([0, 3])
          completions = getCompletions()
          expect(completions).toBe null

      describe "pseudo selectors", ->
        it "autocompletes without a prefix", ->
          editor.setText """
            div: {
            }
          """
          editor.setCursorBufferPosition([0, 4])
          completions = getCompletions()
          expect(completions.length).toBe 43
          for completion in completions
            text = (completion.text or completion.snippet)
            expect(text.length).toBeGreaterThan 0
            expect(completion.type).toBe 'pseudo-selector'

        it "autocompletes with a prefix", ->
          editor.setText """
            div:f {
            }
          """
          editor.setCursorBufferPosition([0, 5])
          completions = getCompletions()
          expect(completions.length).toBe 5
          expect(completions[0].text).toBe ':first'
          expect(completions[0].type).toBe 'pseudo-selector'
          expect(completions[0].description.length).toBeGreaterThan 0
          expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0

        it "autocompletes with arguments", ->
          editor.setText """
            div:nth {
            }
          """
          editor.setCursorBufferPosition([0, 7])
          completions = getCompletions()
          expect(completions.length).toBe 4
          expect(completions[0].snippet).toBe ':nth-child(${1:an+b})'
          expect(completions[0].type).toBe 'pseudo-selector'
          expect(completions[0].description.length).toBeGreaterThan 0
          expect(completions[0].descriptionMoreURL.length).toBeGreaterThan 0

        it "autocompletes when nothing precedes the colon", ->
          editor.setText """
            :f {
            }
          """
          editor.setCursorBufferPosition([0, 2])
          completions = getCompletions()
          expect(completions.length).toBe 5
          expect(completions[0].text).toBe ':first'

  Object.keys(packagesToTest).forEach (packageLabel) ->
    if packageLabel[name] is 'language-css'
      describe "#{packageLabel[name]} files", ->
        beforeEach ->
          waitsForPromise -> atom.packages.activatePackage(packagesToTest[packageLabel].name)
          waitsForPromise -> atom.workspace.open(packagesToTest[packageLabel].file)
          runs -> editor = atom.workspace.getActiveTextEditor()

        it "autocompletes tags and properties when nesting inside the property list", ->
          editor.setText """
            .ca {
              di
            }
          """
          editor.setCursorBufferPosition([1, 4])
          completions = getCompletions()
          expect(completions.length).toBe 4
          expect(completions[0].text).toBe 'direction: '
          expect(completions[1].text).toBe 'display: '
          expect(completions[2].text).toBe 'dialog'
          expect(completions[3].text).toBe 'div'

        it "autocompletes pseudo selectors when nested in LESS and SCSS files", ->
          editor.setText """
            .some-class {
              .a:f
            }
          """
          editor.setCursorBufferPosition([1, 6])
          completions = getCompletions()
          expect(completions.length).toBe 5
          expect(completions[0].text).toBe ':first'
