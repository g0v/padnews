require! <[request split deep-diff]>

class Padnews
  (@id) ->
    @news = []
  separator: /(\r?\n|<\/p>|<p>)/
  match: /\s*(\d?\d:\S\S)\s*(?:\[\s*(.+)\s*\])?\s*(.+)\s*/
  get: (cb) ->
    var last
    result = []
    request
      .get "https://g0v.hackpad.com/ep/pad/static/#{@id}"
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
    do update-loop = ~>
      news <~ @get
      new-entries = []
      for i, current of news
        prev = @news[i]
        if prev
          var content
          ds = deep-diff.diff current, prev
          continue if not ds
          prev <<< current
          on-msg? \update, current, ds
          break
        else
          new-entries.push current
          on-msg? \create current
      Array.prototype.push.apply @news, new-entries
      setTimeout update-loop, delay

module.exports = Padnews
