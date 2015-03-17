provider = require './provider'

module.exports =
  activate: -> provider.loadProperties()

  getProvider: -> provider
