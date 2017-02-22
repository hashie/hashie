# Releasing Hashie

There're no particular rules about when to release Hashie. Release bug fixes frequenty, features not so frequently and breaking API changes rarely.

## Release

Run tests, check that all tests succeed locally.

```sh
bundle install
bundle exec rake
```

Check that the last build succeeded in [Travis CI](https://travis-ci.org/intridea/hashie) for all supported platforms.

### Check Next Version

Increment the version, modify [lib/hashie/version.rb](lib/hashie/version.rb). [Changelog](CHANGELOG.md) entries should be helpfully categorized to assist in picking the next version number.

* Increment the third number (minor version) if the release has bug fixes and/or very minor features, only (eg. change `0.5.1` to `0.5.2`). These should be in the "Fixed", "Security", or "Miscellaneous" categories in the change log.
* Increment the second number (patch version) if the release contains major features or breaking API changes (eg. change `0.5.1` to `0.6.0`). These should be in the "Added" or "Deprecated" categories in the change log.
* Increment the first number (major version) if the release has any changed or removed behavior on public APIs (eg. change `0.5.1` to `1.0.0`). These should be in the "Changed" or "Removed" categories in the change log.

### Modify the Readme

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the documentation for a stable release. Remove references to the previous release of Hashie. Keep the file open, you'll have to undo this change after the release.

```markdown
## Stable Release

You're reading the documentation for the stable release of Hashie, 3.3.0.
```

### Modify the Changelog

Change "Unreleased" in [CHANGELOG.md](CHANGELOG.md) to the new version.

```markdown
## [3.3.0] - 2014-08-25

[3.3.0]: https://github.com/intridea/hashie/compare/v<LAST_VERSION>..v<THIS_VERSION>
```

Replace `<LAST_VERSION>` and `<THIS_VERSION>` with the last and new-to-be-released versions to set up the compare view on Github.

Remove any sections that only have "Your contribution here." underneath them.

Commit your changes.

```sh
git add README.md CHANGELOG.md lib/hashie/version.rb
git commit -m "Preparing for release, 3.3.0."
git push origin master
```

### Push to RubyGems.org

Release.

```sh
$ rake release

hashie 3.3.0 built to pkg/hashie-3.3.0.gem.
Tagged v3.3.0.
Pushed git commits and tags.
Pushed hashie 3.3.0 to rubygems.org.
```

## Prepare for the Next Version

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the next release.

```markdown
## Stable Release

You're reading the documentation for the next release of Hashie, which should be 3.3.1.
The current stable release is [3.3.0](https://github.com/intridea/hashie/blob/v3.3.0/README.md).
```

Add new "Unreleased" section to [CHANGELOG.md](CHANGELOG.md) using this template:

```markdown
## [Unreleased][unreleased]

[unreleased]: https://github.com/intridea/hashie/compare/v<THIS_VERSION>...master

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

### Miscellaneous

* Your contribution here.
```

Replace `<THIS_VERSION>` with the newly released versions to set up the compare view on Github.

Increment the minor version, modify [lib/hashie/version.rb](lib/hashie/version.rb).

Commit your changes.

```sh
git add CHANGELOG.md README.md lib/hashie/version.rb
git commit -m "Preparing for next development iteration, 3.3.1."
git push origin master
```
