# Releasing Hashie

Release bug fixes frequently, features less frequently, and breaking API changes in major releases.

## Prepare the release

Start with a clean, up-to-date `master`. Review the changes in [CHANGELOG.md](CHANGELOG.md) and migration notes in [UPGRADING.md](UPGRADING.md).

Check `Hashie::VERSION` in [lib/hashie/version.rb](lib/hashie/version.rb):

* Increment the patch version for compatible bug fixes, for example `5.2.0` to `5.2.1`.
* Increment the minor version for backward-compatible features, for example `5.2.0` to `5.3.0`.
* Increment the major version for breaking public API changes, for example `5.2.0` to `6.0.0`.

Update the Stable Release section in `README.md`:

```markdown
You're reading the documentation for the stable release of Hashie, 5.2.0.
```

Replace the Unreleased changelog heading and comparison link with the release version, date, and previous release tag:

```markdown
## [5.2.0] - 2026-10-23

[5.2.0]: https://github.com/hashie/hashie/compare/v5.1.0...v5.2.0
```

Remove contribution placeholders and empty categories from the release section. Preserve historical release entries.

## Validate

Use MRI Ruby 3.2 or newer for linting:

```sh
bundle install
bundle exec rake rubocop spec docs:examples docs:readme
bundle exec rake build
```

Inspect the built gem's contents and smoke-test it in an isolated directory with only its runtime dependencies. Confirm the version and key APIs load from the built package, not the checkout.

Commit the release preparation and push `master` normally. Wait for all supported Ruby, JRuby, integration, documentation, and lint jobs in [GitHub Actions](https://github.com/hashie/hashie/actions/workflows/test.yml) to pass on that exact commit.

## Publish

Confirm that neither the release tag nor gem version already exists. Authenticate with RubyGems using an account authorized to publish Hashie; publishing may require MFA.

The `bundle exec rake release` task builds the gem, tags the release, pushes Git commits and tags, and publishes to RubyGems:

```sh
bundle exec rake release
```

Alternatively, publish explicitly to keep each step separately verifiable:

```sh
gem push pkg/hashie-5.2.0.gem
git tag -a v5.2.0 -m "Release 5.2.0"
git push origin v5.2.0
gh release create v5.2.0 --verify-tag --title v5.2.0 --notes-file /path/to/release-notes.md
```

Use the released changelog section for the GitHub release notes. Verify the RubyGems version and required Ruby version, the remote tag's commit, and the GitHub release. If publishing partially succeeds, inspect the existing artifacts before retrying; never move a published release tag or republish a version.

## Prepare the next development version

Set the next planned version in `lib/hashie/version.rb`. After `5.2.0`, the next planned release is `6.0.0` for breaking changes. Restore the development wording in `README.md`:

```markdown
You're reading the documentation for the next release of Hashie, which should be 6.0.0. The current stable release is [5.2.0](https://github.com/hashie/hashie/blob/v5.2.0/README.md).
```

Add a new Unreleased section above the released changelog:

```markdown
## [Unreleased]

[Unreleased]: https://github.com/hashie/hashie/compare/v5.2.0...master

### Added

* Your contribution here.

### Changed

* Your contribution here.

### Deprecated

* Your contribution here.

### Removed

* Your contribution here.

### Fixed

* Your contribution here.

### Security

* Your contribution here.
```

Commit and push the next-development changes to `master` without modifying the release tag.
