# workaround for https://github.com/RocketChat/meteor-streamer/issues/40
global._ = require('meteor/underscore')._

import '/lib/main'
import './bootstrap'
import './chat'
import './indexes'
import './log'
import './meetings'
import './rooms'
import './presence'
import './timesync'
import './zoom'
