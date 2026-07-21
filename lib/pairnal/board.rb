module Pairnal
  # The drag-and-drop board's read/suggest/save logic, kept independent of
  # how it's served over HTTP. Every call re-reads the history file from
  # disk -- the board's "who's dragged where" state lives entirely in the
  # browser; this only ever sees it when the page asks for a suggestion or
  # asks to save.
  class Board
    def initialize(history_path:, today: Date.today, output: $stdout)
      @history_path = history_path
      @today = today
      @output = output
    end

    def state
      history = load_history
      roster = history.roster
      recommender = Recommender.new(history, today: @today)
      members = roster.members
      previous_groups = last_session_groups(history)

      {
        today: @today.iso8601,
        displayNames: members.to_h { |m| [m.to_s, roster.display_name(m)] },
        streams: history.stream_partitions.map { |s| stream_payload(s, previous_groups) },
        staleness: members.combination(2).to_h { |a, b| [staleness_key(a, b), pairing_info(recommender, a, b)] }
      }
    end

    # `groups` is whatever's currently on the board for one stream: some
    # already-paired-off (2+ people, treated as a fixed group to keep),
    # some with just one person dragged in so far (an anchor -- give them a
    # partner), the rest of the stream fills in around those.
    def suggest(params)
      history = load_history
      stream = history.stream_partitions.find { |s| s.name == params["stream"] }
      return {error: "unknown stream"} unless stream

      groups = symbolize_groups(params["groups"])
      fixed = groups.select { |g| g.size >= 2 }.map { |g| Group.of(*g) }
      anchors = groups.select { |g| g.size == 1 }

      recommender = Recommender.new(history, today: @today)
      options = recommender.recommend(n: 3, members: stream.members, fixed:, anchors:)
      {options: options.map { |rec| {score: rec.score, groups: rec.allocation.groups.map { |g| g.members.map(&:to_s) }} }}
    end

    # `groups` is every group across every stream's board that has at
    # least one person in it -- saved as a single session for today.
    def save(params)
      history = load_history
      groups = symbolize_groups(params["groups"])
      return {error: "nothing to save"} if groups.empty?

      Cli::Commands::Record.new(history.roster, @history_path).call(groups.map { |g| g.join("+") }, date: @today, output: @output)
      {ok: true}
    rescue ArgumentError => e
      {error: e.message}
    end

    private

    def load_history = History.load_path(@history_path)

    # Seeds each stream's board with whoever was grouped together last time,
    # so pairs stay "sticky" day to day instead of starting from scratch.
    # Groups are filtered down to whichever of their members are still in a
    # given stream today -- if someone's moved streams or left the roster
    # since then, their old groupmate(s) just fall back to available rather
    # than carrying a stale group forward.
    def last_session_groups(history)
      last_session = history.sessions.max_by(&:date)
      last_session ? last_session.groups.map(&:members) : []
    end

    def stream_payload(stream, previous_groups)
      groups = previous_groups.map { |group| group & stream.members }.reject(&:empty?)
      {name: stream.name, members: stream.members.map(&:to_s), groups: groups.map { |g| g.map(&:to_s) }}
    end

    def symbolize_groups(groups) = Array(groups).map { |g| Array(g).map(&:to_sym) }.reject(&:empty?)

    def staleness_key(a, b) = [a, b].sort.join("|")

    def pairing_info(recommender, a, b)
      ever_paired = !recommender.ever_paired?(a, b).nil?
      {
        days: recommender.staleness(a, b),
        everPaired: ever_paired,
        overPaired: ever_paired && recommender.over_paired?(a, b)
      }
    end
  end
end
