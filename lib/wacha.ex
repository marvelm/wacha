defmodule Wacha do
  use Application
  require Logger

  @timeout 60000

  defp handle_event(
    %{"chat_message" =>
      %{"message_content" =>
        %{"attachment" => attachments}}}) do
    for attachment <- attachments do
      photo = attachment["embed_item"]["embeds.PlusPhoto.plus_photo"]
      :poolboy.transaction(Archiver, fn worker ->
        Logger.info photo["photo_id"]
        GenServer.call(worker, {:archive_photo, photo})
      end, @timeout)
    end
  end
  
  defp handle_event(event) do
    Logger.debug "#{inspect event}"
  end

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    account = B2.authorize_account!()
    children = [
      :poolboy.child_spec(:archiver, [
        name: {:local, Archiver},
        worker_module: Archiver,
        size: 3,
        max_overflow: 2
      ], [account]),

      worker(Task, [fn ->
        conversation_id = Application.get_env(:wacha, :conversation_id)
        Hangouts.parse_events(conversation_id)
          |> Enum.each(&(handle_event(&1)))
      end])
    ]

    opts = [strategy: :one_for_one, name: Wacha.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
