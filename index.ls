Padnews = require './lib/padnews'

new Padnews(\sgyfCRGiBZC).run do
  5000
  (event, msg) ->
    console.log "#{event} #{msg.time} [#{msg.location or \公開}]"
    for p in msg.content
      console.log "#p"
    console.log ''
