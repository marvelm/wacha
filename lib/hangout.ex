defmodule Hangouts do
  require Logger

  def parse_events(conversation_id) do
    Logger.debug "Parsing json"
    raw = File.read!("Hangouts.json")
    data = Poison.Parser.parse!(raw)

    data = data["conversation_state"] |>
      Enum.find(fn convo ->
        convo["conversation_id"]["id"] == conversation_id
      end)

    if is_nil(data) do
      Logger.info "Conversation not found: #{conversation_id}"
    else
      Logger.debug "Conversation found: #{conversation_id}"
    end

    data["conversation_state"]["event"]
  end
end
