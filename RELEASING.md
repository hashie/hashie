# Releasing Hashie

Release bug fixes frequently, features less frequently, and breaking API changes in major releases.

Releases use [`ruby-gem-release`](https://github.com/dblock/ruby-gem-release) 0.6.0 through a manually dispatched [Release workflow](.github/workflows/release.yml). Keep the gem dependency and reusable workflow pinned to the same released version. The workflow publishes through RubyGems Trusted Publishing; no stored RubyGems API key or one-time password is needed. It only runs from `master` in `hashie/hashie`.

## One-Time Setup

Before the first automated release, a maintainer must:

1. Create the GitHub environment `release` in `hashie/hashie` and restrict deployment branches to `master`. Hashie uses no required reviewers: collaborators with write access can dispatch releases without an approval gate. Required maintainer reviewers can be configured later if approval is desired.
2. At [Hashie's trusted publishers](https://rubygems.org/gems/hashie/trusted_publishers), configure repository owner `hashie`, repository `hashie`, workflow filename `release.yml`, environment `release`, and the separate workflow repository owner `dblock` and repository `ruby-gem-release`.
3. Ensure GitHub Actions has permission to push release commits and `v*` tags. The workflow uses `GITHUB_TOKEN` with `contents: write` and `id-token: write`, and pushes release metadata and the next development version directly to `master`. Remove blocking pull-request requirements if necessary while retaining force-push and deletion protections. This also permits other writers to push directly.

These settings are not applied by installing the workflow. Verify them before dispatching. See the upstream [setup and permissions guidance](https://github.com/dblock/ruby-gem-release/blob/v0.6.0/RELEASING.md#one-time-setup).

The GitHub environment is configured, and @dblock manually configured the RubyGems trusted publisher on its website. No publishing run has verified that setup yet.

## Prepare and Validate

Start with a clean, up-to-date `master`. Review [CHANGELOG.md](CHANGELOG.md), [UPGRADING.md](UPGRADING.md), and the supported Ruby, JRuby, integration, documentation, and lint results in [CI](https://github.com/hashie/hashie/actions/workflows/test.yml).

Check `Hashie::VERSION` in [lib/hashie/version.rb](lib/hashie/version.rb):

* Increment the patch version for compatible bug fixes, for example `6.0.0` to `6.0.1`.
* Increment the minor version for backward-compatible features, for example `6.0.0` to `6.1.0`.
* Increment the major version for breaking public API changes, for example `5.2.0` to `6.0.0`.

Keep the Unreleased changelog section and contribution placeholders intact. The workflow dates the release section, updates comparison links, and removes placeholders and empty categories from that section. It also updates the Stable Release paragraph in README. Placeholder-only notes cannot be released.

Hashie uses the standard workflow and built-in `KeepAChangelog` handler with an explicit contribution placeholder and six-section template. README hooks use `Markdown::Section` to validate the Stable Release heading before release validation and update its body after release and next-development preparation, inside trusted staging boundaries. Only Hashie's wording and category choices remain project-specific.

Release specs use the library's [RSpec helpers and local publication adapters](https://github.com/dblock/ruby-gem-release/blob/v0.6.0/docs/testing.md), copying selected real project files with `copy_files` instead of maintaining duplicate fixtures. They exercise the same workflow builder as the production Rakefile through capture, preparation, checkpoint, local publication, and the next development commit, without contacting RubyGems or GitHub. The helper isolates child processes from outer Actions variables, credentials, and release state.

Use MRI Ruby 3.3 or newer for release automation; Hashie's runtime requirement remains Ruby 3.0. The release dependency and tasks are omitted on older Ruby versions and JRuby.

```sh
bundle install
bundle exec rake rubocop spec docs:examples docs:readme
bundle exec rake build
```

Inspect the built gem's contents and smoke-test it in an isolated directory with only its runtime dependencies. Confirm the version and key APIs load from the built package, not the checkout. Commit and push any intended version or release-note changes before dispatching.

## Publish

From an up-to-date checkout, dispatch the checked-in version:

```sh
gh workflow run release.yml --repo hashie/hashie --ref master
```

To select a different release version, pass an explicit override:

```sh
gh workflow run release.yml --repo hashie/hashie --ref master -f version=6.0.0
```

Dispatch starts a real publishing run, not a dry run, and does not wait for approval. Review the selected commit and version before dispatching.

The workflow prepares release metadata, runs lint, specs, and documentation checks on Ruby 3.3, builds and preserves the exact gem and recovery artifacts, publishes to RubyGems, pushes the release commit and tag, and creates the GitHub Release. It then increments the patch version, restores all six contribution categories under Unreleased, updates the next-release wording in README, and pushes the next-development commit to `master`. Select a different planned minor or major development version in a later PR when needed.

Verify the published RubyGems version and required Ruby version, the remote tag's commit, the GitHub Release and its attached gem, and the next-development commit. The workflow does not replace the full supported-runtime CI matrix.

## Recover a Partial Release

Inspect the failed run, RubyGems, remote commits and tags, and the GitHub Release before retrying. Publication may have succeeded even if a later Git push or development-version update failed. Never move a published release tag or republish a version with different bytes.

Use the run's retained recovery artifacts and upstream [recovery instructions](https://github.com/dblock/ruby-gem-release/blob/v0.6.0/docs/actions/release.md#recovery-artifacts) to reconcile the exact prepared commit and gem. Do not blindly dispatch again with a newer version; finish reconciling the published release first.
