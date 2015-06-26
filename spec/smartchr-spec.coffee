describe 'Smartchr', ->
  [workspaceElement, editor, otherEditor] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)

    atom.config.set('smartchr.scopeBlacklist', '.comment, .string')
    atom.config.set('smartchr.chrs', [])

    waitsForPromise ->
      Promise.all([
        atom.packages.activatePackage('smartchr')
        atom.packages.activatePackage('language-coffee-script')
        atom.packages.activatePackage('language-javascript')
      ])

    waitsForPromise ->
      atom.workspace.open('sample.coffee').then (_editor) ->
        editor = _editor

    waitsForPromise ->
      atom.workspace.open('sample.js').then (_editor) ->
        otherEditor = _editor

    runs ->
      atom.workspace.paneForItem(editor).setActiveItem(editor)

  describe 'activate', ->
    beforeEach ->
      atom.config.set('smartchr.chrs', [])
      editor.setText('')
      otherEditor.setText('')

    it 'no settings', ->
      editor.insertText('=')
      expect(editor.getText()).toEqual('=')

    it 'global settings', ->
      atom.config.set('smartchr.chrs', [
        {
          chr: '='
          candidates: [' = ', ' == ', '=']
        }
      ])

      editor.insertText('=')
      expect(editor.getText()).toEqual(' = ')
      editor.insertText('=')
      expect(editor.getText()).toEqual(' == ')
      editor.insertText('=')
      expect(editor.getText()).toEqual('=')

    it 'scope settings', ->
      atom.config.set('smartchr.chrs', [
        {
          chr: '='
          candidates: [' = ', ' == ', '=']
        }
      ], scopeSelector: '.source.coffee')

      editor.insertText('=')
      expect(editor.getText()).toEqual(' = ')
      editor.insertText('=')
      expect(editor.getText()).toEqual(' == ')
      editor.insertText('=')
      expect(editor.getText()).toEqual('=')

      atom.workspace.paneForItem(otherEditor).setActiveItem(otherEditor)

      otherEditor.insertText('=')
      expect(otherEditor.getText()).toEqual('=')
      otherEditor.insertText('=')
      expect(otherEditor.getText()).toEqual('==')

    it 'scopeBlacklist', ->
      atom.config.set('smartchr.chrs', [
        {
          chr: '='
          candidates: [' = ', ' == ', '=']
        }
      ], scopeSelector: '.source.coffee')

      editor.insertText('=')
      expect(editor.getText()).toEqual(' = ')

      editor.setText('str = "str"')
      editor.setCursorBufferPosition([0, 8])
      editor.insertText('=')
      expect(editor.getText()).toEqual('str = "s=tr"')
