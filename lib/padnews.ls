require! <[request split diff deep-diff]>

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
          updated = false
          continue if current.time is prev.time and current.location is prev.location and current.content is prev.content
          var content
          count = 0
          ds = deep-diff.diff current, prev
          continue if not ds
          for d in ds
            if d.path.0 is \time or d.path.0 is \location
              update = true
              break
            content = d if d.path.0 is \content
            if content
              parts = diff.diffChars content.lhs, content.rhs
              for part in parts
                count += part.value.length if part.added or part.removed
          updated = true if count < 5
          if updated
            prev <<< current
            on-msg? \update, current
            break
        else
          new-entries.push current
          on-msg? \create current
      Array.prototype.push.apply @news, new-entries
      setTimeout update-loop, delay

module.exports = Padnews
