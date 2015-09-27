defmodule CookieAgent do

  @doc """
  Starts a blank cookie.
  """
  def start_link(cookie_string) do
    Agent.start_link(fn -> cookie_string end, name: :cookie)
  end

  @doc """
  Gets the cookie's value
  """
  def get(agent) do
    Agent.get(agent, fn cookie -> cookie end)
  end

  @doc """
  Updates the cookie's value 
  """
  def set(agent, value) do
    IO.puts 'Updating agent with value: #{value}'
    Agent.get_and_update(agent, fn cookie -> {:ok, value} end)
  end
end
