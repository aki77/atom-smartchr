{CompositeDisposable, TextEditor} = require 'atom'

module.exports =
class Smartchr
  active: false
  characters: {}
  editor: null
  editorSubscriptions: null
  lastChr: null
  storeCount: 0

  constructor: ->
    @subscriptions = new CompositeDisposable
    @handleEvents()

  destroy: ->
    @subscriptions.dispose()
    @subscriptions = null
    @editorSubscriptions?.dispose()
    @editorSubscriptions = null

  handleEvents: =>
    @subscriptions.add atom.workspace.observeActivePaneItem(@updateCurrentEditor)

  updateCurrentEditor: (currentPaneItem) =>
    return if not currentPaneItem? or currentPaneItem is @editor

    @editorSubscriptions?.dispose()
    @editorSubscriptions = null

    # Stop tracking editor
    @editor = null
    @characters = {}
    @lastChr = null
    @active = false

    return unless @paneItemIsValid(currentPaneItem)

    # Track the new editor
    @editor = currentPaneItem

    # Subscribe to editor events:
    @editorSubscriptions = new CompositeDisposable
    @editorSubscriptions.add @editor.onWillInsertText(@onInsertText)
    @editorSubscriptions.add atom.config.observe 'smartchr.chrs', scope: @editor.getRootScopeDescriptor(), @updateCharacters

  paneItemIsValid: (paneItem) ->
    return false unless paneItem?
    return paneItem instanceof TextEditor

  onInsertText: ({text, cancel}) =>
    @cursorPositionSubscription?.dispose()
    unless @isTargetChr(text)
      @lastChr = null
      return

    @insert(text)
    @lastChr = text
    cancel()
    @cursorPositionSubscription = @editor.onDidChangeCursorPosition(@cursorMoved)
    @editorSubscriptions.add @cursorPositionSubscription

  insert: (text) ->
    @active = true
    chr = text
    candidates = @characters[chr]
    @storeCount = if chr is @lastChr then @storeCount + 1 else 0

    @editor.transact =>
      if @storeCount > 0
        beforeText = candidates[(@storeCount - 1) % candidates.length]
        @editor.mutateSelectedText (selection) ->
          selection.selectLeft(beforeText.length)
          selection.delete()

      @editor.insertText candidates[@storeCount % candidates.length]

    @active = false
    true

  isTargetChr: (chr) =>
    return false if @active
    return false unless chr
    return false unless chr.length is 1
    return false if @editor.hasMultipleCursors()
    return false unless @characters.hasOwnProperty(chr)

    true

  cursorMoved: =>
    @lastChr = null
    @cursorPositionSubscription.dispose()
    @editorSubscriptions.remove @cursorPositionSubscription

  updateCharacters: (chrs) =>
    chrs.forEach (obj) =>
      @characters[obj.chr] = obj.candidates
