// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

import { Socket } from 'phoenix'
import { LiveSocket } from "phoenix_live_view"

let liveSocket = new LiveSocket("/live", Socket, {})
liveSocket.connect()

/*
Make it possible to click line numbers to update the address bar to a
link directly to that line.
*/
if (location.hash) {
  document.getElementById(location.hash.replace('#', '')).classList.add('selected')
}

const lines = document.querySelectorAll('.ghd-line-number')
lines.forEach(line => {
  line.addEventListener('click', e => {
    const parent = line.parentNode

    if (parent && parent.id) {
      document.querySelectorAll('.ghd-line.selected').forEach(line => {
        line.classList.remove('selected')
      })

      parent.classList.add('selected')

      history.replaceState(null, null, '#' + parent.id)
    }
  })
})

const fileHeaders = document.querySelectorAll('.ghd-file-header')
fileHeaders.forEach(header => {
  header.addEventListener('click', e => {
    const parent = header.parentNode

    parent.querySelectorAll('.ghd-diff').forEach(diff => {
      diff.classList.toggle('hidden')
    })
    header.classList.toggle('collapsed') && scrollIfNeeded(header)
  })
})

const scrollIfNeeded = elem => {
  elem.getBoundingClientRect().top < 0 && elem.scrollIntoView(true)
}

const MAX_EXPAND_CONTEXT_LINES = 20

document.addEventListener('DOMContentLoaded', e => {
  document.querySelectorAll('.ghd-expand-up').forEach(expandUp => {
    expandUp.addEventListener('click', e => {
      const {fileName, packageName, version, lineAfter, lineBefore, patch} = gatherInfo(expandUp)

      // expandUp always follows by diff line.. so we take the number
      const toLine = numberFrom(lineAfter) - 1

      const _fromLine = lineBefore ? numberFrom(lineBefore) + 1 : 1
      const fromLine = Math.max(toLine - MAX_EXPAND_CONTEXT_LINES, _fromLine)

      const _rightLine = lineBefore ? numberTo(lineBefore) + 1 : 1
      const rightLine = Math.max(toLine - MAX_EXPAND_CONTEXT_LINES, _rightLine)

      fetchChunkAndInsert({target: lineAfter, packageName, version, fromLine, toLine, rightLine, fileName, patch})
    })
  })

  document.querySelectorAll('.ghd-expand-down').forEach(expandDown => {
    expandDown.addEventListener('click', e => {
      const {fileName, packageName, version, lineAfter, lineBefore, patch} = gatherInfo(expandDown)

      const fromLine = numberFrom(lineBefore) + 1
      const rightLine = numberTo(lineBefore) + 1

      const _toLine = lineAfter ? numberFrom(lineAfter) - 1 : Infinity
      const toLine = Math.min(fromLine + MAX_EXPAND_CONTEXT_LINES, _toLine)

      fetchChunkAndInsert({target: expandDown.closest('tr'), packageName, version, fromLine, toLine, rightLine, fileName, patch})

    })
  })
})

const numberFrom = line => parseInt(line.querySelector('.ghd-line-number .ghd-line-number-from').textContent.trim())
const numberTo = line => parseInt(line.querySelector('.ghd-line-number .ghd-line-number-to').textContent.trim())

const gatherInfo = line => {
  const patch = line.closest('.ghd-file')
  const {fileName, packageName, version} = patch.querySelector('.ghd-file-header').dataset

  const lineAfter = line.closest('tr').nextElementSibling
  const lineBefore = line.closest('tr').previousElementSibling

  return {fileName, packageName, version, lineAfter, lineBefore, patch}
}

const fetchChunkAndInsert = params => {
  if( !(params.fromLine && params.toLine) ||
      (params.fromLine >= params.toLine) ){
    return
  }

  const path = `/diff/${params.packageName}/${params.version}/expand/${params.fromLine}/${params.toLine}/${params.rightLine}`
  const url = new URL(path, window.location)
  url.searchParams.append('file_name', params.fileName)

  fetch(url)
  .then(response => response.json())
  .then(({chunk, lines, errors}) => {
    if(errors){return}
    const context = document.createElement('template')
    context.innerHTML = chunk.trim()
    const patchBody = params.patch.querySelector('tbody')

    Array.prototype.reduceRight.call(context.content.childNodes, (target, line) => {
      return patchBody.insertBefore(line, target)
    }, params.target)
  })
  .catch(console.error)
}
