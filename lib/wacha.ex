defmodule Wacha do
  use Application
  require Logger

  def listen(account) do
    receive do
      {:event,
       %{"chat_message" =>
          %{"message_content" =>
             %{"attachment" => attachments}}}} ->
        for attachment <- attachments do
          photo = attachment["embed_item"]["embeds.PlusPhoto.plus_photo"]
          mirror(account, photo)
          Logger.info photo["photo_id"]
        end
    end
    listen(account)
  end

  def mirror(account, photo) do
    case HTTPoison.get(photo["original_content_url"]) do
      {:ok, %HTTPoison.Response{
          status_code: 200, body: body, headers: headers}} ->
        {_, content_type} = Enum.find(
          headers,
          fn
            ({"Content-Type", _}) -> true
            (_) -> false
          end)
        Logger.info content_type

        # {_, content_disposition} = Enum.find(
        #   headers,
        #   fn
        #     ({"Content-Disposition", _}) -> true
        #     (_) -> false
        #   end)
        # Logger.info content_disposition

        # [_, file_name] = Regex.run(~r/inline;filename="(.+)"/,
        #                            content_disposition)
        # Logger.info file_name

        #upload(account, content, content_type, file_name, photo_id) do
        photo_id = photo["photo_id"]
        B2.upload(account, body, content_type, photo_id)
    end
  end

  def start(_type, _args) do
    Task.start(fn ->
      conversation = Application.get_env(:wacha, :conversation_id)
      spawn_link(Hangout, :parse_events, [self, conversation])
      listen(B2.authorize_account)
    end)
  end
end
