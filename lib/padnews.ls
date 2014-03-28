require! <[request ent deep-diff]>

class Padnews
  regex =
    splitter: /(<\/p>|<p>)/
    tags:     /<[^<]*>/gi
    entry:    /^\s*(\d?\d:\S\S)\s*(?:\[\s*([^\[]*)\s*\])?\s*(.+)\s*/
    newline:  /\r?\n/
  (@id, @domain, @api-client) ->
    @domain = if @domain then "#{domain}." else ''
    @delay = 5000
    @prev = []
    @news = []
  get-by-api: (err, data) !~> @get err, null, data
  get: (err, res, body) !~>
    return if err or res.statusCode isnt 200
    @prev = @news
    @news = []
    var last
    for line in body.split regex.splitter
      line .= replace regex.tags, ''
      line = ent.decode line
      news = regex.entry.exec line
      if news
        last :=
          time:     news.1
          location: news.2 or ''
          content:  [news.3]
        @news.push last
      else if line.length and not regex.newline.test line
        last?content.push line
    @news.reverse!
    @did-update!
  did-update: !->
    if @prev.length
      for i til @news.length
        current = @news[i]
        prev    = @prev[i]
        if prev
          ds = deep-diff.diff current, prev
          continue if not ds
          @on-msg? \update, current, i, ds
        else
          @on-msg? \create current, i
      for i from @prev.length-1 to @news.length by -1
        prev = @prev[i]
        @on-msg? \remove, prev, i
    else if @news.length
      @on-msg? \ready
    setTimeout @run, @delay
  run: !~>
    if not @api-client
      request "https://#{@domain}hackpad.com/ep/pad/static/#{@id}" @get
    else
      @api-client.export @id, \latest, \txt, @get-by-api

module.exports = Padnews
