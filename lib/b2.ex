defmodule B2 do
  @bucket Application.get_env(:wacha, :b2_bucket)
  @base_url Application.get_env(:wacha, :b2_bucket_auth_token)
  @account_id Application.get_env(:wacha, :b2_account_id)
  @application_key Application.get_env(:wacha, :b2_application_key)

  def authorize_account() do
    url = "https://api.backblaze.com/b2api/v1/b2_authorize_account"
    auth = :base64.encode(@account_id <> ":" <> @application_key)
    headers = [{"Authorization", "Basic " <> auth}]
    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        IO.puts "Not found"
        IO.puts status_code
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        nil
    end
  end
end
