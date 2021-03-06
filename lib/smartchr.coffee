{CompositeDisposable} = require 'atom'
{Selector} = require 'selector-kit'
{selectorsMatchScopeChain} = require './scope-helpers'

module.exports =
class Smartchr
  active: false
  characters: {}
  cancelSubscription: null
  cursorPositionSubscription: null
  editorSubscriptions: null
  lastChr: null
  storeCount: 0

  constructor: ->
    @subscriptions = new CompositeDisposable
    @handleEvents()

  destroy: ->
    @reset()
    @subscriptions.dispose()
    @subscriptions = null
    @editorSubscriptions?.dispose()
    @editorSubscriptions = null

  handleEvents: =>
    @subscriptions.add(atom.workspace.observeActivePaneItem(@updateCurrentEditor))

  updateCurrentEditor: (currentPaneItem) =>
    return if not currentPaneItem? or currentPaneItem is @editor

    @reset()
    @editorSubscriptions?.dispose()
    @editorSubscriptions = null

    # Stop tracking editor
    @editor = null
    @editorView = null
    @characters = {}

    return unless @paneItemIsValid(currentPaneItem)

    # Track the new editor
    @editor = currentPaneItem
    @editorView = atom.views.getView(@editor)

    # Subscribe to editor events:
    @editorSubscriptions = new CompositeDisposable
    @editorSubscriptions.add @editor.onWillInsertText(@onInsertText)

    options =
      scope: @editor.getRootScopeDescriptor()

    @editorSubscriptions.add atom.config.observe 'smartchr.chrs', options, @updateCharacters
    @editorSubscriptions.add atom.config.observe 'smartchr.scopeBlacklist', options, @updateScopeBlacklist

  paneItemIsValid: (paneItem) ->
    # TODO: remove conditional when `isTextEditor` is shipped.
    if typeof atom.workspace.isTextEditor is 'function'
      atom.workspace.isTextEditor(paneItem)
    else
      return false unless paneItem?
      # Should we disqualify TextEditors with the Grammar text.plain.null-grammar?
      paneItem.getText?

  onInsertText: ({text, cancel}) =>
    return if @insertFlag
    return @reset() unless @isTargetChr(text)

    @insertCandidate(text)
    cancel()

    @cursorPositionSubscription ?= @editor.onDidChangeCursorPosition(@reset)

  insertCandidate: (chr) ->
    candidates = @characters[chr]
    @storeCount = if chr is @lastChr then @storeCount + 1 else 0
    @lastChr = chr

    @transact =>
      if @storeCount > 0
        beforeText = candidates[(@storeCount - 1) % candidates.length]
        @editor.mutateSelectedText (selection) ->
          selection.selectLeft(beforeText.length)
          selection.delete()

      @editor.insertText(candidates[@storeCount % candidates.length])

    @cancelSubscription ?= atom.commands.add(@editorView, 'core:cancel', @cancel)

  transact: (fun) =>
    @cursorPositionSubscription?.dispose()
    @cursorPositionSubscription = null
    @insertFlag = true
    @editor.transact(fun)
    @insertFlag = false

  isTargetChr: (chr) =>
    return false unless chr
    return false unless chr.length is 1
    return false if @editor.hasMultipleCursors()
    return false unless @characters.hasOwnProperty(chr)
    return false if selectorsMatchScopeChain(@scopeSelectors, @getAfterInsertScopeChain(chr))
    true

  getAfterInsertScopeChain: (chr) =>
    scopes = []
    @transact =>
      @editor.insertText(chr)
      scopes = @editor.getLastCursor().getScopeDescriptor().getScopeChain()
      @editor.abortTransaction()
    scopes

  cancel: =>
    candidates = @characters[@lastChr]
    beforeText = candidates[(@storeCount) % candidates.length]
    chr = @lastChr

    @reset()

    @transact =>
      @editor.mutateSelectedText (selection) ->
        selection.selectLeft(beforeText.length)
        selection.delete()
      @editor.insertText(chr)

  reset: =>
    return unless @lastChr?
    @lastChr = null
    @cancelSubscription?.dispose()
    @cancelSubscription = null
    @cursorPositionSubscription?.dispose()
    @cursorPositionSubscription = null

  updateCharacters: (chrs) =>
    @characters = {}
    chrs.forEach (obj) =>
      @characters[obj.chr] = obj.candidates

  updateScopeBlacklist: (scopes) =>
    @scopeSelectors = Selector.create(scopes)
