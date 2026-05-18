defmodule DiffWeb.CoreComponents do
  use Phoenix.Component

  @doc """
  Renders the main navbar.
  """
  attr :package, :string, default: nil
  attr :from, :string, default: nil
  attr :to, :string, default: nil

  def navbar(assigns) do
    ~H"""
    <nav class="bg-grey-800 w-full font-sans">
      <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="flex items-center h-[72px] gap-8">

          <a href="/" class="shrink-0 flex items-center gap-3">
            <img src="/images/hex-full.svg" alt="hex logo" class="h-8 w-auto" />
            <span class="text-white text-2xl tracking-tight"><span class="font-bold">hex</span>diff</span>
          </a>

          <%= if @package do %>
            <.diff_breadcrumb package={@package} from={@from} to={@to} />
          <% end %>

          <div class="flex items-center gap-2 ml-auto">
            <.nav_link href="https://hex.pm">hex.pm</.nav_link>
            <.theme_toggle />
          </div>

        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Renders the diff breadcrumb shown in the navbar when viewing a diff.
  """
  attr :package, :string, required: true
  attr :from, :string, required: true
  attr :to, :string, required: true

  def diff_breadcrumb(assigns) do
    ~H"""
    <div class="flex items-center gap-3 min-w-0">
      <a
        href="/"
        class="shrink-0 flex items-center gap-1.5 px-2 py-1 rounded-md text-grey-200 hover:text-white hover:bg-grey-700 text-xs font-medium transition-colors"
        aria-label="Back to search"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="h-3.5 w-3.5" aria-hidden="true">
          <path fill-rule="evenodd" d="M14 8a.75.75 0 0 1-.75.75H4.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L4.56 7.25h8.69A.75.75 0 0 1 14 8Z" clip-rule="evenodd" />
        </svg>
        Search
      </a>

      <div class="h-4 w-px bg-grey-600 shrink-0"></div>

      <div class="flex items-center gap-2 min-w-0 overflow-hidden">
        <span class="shrink-0 text-xs font-medium text-grey-400 uppercase tracking-wider">diff</span>
        <span class="text-primary-100 font-mono text-sm font-semibold truncate"><%= @package %></span>
        <div class="shrink-0 flex items-center gap-1.5 font-mono text-xs">
          <span class="px-1.5 py-0.5 rounded bg-grey-800 text-grey-200"><%= @from %></span>
          <span class="text-grey-300">&rarr;</span>
          <span class="px-1.5 py-0.5 rounded bg-primary-900 text-primary-200"><%= @to %></span>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a text link in the navbar style.
  """
  attr :href, :string, required: true
  slot :inner_block, required: true

  def nav_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="px-3 py-1.5 rounded-md text-grey-300 hover:text-white hover:bg-grey-700 text-sm font-medium transition-colors"
    ><%= render_slot(@inner_block) %></a>
    """
  end

  @doc """
  Renders the theme toggle button with a light/dark/system dropdown.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex items-center">
      <button
        type="button"
        data-theme-toggle
        class="inline-flex items-center justify-center h-9 w-9 text-grey-300 hover:text-white transition-colors cursor-pointer rounded-md hover:bg-grey-700"
        aria-label="Change theme"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <span class="sr-only">Change color theme</span>
        <span data-theme-icon="light">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-5 w-5" aria-hidden="true">
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2" />
            <path d="M12 20v2" />
            <path d="m4.93 4.93 1.41 1.41" />
            <path d="m17.66 17.66 1.41 1.41" />
            <path d="M2 12h2" />
            <path d="M20 12h2" />
            <path d="m6.34 17.66-1.41 1.41" />
            <path d="m19.07 4.93-1.41 1.41" />
          </svg>
        </span>
        <span data-theme-icon="dark">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-5 w-5" aria-hidden="true">
            <path fill-rule="evenodd" d="M9.528 1.718a.75.75 0 0 1 .162.819A8.97 8.97 0 0 0 9 6a9 9 0 0 0 9 9 8.97 8.97 0 0 0 3.463-.69.75.75 0 0 1 .981.98 10.503 10.503 0 0 1-9.694 6.46c-5.799 0-10.5-4.7-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 0 1 .818.162Z" clip-rule="evenodd" />
          </svg>
        </span>
        <span data-theme-icon="system">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-5 w-5" aria-hidden="true">
            <path fill-rule="evenodd" d="M2.25 5.25a3 3 0 0 1 3-3h13.5a3 3 0 0 1 3 3V15a3 3 0 0 1-3 3h-3v.257c0 .597.237 1.17.659 1.591l.621.622a.75.75 0 0 1-.53 1.28h-9a.75.75 0 0 1-.53-1.28l.621-.622a2.25 2.25 0 0 0 .659-1.59V18h-3a3 3 0 0 1-3-3V5.25Zm1.5 0v9.75c0 .83.672 1.5 1.5 1.5h13.5c.828 0 1.5-.672 1.5-1.5V5.25a1.5 1.5 0 0 0-1.5-1.5H5.25a1.5 1.5 0 0 0-1.5 1.5Z" clip-rule="evenodd" />
          </svg>
        </span>
      </button>

      <div
        data-theme-menu
        class="hidden absolute right-0 top-full mt-2 w-36 bg-grey-700 border border-grey-600 rounded-lg shadow-lg py-1 z-50"
      >
        <button
          type="button"
          data-theme-choice="light"
          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-grey-200 hover:bg-grey-600 transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4 shrink-0" aria-hidden="true">
            <circle cx="12" cy="12" r="4" />
            <path d="M12 2v2" />
            <path d="M12 20v2" />
            <path d="m4.93 4.93 1.41 1.41" />
            <path d="m17.66 17.66 1.41 1.41" />
            <path d="M2 12h2" />
            <path d="M20 12h2" />
            <path d="m6.34 17.66-1.41 1.41" />
            <path d="m19.07 4.93-1.41 1.41" />
          </svg>
          Light
        </button>
        <button
          type="button"
          data-theme-choice="dark"
          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-grey-200 hover:bg-grey-600 transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-4 w-4 shrink-0" aria-hidden="true">
            <path fill-rule="evenodd" d="M9.528 1.718a.75.75 0 0 1 .162.819A8.97 8.97 0 0 0 9 6a9 9 0 0 0 9 9 8.97 8.97 0 0 0 3.463-.69.75.75 0 0 1 .981.98 10.503 10.503 0 0 1-9.694 6.46c-5.799 0-10.5-4.7-10.5-10.5 0-4.368 2.667-8.112 6.46-9.694a.75.75 0 0 1 .818.162Z" clip-rule="evenodd" />
          </svg>
          Dark
        </button>
        <button
          type="button"
          data-theme-choice="system"
          class="w-full flex items-center gap-2 px-4 py-2 text-sm text-grey-200 hover:bg-grey-600 transition-colors cursor-pointer"
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="h-4 w-4 shrink-0" aria-hidden="true">
            <path fill-rule="evenodd" d="M2.25 5.25a3 3 0 0 1 3-3h13.5a3 3 0 0 1 3 3V15a3 3 0 0 1-3 3h-3v.257c0 .597.237 1.17.659 1.591l.621.622a.75.75 0 0 1-.53 1.28h-9a.75.75 0 0 1-.53-1.28l.621-.622a2.25 2.25 0 0 0 .659-1.59V18h-3a3 3 0 0 1-3-3V5.25Zm1.5 0v9.75c0 .83.672 1.5 1.5 1.5h13.5c.828 0 1.5-.672 1.5-1.5V5.25a1.5 1.5 0 0 0-1.5-1.5H5.25a1.5 1.5 0 0 0-1.5 1.5Z" clip-rule="evenodd" />
          </svg>
          System
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders the site footer.
  """
  def footer(assigns) do
    ~H"""
    <footer class="bg-grey-800 text-grey-200 font-sans">
      <div class="max-w-7xl mx-auto px-4 pt-12 pb-10 flex flex-col gap-10">
        <div class="flex flex-col gap-10 lg:flex-row lg:items-start lg:gap-24 xl:gap-28">
          <.footer_branding />
          <.footer_links />
        </div>
      </div>
      <.footer_copyright />
    </footer>
    """
  end

  defp footer_branding(assigns) do
    ~H"""
    <div class="flex w-full items-start justify-between gap-6 lg:w-auto lg:flex-col lg:items-start lg:justify-start lg:gap-6">
      <div class="flex items-center gap-3">
        <img src="/images/hex-full.svg" alt="hex logo" class="h-8 w-auto" />
        <span class="text-white text-2xl tracking-tight"><span class="font-bold">hex</span>diff</span>
      </div>
      <.footer_social_links />
    </div>
    """
  end

  defp footer_social_links(assigns) do
    ~H"""
    <div class="flex gap-3 lg:mt-4">
      <.footer_social_link href="https://github.com/hexpm/diff" label="GitHub">
        <.github_icon class="h-4 w-4" />
      </.footer_social_link>
      <.footer_social_link href="https://x.com/hexpm" label="X">
        <.twitter_icon class="h-4 w-4" />
      </.footer_social_link>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  slot :inner_block, required: true

  defp footer_social_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="inline-flex h-10 w-10 items-center justify-center rounded-lg bg-grey-700 text-grey-200 hover:bg-grey-600 transition duration-200"
      target="_blank"
      rel="noopener noreferrer"
      aria-label={@label}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  defp footer_links(assigns) do
    ~H"""
    <div class="flex-1">
      <div class="grid grid-cols-1 gap-y-10 gap-x-12 md:grid-cols-3 lg:gap-x-16 xl:gap-x-24">
        <.footer_link_column>
          <.footer_link href="https://hex.pm/about" label="About" />
          <.footer_link href="https://hex.pm/blog" label="Blog" />
          <.footer_link href="https://hex.pm/sponsors" label="Sponsors" />
          <.footer_link href="https://status.hex.pm" label="Status" external />
        </.footer_link_column>

        <.footer_link_column>
          <.footer_link href="https://hex.pm/docs" label="Documentation" />
          <.footer_link href="https://hex.pm/docs/faq" label="FAQ" />
          <.footer_link href="https://github.com/hexpm/specifications" label="Specifications" external />
          <.footer_link href="https://github.com/hexpm/hex/issues" label="Report Client Issue" external />
          <.footer_link href="https://github.com/hexpm/hexpm/issues" label="Report General Issue" external />
          <.footer_link href="mailto:security@hex.pm" label="Report Security Issue" />
          <.footer_link href="mailto:support@hex.pm" label="Contact Support" />
        </.footer_link_column>

        <.footer_link_column>
          <.footer_link href="https://hex.pm/policies/codeofconduct" label="Code of Conduct" />
          <.footer_link href="https://hex.pm/policies/termsofservice" label="Terms of Service" />
          <.footer_link href="https://hex.pm/policies/privacy" label="Privacy Policy" />
          <.footer_link href="https://hex.pm/policies/copyright" label="Copyright Policy" />
          <.footer_link href="https://hex.pm/policies/dispute" label="Dispute Policy" />
        </.footer_link_column>
      </div>
    </div>
    """
  end

  slot :inner_block, required: true

  defp footer_link_column(assigns) do
    ~H"""
    <div class="flex flex-col gap-3 font-medium leading-4">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :external, :boolean, default: false
  attr :href, :string, required: true
  attr :label, :string, required: true

  defp footer_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="text-grey-200 hover:text-white transition-colors"
      target={if @external, do: "_blank"}
      rel={if @external, do: "noopener noreferrer"}
    >
      <%= @label %>
    </a>
    """
  end

  defp footer_copyright(assigns) do
    ~H"""
    <div class="bg-grey-700">
      <div class="max-w-7xl mx-auto px-4 py-4 flex flex-col items-center gap-3 text-sm text-grey-200 md:flex-row md:justify-between">
        <p class="text-center leading-[14px] md:text-left">
          <%= Date.utc_today().year %> © Six Colors AB.
        </p>
        <p class="text-center leading-[18px] md:text-right">
          Powered by the
          <a href="https://www.erlang.org/" class="underline hover:text-grey-300">Erlang VM</a>
          and the
          <a href="https://elixir-lang.org/" class="underline hover:text-grey-300">Elixir Programming Language</a>
        </p>
      </div>
    </div>
    """
  end

  @doc """
  Renders a GitHub icon.
  """
  attr :class, :string, default: "h-4 w-4"

  def github_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      class={@class}
      aria-hidden="true"
    >
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M12 2C6.477 2 2 6.528 2 12.07c0 4.449 2.865 8.222 6.839 9.558.5.095.683-.219.683-.487 0-.24-.01-1.034-.014-1.876-2.782.609-3.369-1.193-3.369-1.193-.454-1.166-1.11-1.477-1.11-1.477-.908-.625.07-.612.07-.612 1.004.071 1.532 1.045 1.532 1.045.893 1.55 2.341 1.103 2.91.844.091-.656.35-1.103.636-1.357-2.22-.257-4.555-1.117-4.555-4.969 0-1.098.388-1.995 1.025-2.698-.103-.259-.445-1.296.098-2.704 0 0 .84-.27 2.75 1.03A9.517 9.517 0 0 1 12 6.844a9.5 9.5 0 0 1 2.5.341c1.91-1.3 2.749-1.03 2.749-1.03.544 1.408.202 2.445.1 2.704.64.703 1.024 1.6 1.024 2.698 0 3.861-2.339 4.708-4.566 4.961.359.313.678.928.678 1.872 0 1.352-.013 2.442-.013 2.775 0 .27.18.586.688.486C19.138 20.287 22 16.517 22 12.07 22 6.528 17.523 2 12 2Z"
        fill="currentColor"
      />
    </svg>
    """
  end

  @doc """
  Renders a Twitter/X icon.
  """
  attr :class, :string, default: "h-4 w-4"

  def twitter_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      class={@class}
      aria-hidden="true"
    >
      <path
        d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
        fill="currentColor"
      />
    </svg>
    """
  end
end
