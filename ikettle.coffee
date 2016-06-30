module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  class IKettlePlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("IKettleDevice", {
        configDef: deviceConfigDef.IKettleDevice,
        createCallback: (config) =>
          device = new IKettleDevice(config)
          return device
      })

      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage(
          'pimatic-ikettle', "Found an iKettle!"
        )
      )

      @framework.ruleManager.addActionProvider(new IKettleActionProvider(@framework))

  plugin = new IKettlePlugin

  class IKettleDevice extends env.devices.Device

    constructor: (@config, lastState, deviceNum) ->
      @name = @config.name
      @id = @config.id
      super()

  # For testing...
  plugin.IKettleDevice = IKettleDevice

  class IKettleActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @config) ->
      return

    parseAction: (input, context) =>
      defaultTemp = 65

      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      tempTokens = strToTokens defaultTemp
      turnTokens = strToTokens ""

      setTemp = (m, tokens) => tempTokens = tokens
      setTurn = (m, tokens) => turnTokens = tokens

      m = M(input, context)
        .match(['kettle ','ikettle ','jug ']);

      next = m.match([' boil temp ',' boil temp',' boil temp: ',' boil temp:']).matchNumericExpression(setTemp)
      if next.hadMatch() then m = next

      next = m.match([' turn ']).matchStringWithVars(setTurn)
      if next.hadMatch() then m = next

      # boil
      # keepwarm

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(tempTokens)
        assert Array.isArray(turnTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new IKettleActionHandler(
            @framework, fileTokens
          )
        }

  plugin.IKettleActionProvider = IKettleActionProvider

  class IKettleActionHandler extends env.actions.ActionHandler

    constructor: (@framework) ->

    executeAction: (simulate) =>
      if simulate
        return Promise.resolve(__("would log 42"))
      else
        env.logger.info "42"
        return Promise.resolve(__("logged 42"))

  plugin.IKettleActionHandler = IKettleActionHandler

  return plugin
