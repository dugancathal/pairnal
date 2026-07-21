require "sinatra/base"
require "json"

module Pairnal
  # Thin Sinatra wrapper around Board -- every route just delegates to it
  # and renders the result as JSON. See board.rb for the actual logic.
  class Server < Sinatra::Base
    set :public_folder, File.expand_path("../../web", __dir__)
    set :server, "puma"
    set :history_path, nil
    set :today, nil
    set :show_exceptions, false
    set :raise_errors, false

    get "/" do
      send_file File.join(settings.public_folder, "index.html")
    end

    get "/api/state" do
      json board.state
    end

    post "/api/suggest" do
      json board.suggest(json_body)
    end

    post "/api/save" do
      json board.save(json_body)
    end

    error do
      json({error: env["sinatra.error"]&.message || "internal error"})
    end

    private

    def board = Board.new(history_path: settings.history_path, today: settings.today)

    def json(payload)
      content_type :json
      payload.to_json
    end

    def json_body
      JSON.parse(request.body.read)
    rescue JSON::ParserError
      {}
    end
  end
end
