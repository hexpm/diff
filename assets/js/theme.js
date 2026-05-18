const THEME_STORAGE_KEY = "hexpm-theme"
const THEME_MEDIA_QUERY = "(prefers-color-scheme: dark)"

function getStoredPreference() {
  try { return window.localStorage.getItem(THEME_STORAGE_KEY) } catch (_e) { return null }
}

function getSystemTheme() {
  return window.matchMedia(THEME_MEDIA_QUERY).matches ? "dark" : "light"
}

function resolveTheme() {
  const pref = getStoredPreference()
  if (pref === "light" || pref === "dark") return pref
  return getSystemTheme()
}

function currentPreference() {
  return getStoredPreference() || "system"
}

function applyTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme)
  document.documentElement.style.colorScheme = theme
  document.documentElement.setAttribute("data-theme-preference", currentPreference())
}

function setPreference(preference) {
  if (preference === "system") {
    try { window.localStorage.removeItem(THEME_STORAGE_KEY) } catch (_e) {}
  } else {
    try { window.localStorage.setItem(THEME_STORAGE_KEY, preference) } catch (_e) {}
  }
  applyTheme(resolveTheme())
}

function closeAllMenus() {
  document.querySelectorAll("[data-theme-menu]").forEach((menu) => {
    menu.classList.add("hidden")
    const toggle = menu.closest("[data-theme-toggle]") || menu.parentElement?.querySelector("[data-theme-toggle]")
    if (toggle) toggle.setAttribute("aria-expanded", "false")
  })
}

export function initializeTheme() {
  applyTheme(resolveTheme())

  document.addEventListener("click", (event) => {
    const toggle = event.target.closest("[data-theme-toggle]")
    if (toggle) {
      event.preventDefault()
      const menu = toggle.parentElement.querySelector("[data-theme-menu]")
      if (menu) {
        const isOpen = !menu.classList.contains("hidden")
        menu.classList.toggle("hidden")
        toggle.setAttribute("aria-expanded", String(!isOpen))
      }
      return
    }

    const choice = event.target.closest("[data-theme-choice]")
    if (choice) {
      event.preventDefault()
      setPreference(choice.getAttribute("data-theme-choice"))
      closeAllMenus()
      return
    }

    closeAllMenus()
  })

  const systemThemeMedia = window.matchMedia(THEME_MEDIA_QUERY)
  const handleSystemThemeChange = (event) => {
    if (getStoredPreference()) return
    applyTheme(event.matches ? "dark" : "light")
  }

  if (typeof systemThemeMedia.addEventListener === "function") {
    systemThemeMedia.addEventListener("change", handleSystemThemeChange)
  } else if (typeof systemThemeMedia.addListener === "function") {
    systemThemeMedia.addListener(handleSystemThemeChange)
  }

  window.addEventListener("storage", (event) => {
    if (event.key !== THEME_STORAGE_KEY) return
    applyTheme(resolveTheme())
  })
}
