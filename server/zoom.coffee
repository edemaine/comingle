Meteor.methods
  zoomEmbed: ->
    Meteor.settings.zoom?.apiKey and
    Meteor.settings.zoom?.apiSecret
