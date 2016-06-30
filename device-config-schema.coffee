module.exports = {
  title: "pimatic-ikettle device config schemas"
  IKettleDevice: {
    title: "IKettleDevice config options"
    type: "object"
    required: ["host"]
    extensions: ["xLink"]
    properties:
      host:
        description: "the ip or hostname of the iKettle device"
        type: "string"
        default: ""
  }
}
