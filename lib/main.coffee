{CompositeDisposable} = require 'atom'
Smartchr = require './smartchr'

module.exports =
  config:
    chrs:
      type: 'array'
      default: []
      items:
        type: 'object'
        properties:
          chr:
            type: 'string'
          candidates:
            type: 'array'
            items:
              type: 'string'

  smartchr: null

  activate: ->
    @smartchr = new Smartchr

  deactivate: ->
    @smartchr?.destroy()
    @smartchr = null
