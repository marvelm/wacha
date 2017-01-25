# Wacha

**Back up your Google Hangout conversations**

Wacha takes all the photos shared in a Hangout conversations and uploads them to
Backblaze B2

## Instructions
1. Export your Hangout conversations by visiting https://takeout.google.com
2. Create a bucket on Backblaze B2
3. `git clone https://github.com/marvelm/wacha.git`
4. Create a config file in `wacha/config/secret.exs`
  - The file should look like this:
    ```
    use Mix.Config
    config :wacha,
      b2_bucket_id: "jaksdjaslkdjsa",
      b2_account_id: "asdaksjdskad",
      b2_application_key: "ajsdklasjdklas",
      conversation_id: "asjdkasjdkasd",
      hangouts_json: "/path/to/Hangouts.json"
    ```
5. `mix run --no-halt`
