defmodule Mafia.Coherence.ViewHelpers do
  @moduledoc """
  Helper functions for Coherence Views.
  """
  use Phoenix.HTML
  alias Coherence.Config

  @seperator {:safe, "&nbsp; | &nbsp;"}
  @helpers Module.concat(Application.get_env(:coherence, :module), Router.Helpers)

  @recover_link  "I forgot my password"
  @unlock_link   "Send an unlock email"
  @register_link "I'm new here"
  @invite_link   "Invite Someone"
  @confirm_link  "Resend confirmation email"
  @signin_link   "Sign in"
  @signout_link  "Sign out"

  @doc """
  Create coherence template links.

  Generates links if the appropriate option is installed.

  ## Examples

      coherence_links(conn, :new_session)
      Generates: #{@recover_link}  #{@unlock_link} #{@register_link} #{@confirm_link}

      coherence_links(conn, :new_session, recover: "Password reset", register: false
      Generates: Password reset  #{@unlock_link}

      coherence_links(conn, :layout)             # when logged in
      Generates: User's Name  #{@signout_link}

      coherence_links(conn, :layout)             # when not logged in
      Generates: #{@register_link}  #{@signin_link}

  """
  def coherence_links(conn, which, opts \\ [])
  def coherence_links(conn, :new_session, opts) do
    recover_link  = Keyword.get opts, :recover, @recover_link
    unlock_link   = Keyword.get opts, :unlock, @unlock_link
    register_link = Keyword.get opts, :register, @register_link
    confirm_link  = Keyword.get opts, :confirm, @confirm_link

    user_schema = Coherence.Config.user_schema
    [
      register_link(conn, user_schema, register_link),
      recover_link(conn, user_schema, recover_link),
      unlock_link(conn, user_schema, unlock_link),
      confirmation_link(conn, user_schema, confirm_link)
    ]
    |> List.flatten
  end

  def coherence_links(conn, :layout, opts) do
    signout_class = Keyword.get opts, :signout_class, "navbar-form"
    signin        = Keyword.get opts, :signin, @signin_link
    signout       = Keyword.get opts, :signout, @signout_link
    register      = Keyword.get opts, :register, @register_link

    if Coherence.logged_in?(conn) do
      current_user = Coherence.current_user(conn)
      [
        profile_link(current_user, conn),
        link(signout, to: coherence_path(@helpers, :session_path, conn, :delete), method: :delete, class: signout_class)
      ]
    else
      if Config.has_option(:registerable) && register do
        [link(register, to: coherence_path(@helpers, :registration_path, conn, :new)), signin_link(conn, signin)]
      else
        signin_link(conn, signin)
      end
    end
  end

  def signin_link(conn, label) do
    link(label, to: coherence_path(@helpers, :session_path, conn, :new))   
  end

  @doc """
  Helper to avoid compile warnings when options are disabled.
  """
  def coherence_path(module, route_name, conn, action) do
    apply(module, route_name, [conn, action])
  end
  def coherence_path(module, route_name, conn, action, opts) do
    apply(module, route_name, [conn, action, opts])
  end

  defp concat([], acc), do: Enum.reverse(acc)
  defp concat([h|t], []), do: concat(t, [h])
  defp concat([h|t], acc), do: concat(t, [h, @seperator | acc])

  def recover_link(_conn, _user_schema, false), do: []
  def recover_link(conn, user_schema, text) do
    if user_schema.recoverable?, do: [recover_link(conn, text)], else: []
  end
  def recover_link(conn, text \\ @recover_link), do:
    link(text, to: coherence_path(@helpers, :password_path, conn, :new))

  def register_link(_conn, _user_schema, false), do: []
  def register_link(conn, user_schema, text) do
    if user_schema.registerable?, do: [register_link(conn, text)], else: []
  end
  def register_link(conn, text \\ @register_link), do:
    link(text, to: coherence_path(@helpers, :registration_path, conn, :new))

  def unlock_link(_conn, _user_schema, false), do: []
  def unlock_link(conn, _user_schema, text) do
    if conn.assigns[:locked], do: [unlock_link(conn, text)], else: []
  end
  def unlock_link(conn, text \\ @unlock_link), do:
    link(text, to: coherence_path(@helpers, :unlock_path, conn, :new))

  def invitation_link(conn, text \\ @invite_link) do
    link text, to: coherence_path(@helpers, :invitation_path, conn, :new)
  end

  def confirmation_link(_conn, _user_schema, false), do: []
  def confirmation_link(conn, user_schema, text) do
    if user_schema.confirmable?, do: [confirmation_link(conn, text)], else: []
  end
  def confirmation_link(conn, text \\ @confirm_link) do
    link(text, to: coherence_path(@helpers, :confirmation_path, conn, :new))
  end

  def required_label(f, name, opts \\ []) do
    label f, name, opts do
      "#{if name == :name, do: "Username", else: humanize(name)}\n"
    end
  end

  defp profile_link(current_user, conn) do
    if Config.user_schema.registerable? do
      link current_user.name, to: coherence_path(@helpers, :registration_path, conn, :show, current_user.id)
    else
      current_user.name
    end
  end
end