require "rbconfig"

module Pairnal
  class Cli
    module Commands
      class Serve
        DEFAULT_PORT = 4567

        def initialize(history_path, today: Date.today)
          @history_path = history_path
          @today = today
        end

        def call(args = [], output: $stdout)
          port = parse_port(args) || DEFAULT_PORT
          url = "http://127.0.0.1:#{port}"

          Pairnal::Server.set(history_path: @history_path, today: @today)

          Thread.new do
            sleep 0.5
            output.puts "Pairnal board running at #{url} (Ctrl-C to stop)"
            open_browser(url)
          end

          Pairnal::Server.run!(port:, bind: "127.0.0.1")
        end

        private

        def parse_port(args)
          idx = args.index("--port")
          return nil unless idx

          args[idx + 1]&.to_i
        end

        def open_browser(url)
          opener = case RbConfig::CONFIG["host_os"]
          when /darwin/ then "open"
          when /linux|bsd/ then "xdg-open"
          when /mswin|mingw|cygwin/ then "start"
          end
          system(opener, url, out: File::NULL, err: File::NULL) if opener
        rescue StandardError
          nil
        end
      end
    end
  end
end
