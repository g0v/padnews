require! <[request ent deep-diff moment]>

class Padnews
  pad-zero = -> if it.length is 1 then "0#it" else it
  regex =
    date:     /^\s*(\d?\d)\s*月\s*(\d?\d)\s*日\s*$/
    splitter: /(<\/p>|<p>)/
    tags:     /<[^<]*>/gi
    entry:    /^\s*(\d?\d:\S\S)\s*(?:\[\s*([^\[]*)\s*\])?\s*(.+)\s*/
    newline:  /\r?\n/
  (@id, @domain, @api-client) ->
    @domain = if @domain then "#{domain}." else ''
    @delay = 5000
    @prev = []
    @news = []
    @year = new Date!getFullYear!
  get-by-api: (err, data) !~> @get err, null, data
  get: (err, res, body) !~>
    return if err or res.statusCode isnt 200
    @prev = @news
    @news = []
    var last
    for line in body.split regex.splitter
      # clean up
      line .= replace regex.tags, ''
      line = ent.decode line
      # is this line a date?
      date = regex.date.exec line
      if date
        for entry in @news
          if not entry.month and not entry.date
            entry <<< month: date.1, date: date.2
            entry.possible-timestamp = moment "#{@year}-#{pad-zero entry.month}-#{pad-zero entry.date}T#{entry.time}" .unix!
        continue
      # is this line a news entry?
      news = regex.entry.exec line
      if news
        last :=
          month:         null
          date:          null
          time:          if news.1.length is 4 then "0#{news.1}" else news.1
          location:      news.2 or ''
          content:       [news.3]
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
