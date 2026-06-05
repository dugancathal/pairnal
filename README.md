# Pairnal

Pairnal tracks your team's pairing history and recommends who should work together next, prioritizing people who haven't paired recently (or ever).

## Installation

```bash
gem install pairnal
```

## Usage

Pairnal reads a `.pair-history` file written in a simple Ruby DSL. Create one in your project root (or anywhere you like):

```ruby
# .pair-history
roster :alice, :bob, :carol, :dan, :eli

on "2026-06-01" do
  pair :alice, :bob
  pair :carol, :dan
  # eli sits out
end

on "2026-05-25" do
  mob :alice, :carol, :eli   # three or more people
  pair :bob, :dan
end
```

- `roster` — everyone currently on the team
- `on` — a dated session block (ISO 8601 date)
- `pair` — two people who worked together
- `mob` — three or more people who worked together

Run `pairnal` from the directory containing `.pair-history`:

```
$ pairnal
=== Option 1  (total staleness: 1095) ===
  alice + dan  (never paired)
  bob + carol  (never paired)
  eli  -- sits out

=== Option 2  (total staleness: 1090) ===
  ...
```

Options are ranked by total staleness — the sum of days since each pair last worked together (365 days for pairs that have never worked together). Higher is better.

To use a history file at a custom path:

```
$ pairnal --history path/to/.pair-history
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, then run `bundle exec rake release`, which will create a git tag, push commits and the tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dugancathal/pairnal. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/dugancathal/pairnal/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pairnal project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dugancathal/pairnal/blob/main/CODE_OF_CONDUCT.md).
