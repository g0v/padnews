require! <[request split deep-diff]>

class Padnews
  (@id, @domain) ->
    @domain = if @domain then "#{domain}." else ''
    @news = []
  separator: /(<\/p>|<p>)/
  match: /\s*(\d?\d:\S\S)\s*(?:\[\s*(.+)\s*\])?\s*(.+)\s*/
  get: (cb) ->
    var last
    result = []
    request
      .get "https://#{@domain}hackpad.com/ep/pad/static/#{@id}"
      .pipe split @separator
      .on \data ~>
        news = @match.exec it
        if news
          last :=
            time:     news.1
            location: news.2 or ''
            content:  [news.3]
          result.push last
        else if it.length and not /(\r?\n|^<.*>$)/.test it
          last?content.push it
      .on \end ->
        cb? result.reverse!
  run: (delay, on-msg) !->
    news <~ @get
    @news = news
    on-msg? \ready
    setTimeout update-loop, delay
    do update-loop = ~>
      news <~ @get
      for i, current of news
        prev = @news[i]
        if prev
          ds = deep-diff.diff current, prev
          continue if not ds
          on-msg? \update, current, i, ds
        else
          on-msg? \create current, i
      @news = news
      setTimeout update-loop, delay

module.exports = Padnews
