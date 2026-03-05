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

// Define hooks for LiveView
window.Hooks = {}

window.Hooks.InfiniteScroll = {
  mounted() {
    this.pending = false

    this.observer = new IntersectionObserver((entries) => {
      const target = entries[0]
      if (target.isIntersecting && !this.pending) {
        this.pending = true
        this.pushEvent("load-more", {})
      }
    }, {
      root: null,
      rootMargin: '100px',
      threshold: 0.1
    })

    this.observer.observe(this.el)
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  },

  updated() {
    this.pending = false

    // Check if we're still at the bottom after loading content
    // Use requestAnimationFrame to ensure DOM has fully updated
    requestAnimationFrame(() => {
      const target = this.el
      const rect = target.getBoundingClientRect()
      const isIntersecting = rect.top <= (window.innerHeight || document.documentElement.clientHeight)

      if (isIntersecting && !this.pending) {
        this.pending = true
        this.pushEvent("load-more", {})
      }
    })
  }
}

window.Hooks.DiffList = {
  mounted() {
    this.el.addEventListener('click', e => {
      const lineNumber = e.target.closest('.ghd-line-number')
      if (!lineNumber) return

      const parent = lineNumber.parentNode
      if (parent && parent.id) {
        this.el.querySelectorAll('.ghd-line.selected').forEach(el => {
          el.classList.remove('selected')
        })
        parent.classList.add('selected')
        history.replaceState(null, null, '#' + parent.id)
      }
    })

    this.selectHash()
  },

  updated() {
    this.selectHash()
  },

  selectHash() {
    if (location.hash) {
      const el = document.getElementById(location.hash.replace('#', ''))
      if (el) {
        this.el.querySelectorAll('.ghd-line.selected').forEach(el => {
          el.classList.remove('selected')
        })
        el.classList.add('selected')
        el.scrollIntoView({ block: 'center' })
      }
    }
  }
}

let liveSocket = new LiveSocket("/live", Socket, { hooks: window.Hooks })
liveSocket.connect()
