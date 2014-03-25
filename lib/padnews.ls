require! <[request split deep-diff]>

class Padnews
  (@id, @domain) ->
    @domain = if @domain then "#{domain}." else ''
    @news = []
  get: (cb) !->
    var last
    result = []
    request
      .get "https://#{@domain}hackpad.com/ep/pad/static/#{@id}"
      .pipe split /(<\/p>|<p>)/
      .on \data !->
        it .= replace /&nbsp;/gi ' '
        it .= replace /<[^<]*>/gi ''
        news = /^\s*(\d?\d:\S\S)\s*(?:\[\s*([^\[]*)\s*\])?\s*(.+)\s*/.exec it
        if news
          last :=
            time:     news.1
            location: news.2 or ''
            content:  [news.3]
          result.push last
        else if it.length and not /\r?\n/.test it
          last?content.push it
      .on \end !->
        cb? result.reverse!
  run: (delay, on-msg) !->
    update-news = (news) ~>
      if @news.length
        for i til news.length
          current = news[i]
          prev    = @news[i]
          if prev
            ds = deep-diff.diff current, prev
            continue if not ds
            on-msg?call this, \update, current, i, ds
          else
            on-msg?call this, \create current, i
        for i from @news.length-1 to news.length by -1
          prev = @news[i]
          on-msg?call this, \remove, prev, i
        @news = news
      else if news.length
        @news = news
        on-msg?call this, \ready
    do update-loop = ~>
      @get update-news
      setTimeout update-loop, delay

module.exports = Padnews
