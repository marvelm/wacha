defmodule Archiver do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def init([account]) do
    {:ok, %{account: account}}
  end

  def handle_call({:archive_photo, photo}, _from, state) do
    case HTTPoison.get(photo["original_content_url"]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body, headers: headers}} ->
        {_, content_type} = Enum.find(
          headers,
          fn
            ({"Content-Type", _}) -> true
            (_) -> false
          end)
        Logger.debug "Content-Type: #{content_type}"

        photo_id = photo["photo_id"]
        B2.upload!(state.account, body, content_type, photo_id)
    end

    {:reply, nil, state}
  end
end
