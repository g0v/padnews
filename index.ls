Padnews = require './lib/padnews'

new Padnews(\sgyfCRGiBZC).run do
  5000
  -> console.log "#{it.time} [#{it.location or \公開}] #{it.content}"
  -> console.log "something updated"
