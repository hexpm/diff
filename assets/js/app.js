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
