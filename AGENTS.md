# Contributor instructions for coding agents

## Ruby and linting

- Use `# frozen_string_literal: true` in Ruby files.
- Run `bundle exec rake rubocop` on Ruby 3.2 or newer. RuboCop scans the entire project and enables new cops by default.
- Keep `.rubocop_todo.yml` as the baseline for existing offenses. Do not expand it to suppress new problems without explaining why.
- Fix spelling errors in prose and add intentional project terms to `.spellcheck.txt`; do not accept typos as vocabulary.
- Review autocorrections for behavior changes. In particular, do not replace `Hashie::Array#dig` with `[]` or change an arity-sensitive lambda to a symbol proc.
- Exception messages begin with lowercase words, have no trailing punctuation, and quote interpolated values with backticks.

## Validation

- Run the relevant specs with `bundle exec rspec`; run `bundle exec rake spec` for changes spanning the library.
- Integration specs use separate Gemfiles under `spec/integration`. Preserve their dependency isolation.
- Use `bundle exec` or `ruby -Ilib` so checks load this checkout rather than an installed Hashie.

## Documentation

- Keep Markdown prose paragraphs on one line; do not hard-wrap them.
- Update the README table of contents when adding or removing headings.
- Preserve every `Your contribution here.` placeholder in `CHANGELOG.md`; add entries without replacing the placeholders.
- Document changes to compatibility or supported Ruby versions in `UPGRADING.md`.
