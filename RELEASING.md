# Releasing Hashie

There're no particular rules about when to release Hashie. Release bug fixes frequenty, features not so frequently and breaking API changes rarely.

### Release

Run tests, check that all tests succeed locally.

```sh
bundle install
bundle exec rake
```

Check that the last build succeeded in [Travis CI](https://travis-ci.org/intridea/hashie) for all supported platforms.

Increment the version, modify [lib/hashie/version.rb](lib/hashie/version.rb).

* Increment the third number (minor version) if the release has bug fixes and/or very minor features, only (eg. change `0.5.1` to `0.5.2`).
* Increment the second number (patch version) if the release contains major features or breaking API changes (eg. change `0.5.1` to `0.6.0`).

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the documentation for a stable release. Remove references to the previous release of Hashie. Keep the file open, you'll have to undo this change after the release.

```markdown
## Stable Release

You're reading the documentation for the stable release of Hashie, 3.3.0.
```

Change "Next Release" in [CHANGELOG.md](CHANGELOG.md) to the new version.

```markdown
3.3.0 (8/25/2014)
=================
```

Remove the line with "Your contribution here.", since there will be no more contributions to this release.

Commit your changes.

```sh
git add README.md CHANGELOG.md lib/hashie/version.rb
git commit -m "Preparing for release, 3.3.0."
git push origin master
```

Release.

```sh
$ rake release

hashie 3.3.0 built to pkg/hashie-3.3.0.gem.
Tagged v3.3.0.
Pushed git commits and tags.
Pushed hashie 3.3.0 to rubygems.org.
```

### Prepare for the Next Version

Modify the "Stable Release" section in [README.md](README.md). Change the text to reflect that this is going to be the next release.

```markdown
## Stable Release

You're reading the documentation for the next release of Hashie, which should be 3.3.1.
The current stable release is [3.3.0](https://github.com/intridea/hashie/blob/v3.3.0/README.md).
```

Add the next release to [CHANGELOG.md](CHANGELOG.md).

```markdown
Next Release
============

* Your contribution here.
```

Commit your changes.

```sh
git add CHANGELOG.md README.md
git commit -m "Preparing for next release."
git push origin master
```
