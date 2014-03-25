require! <[request split deep-diff]>

class Padnews
  (@id, @domain) ->
    @domain = if @domain then "#{domain}." else ''
    @prev = []
    @news = []
  get: (err, res, body) !~>
    return if err or res.statusCode isnt 200
    @prev = @news
    @news = []
    var last
    for line in body.split /(<\/p>|<p>)/
      line .= replace /&nbsp;/gi ' '
      line .= replace /<[^<]*>/gi ''
      news = /^\s*(\d?\d:\S\S)\s*(?:\[\s*([^\[]*)\s*\])?\s*(.+)\s*/.exec line
      if news
        last :=
          time:     news.1
          location: news.2 or ''
          content:  [news.3]
        @news.push last
      else if line.length and not /\r?\n/.test line
        last?content.push line
    @news.reverse!
  run: (delay, on-msg) !->
    do update-loop = ~>
      request "https://#{@domain}hackpad.com/ep/pad/static/#{@id}" @get
      if @prev.length
        for i til @news.length
          current = @news[i]
          prev    = @prev[i]
          if prev
            ds = deep-diff.diff current, prev
            continue if not ds
            on-msg?call this, \update, current, i, ds
          else
            on-msg?call this, \create current, i
        for i from @prev.length-1 to @news.length by -1
          prev = @prev[i]
          on-msg?call this, \remove, prev, i
      else if @news.length
        on-msg?call this, \ready
      setTimeout update-loop, delay

module.exports = Padnews
