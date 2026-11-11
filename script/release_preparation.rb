# frozen_string_literal: true

require 'ruby-gem-release/changelog'
require 'tempfile'

class HashieReleasePreparation
  CATEGORIES = %w[Added Changed Deprecated Removed Fixed Security].freeze
  README_RELEASE = /^## Stable Release\n\n[^\n]+$/

  def initialize(path: 'CHANGELOG.md', readme_path: 'README.md')
    @path = path
    @readme_path = readme_path
  end

  def validate!(release, changelog:)
    _readme_content
    return if changelog.released?(release.version)

    Tempfile.create('hashie-changelog') do |file|
      file.write(_clean_pending_notes(File.read(@path)))
      file.flush
      pending = RubyGemRelease::Changelog::KeepAChangelog.new(path: file.path).pending?
      raise ArgumentError, 'nothing to release: no pending changelog notes' unless pending
    end
  end

  def prepare!(release, changelog:)
    validate!(release, changelog: changelog)
    readme = _readme_content
    File.write(@path, _clean_pending_notes(File.read(@path))) unless changelog.released?(release.version)
    _write_readme(readme, "You're reading the documentation for the stable release of Hashie, #{release.version}.")
  end

  def prepare_next!(release)
    readme = _readme_content
    content = File.read(@path)
    empty_section = /^## \[Unreleased\]\n\n(?=## )/
    if content.match?(empty_section)
      reference = content[/^\[Unreleased\]: [^\n]+\n/]
      content.sub!(reference, '') if reference
      categories = CATEGORIES.map { |category| "### #{category}\n\n* Your contribution here.\n\n" }.join
      content.sub!(empty_section, "## [Unreleased]\n\n#{reference}\n#{categories}")
      File.write(@path, content)
    end
    _write_readme(readme, "You're reading the documentation for the next release of Hashie, which should be #{release.next_version}. " \
                          "The current stable release is [#{release.version}](https://github.com/hashie/hashie/blob/v#{release.version}/README.md).")
  end

  private

  def _clean_pending_notes(content)
    content.sub(/(^## \[Unreleased\]\n)(.*?)(?=^## |\z)/m) do
      heading = Regexp.last_match(1)
      notes = Regexp.last_match(2)
      notes = notes.gsub(/^\* Your contribution here\.\n/, '').gsub(/^### [^\n]+\n\n*(?=### |\z)/, '')
      "#{heading}#{notes.rstrip}\n\n"
    end
  end

  def _readme_content
    content = File.read(@readme_path)
    raise ArgumentError, 'expected exactly one stable release paragraph in `README.md`' unless content.scan(README_RELEASE).one?

    content
  end

  def _write_readme(content, paragraph)
    File.write(@readme_path, content.sub(README_RELEASE, "## Stable Release\n\n#{paragraph}"))
  end
end
