defmodule B2 do
  require Logger

  defp auth_headers(account) do
    [{"Authorization", account["authorizationToken"]}]
  end

  def authorize_account!() do
    account_id = Application.fetch_env!(:wacha, :b2_account_id)
    application_key = Application.fetch_env!(:wacha, :b2_application_key)

    url = "https://api.backblaze.com/b2api/v1/b2_authorize_account"
    auth = :base64.encode("#{account_id}:#{application_key}")
    headers = [{"Authorization", "Basic " <> auth}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        throw "Not found #{status_code}"
      {:error, %HTTPoison.Error{reason: reason}} ->
        throw reason
    end
  end

  defp get_upload_url!(account) do
    url = account["apiUrl"] <> "/b2api/v1/b2_get_upload_url"
    headers = auth_headers(account)

    bucket_id = Application.fetch_env!(:wacha, :b2_bucket_id)
    json = Poison.encode!(%{"bucketId" => bucket_id})

    case HTTPoison.post(url, json, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        throw "Not found. #{status_code}"
      {:error, %HTTPoison.Error{reason: reason}} ->
        throw reason
    end
  end

  # account can be obtained from authorize_account!()
  def upload!(account, content, content_type, photo_id) do
    case get_upload_url!(account) do
      nil -> nil
      resp ->
        url = resp["uploadUrl"]
        Logger.info url

        headers = [{"Authorization", resp["authorizationToken"]},
                   {"Content-Type", content_type},
                   {"Content-Length", byte_size(content)},
                   {"X-Bz-File-Name", photo_id},
                   {"X-Bz-Content-Sha1", :crypto.hash(:sha, content) |> Base.encode16}]
        Logger.info "#{inspect headers}"

        case HTTPoison.post(url, content, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            Poison.decode!(body)
          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            throw "Not found. #{status_code}. #{body}"
          {:error, %HTTPoison.Error{reason: reason}} ->
            throw reason
        end
    end
  end
end
