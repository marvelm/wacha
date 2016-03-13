defmodule B2 do
  require Logger

  @bucket_id Application.get_env(:wacha, :b2_bucket_id)
  @account_id Application.get_env(:wacha, :b2_account_id)
  @application_key Application.get_env(:wacha, :b2_application_key)

  @upload_url_json Poison.encode!(%{"bucketId" => @bucket_id})

  defp auth_headers(account) do
    [{"Authorization", account["authorizationToken"]}]
  end

  def authorize_account do
    url = "https://api.backblaze.com/b2api/v1/b2_authorize_account"
    auth = :base64.encode("#{@account_id}:#{@application_key}")
    headers = [{"Authorization", "Basic " <> auth}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error "Not found #{status_code}"
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error "#{inspect reason}"
        nil
    end
  end

  defp get_upload_url(account) do
    url = account["apiUrl"] <> "/b2api/v1/b2_get_upload_url"
    headers = auth_headers(account)

    case HTTPoison.post(url, @upload_url_json, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        Poison.decode!(body)
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        Logger.error("Not found. #{status_code}")
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error "#{inspect reason}"
        nil
    end
  end

  # account can be obtained from authorize_account
  def upload(account, content, content_type, photo_id) do
    case get_upload_url(account) do
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
            Logger.error("Not found. #{status_code}. #{body}")
            nil
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.error "#{inspect reason}"
            nil
        end
    end
  end
end
