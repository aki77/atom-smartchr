# smartchr package

Insert several candidates with a single key

![A screenshot of your package](http://i.gyazo.com/d65638fee9e3854443b4846287f5d9b0.gif)

Inspired by [smartchr.el](https://github.com/imakado/emacs-smartchr/).

## Settings

edit `~/.atom/config.cson`

```coffeescript
'*':
  'smartchr':
    'scopeBlacklist': ['comment.*', 'string.*']
'.source.coffee':
  'smartchr':
    'chrs': [
      {
        chr: '=',
        candidates: [' = ', ' == ', '=']
      }
      {
        chr: '>',
        candidates: [' -> ', ' => ', ' > ', ' >= ', '>']
      }
      {
        chr: '<',
        candidates: [' < ', ' <= ', '<']
      }
      {
        chr: ',',
        candidates: [', ', ',']
      }
      {
        chr: '+',
        candidates: [' + ', '+']
      }
      {
        chr: '-',
        candidates: [' - ', '-']
      }
      {
        chr: '&',
        candidates: [' && ', '&']
      }
      {
        chr: '|',
        candidates: [' || ', '|']
      }
    ]
```
