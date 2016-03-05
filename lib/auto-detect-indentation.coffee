{CompositeDisposable} = require 'atom'
IndentationManager = require './indentation-manager'

module.exports =
  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.observeTextEditors (editor) =>
      @_handleLoad editor
    @disposables.add atom.commands.add('atom-text-editor', 'indentation-selector:show', @createIndentationListView)

    @indentationListView = null
    @indentationStatusView = null

  _handleLoad: (editor) ->
    @_attach editor

    onSaveDisposable = editor.buffer.onDidSave =>
      if IndentationManager.isManuallyIndented editor
        onSaveDisposable?.dispose()
      else
        indentation = IndentationManager.autoDetectIndentation editor
        IndentationManager.setIndentation editor, indentation, true

    if editor.displayBuffer?.onDidTokenize
      onTokenizeDisposable = editor.displayBuffer.onDidTokenize =>
        # This event fires when the grammar is first loaded.
        # We re-analyze the file's indentation, in order to ignore indentation inside comments
        @_attach editor
        onTokenizeDisposable?.dispose()
        onTokenizeDisposable = null
    else
      onTokenizeDisposable = null

    editor.onDidDestroy ->
      onSaveDisposable?.dispose()
      onTokenizeDisposable?.dispose()

  deactivate: ->
    @disposables.dispose()

  createIndentationListView: =>
    unless @indentationListView?
      IndentationListView = require './indentation-list-view'
      indentationListView = new IndentationListView()
    indentationListView.toggle()

  consumeStatusBar: (statusBar) ->
    unless @IndentationStatusView?
      IndentationStatusView = require './indentation-status-view'
      indentationStatusView = new IndentationStatusView().initialize(statusBar)
    indentationStatusView.attach()

  _attach: (editor) ->
    # Disable atom's native detection of spaces/tabs
    editor.shouldUseSoftTabs = ->
      @softTabs

    # Trigger "did-change-indentation" event when indentation is changed
    editor.setSoftTabs = (@softTabs) ->
      @emitter.emit 'did-change-indentation'
      @softTabs

    # Trigger "did-change-indentation" event when indentation is changed
    editor.setTabLength = (tabLength) ->
      value = @displayBuffer.setTabLength(tabLength)
      @emitter.emit 'did-change-indentation'
      value

    indentation = IndentationManager.autoDetectIndentation editor
    IndentationManager.setIndentation editor, indentation, true

  config:
    indentationTypes:
      type: 'array'
      items:
        type: 'object'
        properties:
          name:
            type: 'string'
          softTabs:
            type: 'boolean'
          tabLength:
            type: 'integer'
      default:
        [
          {
            name: "2 Spaces"
            softTabs: true
            tabLength: 2
          }
          {
            name: "4 Spaces"
            softTabs: true
            tabLength: 4
          }
          {
            name: "8 Spaces"
            softTabs: true
            tabLength: 8
          }
          {
            name: "Tabs (default width)"
            softTabs: false
          }
          {
            name: "Tabs (2 wide)"
            softTabs: false
            tabLength: 2
          }
          {
            name: "Tabs (4 wide)"
            softTabs: false
            tabLength: 4
          }
          {
            name: "Tabs (8 wide)"
            softTabs: false
            tabLength: 8
          }
        ]
