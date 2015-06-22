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
    scopeBlacklist:
      type: 'string'
      default: '.comment, .string'

  smartchr: null

  activate: ->
    @smartchr = new Smartchr

  deactivate: ->
    @smartchr?.destroy()
    @smartchr = null
