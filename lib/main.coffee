provider = require './provider'

module.exports =
  config:
    selector:
      type: 'string'
      default: '.source.css, .source.sass'
    disableForSelector:
      type: 'string'
      default: '.source.css .comment, .source.css .string, .source.sass .comment, .source.sass .string'

  activate: -> provider.loadProperties()

  getProvider: -> provider
