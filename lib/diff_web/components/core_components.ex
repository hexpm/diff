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
    <nav class="bg-grey-900 w-full font-sans">
      <div class="max-w-7xl mx-auto px-4 lg:px-8">
        <div class="flex items-center h-[72px] gap-8">

          <a href="/" class="shrink-0 flex items-center gap-3">
            <img src="/images/hexdiff.svg" alt="hexdiff" class="h-8 w-auto" />
          </a>

          <%= if @package do %>
            <.diff_breadcrumb package={@package} from={@from} to={@to} />
          <% end %>

          <div class="flex items-center gap-2 ml-auto">
            <.nav_link href="https://hex.pm">hex.pm</.nav_link>
            <.nav_icon_link href="https://github.com/hexpm/diff" label="GitHub">
              <.github_icon class="h-5 w-5" />
            </.nav_icon_link>
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
        class="shrink-0 flex items-center gap-1.5 px-2 py-1 rounded-md text-grey-400 hover:text-white hover:bg-grey-700 text-xs font-medium transition-colors"
        aria-label="Back to search"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" class="h-3.5 w-3.5" aria-hidden="true">
          <path fill-rule="evenodd" d="M14 8a.75.75 0 0 1-.75.75H4.56l3.22 3.22a.75.75 0 1 1-1.06 1.06l-4.5-4.5a.75.75 0 0 1 0-1.06l4.5-4.5a.75.75 0 0 1 1.06 1.06L4.56 7.25h8.69A.75.75 0 0 1 14 8Z" clip-rule="evenodd" />
        </svg>
        Search
      </a>

      <div class="h-4 w-px bg-grey-700 shrink-0"></div>

      <div class="flex items-center gap-2 min-w-0 overflow-hidden">
        <span class="shrink-0 text-xs font-medium text-grey-500 uppercase tracking-wider">diff</span>
        <span class="text-primary-300 font-mono text-sm font-semibold truncate"><%= @package %></span>
        <div class="shrink-0 flex items-center gap-1.5 font-mono text-xs">
          <span class="px-1.5 py-0.5 rounded bg-grey-800 text-grey-300"><%= @from %></span>
          <span class="text-grey-600">&rarr;</span>
          <span class="px-1.5 py-0.5 rounded bg-primary-900 text-primary-300"><%= @to %></span>
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
  Renders an icon-only link in the navbar style.
  """
  attr :href, :string, required: true
  attr :label, :string, required: true
  slot :inner_block, required: true

  def nav_icon_link(assigns) do
    ~H"""
    <a
      href={@href}
      class="p-1.5 rounded-md text-grey-300 hover:text-white hover:bg-grey-700 transition-colors"
      aria-label={@label}
    ><%= render_slot(@inner_block) %></a>
    """
  end

  @doc """
  Renders the site footer.
  """
  def footer(assigns) do
    ~H"""
    <footer class="bg-grey-900 text-grey-300 mt-auto">
      <div class="max-w-7xl mx-auto px-4 lg:px-8 py-10">
        <div class="grid grid-cols-2 md:grid-cols-4 gap-8">

          <.footer_section title="About Hex">
            <.footer_link href="https://hex.pm/about">About</.footer_link>
            <.footer_link href="https://hex.pm/blog">Blog</.footer_link>
            <.footer_link href="https://hex.pm/sponsors">Sponsors</.footer_link>
            <.footer_link href="https://github.com/hexpm">GitHub</.footer_link>
            <.footer_link href="https://twitter.com/hexpm">Twitter</.footer_link>
          </.footer_section>

          <.footer_section title="Help">
            <.footer_link href="https://hex.pm/docs">Documentation</.footer_link>
            <.footer_link href="https://github.com/hexpm/specifications">Specifications</.footer_link>
            <.footer_link href="https://github.com/hexpm/hex/issues">Report Client Issue</.footer_link>
            <.footer_link href="https://github.com/hexpm/hexpm/issues">Report General Issue</.footer_link>
            <.footer_link href="mailto:support@hex.pm">Contact Support</.footer_link>
          </.footer_section>

          <.footer_section title="Policies">
            <.footer_link href="https://hex.pm/policies/codeofconduct">Code of Conduct</.footer_link>
            <.footer_link href="https://hex.pm/policies/termsofservice">Terms of Service</.footer_link>
            <.footer_link href="https://hex.pm/policies/privacy">Privacy Policy</.footer_link>
            <.footer_link href="https://hex.pm/policies/copyright">Copyright Policy</.footer_link>
            <.footer_link href="https://hex.pm/policies/dispute">Dispute Policy</.footer_link>
          </.footer_section>

          <div class="text-sm">
            <p class="text-grey-400"><%= Date.utc_today().year %> &copy; Six Colors AB.</p>
            <p class="mt-2 text-grey-500">
              Powered by the <a href="https://www.erlang.org/" class="hover:text-white transition-colors">Erlang VM</a>
              and <a href="https://elixir-lang.org/" class="hover:text-white transition-colors">Elixir</a>.
            </p>
          </div>

        </div>
      </div>
    </footer>
    """
  end

  @doc """
  Renders a titled section in the footer with a list of links.
  """
  attr :title, :string, required: true
  slot :inner_block, required: true

  def footer_section(assigns) do
    ~H"""
    <div>
      <h4 class="text-white text-sm font-semibold mb-3 uppercase tracking-wider"><%= @title %></h4>
      <ul class="space-y-2 text-sm">
        <%= render_slot(@inner_block) %>
      </ul>
    </div>
    """
  end

  @doc """
  Renders a link inside a footer section.
  """
  attr :href, :string, required: true
  slot :inner_block, required: true

  def footer_link(assigns) do
    ~H"""
    <li><a href={@href} class="hover:text-white transition-colors"><%= render_slot(@inner_block) %></a></li>
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
end
