defmodule B2 do
  @bucket_id Application.get_env(:wacha, :b2_bucket_id)
  @account_id Application.get_env(:wacha, :b2_account_id)
  @application_key Application.get_env(:wacha, :b2_application_key)

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
        IO.puts "Not found"
        IO.puts status_code
        nil
      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect reason
        nil
    end
  end

  defp get_upload_url(account) do
    url = account["apiUrl"] <> "/b2api/v1/b2_get_upload_url"
    json = Poison.encode!(%{"bucketId" => @bucket_id})
    headers = auth_headers(account)

    case HTTPoison.post(url, json, headers) do
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

  # account can be obtained from authorized_account
  def upload(account, content, content_type) do
    case get_upload_url(account) do
      nil -> nil
      resp ->
        url = resp["uploadUrl"]
        headers = [{"Authorization", resp["authorizationToken"]},
                   {"Content-Type", content_type},
                   {"Content-Length", byte_size(content)},
                   {"X-Bz-Content-Sha1", :crypto.hash(:sha, content)}]
        case HTTPoison.post(url, content, headers) do
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
end
