# workaround for https://github.com/RocketChat/meteor-streamer/issues/40
global._ = require('meteor/underscore')._

import '/lib/main.coffee'
import './chat'
import './indexes'
import './meetings'
import './rooms'
import './presence'
import './timesync'
import './zoom'
import './api'
