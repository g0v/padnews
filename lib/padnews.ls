require! <[request split diff]>

class Padnews
  (@id) ->
    @news = []
  separator: /(\r?\n|<\/p>|<p>)/
  match: /\s*(\d\d:\d\d)\s*(?:\[\s*(.+)\s*\])?\s*(.+)\s*/
  get: (cb) ->
    result = []
    request
      .get "https://g0v.hackpad.com/ep/pad/static/#{@id}"
      .pipe split @separator
      .on \data ~>
        news = @match.exec it
        if news
          result.push do
            time:     news.1
            location: news.2
            content:  news.3
      .on \end ->
        cb? result.reverse!
  run: (delay, on-create, on-update) !->
    do update = ~>
      news <~ @get
      for current in news
        updated = false
        found   = false
        for prev in @news
          if current.time is prev.time and current.location is prev.location
            parts = diff.diffChars current.content, prev.content
            if parts.length is 1
              found = true
              break
            count = 0
            for part in parts
              if (part.added or part.removed)
                count += part.value.length
            if count < 5
              updated = true
              prev.content = current.content
              on-update? current, parts
              break
        if not found and not updated
          @news.push current
          on-create? current
      setTimeout update, delay

module.exports = Padnews
