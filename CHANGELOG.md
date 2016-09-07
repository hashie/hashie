# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning 2.0.0][semver]. Any violations of this
scheme are considered to be bugs.

[semver]: http://semver.org/spec/v2.0.0.html

## [Unreleased][unreleased]

[unreleased]: https://github.com/intridea/hashie/compare/v3.4.4...master

### Added

* [#337](https://github.com/intridea/hashie/pull/337), [#331](https://github.com/intridea/hashie/issues/331): `Hashie::Mash#load` accepts a `Pathname` object - [@gipcompany](https://github.com/gipcompany).

### Changed

* Nothing yet.

### Deprecated

* Nothing yet.

### Removed

* Nothing yet.

### Fixed

* [#358](https://github.com/intridea/hashie/pull/358): Fix support for Array#dig - [@modosc](https://github.com/modosc/).
* [#365](https://github.com/intridea/hashie/pull/365): Ensure ActiveSupport::HashWithIndifferentAccess is defined before use in #deep_locate  - [@mikejarema](https://github.com/mikejarema/).

### Security

* Nothing yet.

### Miscellanous

* Nothing yet.

## [3.4.4] - 2016-04-29

[3.4.4]: https://github.com/intridea/hashie/compare/v3.4.3...v3.4.4

### Added

* [#349](https://github.com/intridea/hashie/pull/349): Convert `Hashie::Mash#dig` arguments for Ruby 2.3.0 - [@k0kubun](https://github.com/k0kubun).

### Fixed

* [#240](https://github.com/intridea/hashie/pull/240): Fixed nesting twice with Clash keys - [@bartoszkopinski](https://github.com/bartoszkopinski).
* [#317](https://github.com/intridea/hashie/pull/317): Ensure `Hashie::Extensions::MethodQuery` methods return boolean values - [@michaelherold](https://github.com/michaelherold).
* [#319](https://github.com/intridea/hashie/pull/319): Fix a regression from 3.4.1 where `Hashie::Extensions::DeepFind` is no longer indifference-aware - [@michaelherold](https://github.com/michaelherold).
* [#322](https://github.com/intridea/hashie/pull/322): Fixed `reverse_merge` issue with `Mash` subclasses - [@marshall-lee](https://github.com/marshall-lee).
* [#346](https://github.com/intridea/hashie/pull/346): Fixed `merge` breaking indifferent access - [@docwhat](https://github.com/docwhat), [@michaelherold](https://github.com/michaelherold).
* [#350](https://github.com/intridea/hashie/pull/350): Fixed from string translations used with `IgnoreUndeclared` - [@marshall-lee](https://github.com/marshall-lee).

## [3.4.3] - 2015-10-25

[3.4.3]: https://github.com/intridea/hashie/compare/v3.4.2...v3.4.3

### Added

* [#306](https://github.com/intridea/hashie/pull/306): Added `Hashie::Extensions::Dash::Coercion` - [@marshall-lee](https://github.com/marshall-lee).
* [#314](https://github.com/intridea/hashie/pull/314): Added a `StrictKeyAccess` extension that will raise an error whenever a key is accessed that does not exist in the hash - [@pboling](https://github.com/pboling).

### Fixed

* [#304](https://github.com/intridea/hashie/pull/304): Ensured compatibility of `Hash` extensions with singleton objects - [@regexident](https://github.com/regexident).
* [#310](https://github.com/intridea/hashie/pull/310): Fixed `Hashie::Extensions::SafeAssignment` bug with private methods - [@marshall-lee](https://github.com/marshall-lee).

### Miscellaneous

* [#313](https://github.com/intridea/hashie/pull/313): Restrict pending spec to only Ruby versions 2.2.0-2.2.2 - [@pboling](https://github.com/pboling).
* [#315](https://github.com/intridea/hashie/pull/315): Default `bin/` scripts: `console` and `setup` - [@pboling](https://github.com/pboling).

## [3.4.2] - 2015-06-02

[3.4.2]: https://github.com/intridea/hashie/compare/v3.4.1...v3.4.2

### Added

* [#297](https://github.com/intridea/hashie/pull/297): Extracted `Trash`'s behavior into a new `Dash::PropertyTranslation` extension - [@michaelherold](https://github.com/michaelherold).

### Removed

* [#292](https://github.com/intridea/hashie/pull/292): Removed `Mash#id` and `Mash#type` - [@jrochkind](https://github.com/jrochkind).

## [3.4.1] - 2015-03-31

[3.4.1]: https://github.com/intridea/hashie/compare/v3.4.0...v3.4.1

### Added

* [#269](https://github.com/intridea/hashie/pull/272): Added Hashie::Extensions::DeepLocate - [@msievers](https://github.com/msievers).
* [#281](https://github.com/intridea/hashie/pull/281): Added #reverse_merge to Mash to override ActiveSupport's version - [@mgold](https://github.com/mgold).

### Fixed

* [#270](https://github.com/intridea/hashie/pull/277): Fixed ArgumentError raised when using IndifferentAccess and HashWithIndifferentAccess - [@gardenofwine](https://github.com/gardenofwine).
* [#282](https://github.com/intridea/hashie/pull/282): Fixed coercions in a subclass accumulating in the superclass - [@maxlinc](https://github.com/maxlinc), [@martinstreicher](https://github.com/martinstreicher).

## [3.4.0] - 2015-02-02

[3.4.0]: https://github.com/intridea/hashie/compare/v3.3.2...v3.4.0

### Added

* [#251](https://github.com/intridea/hashie/pull/251): Added block support to indifferent access #fetch - [@jgraichen](https://github.com/jgraichen).
* [#252](https://github.com/intridea/hashie/pull/252): Added support for conditionally required Hashie::Dash attributes - [@ccashwell](https://github.com/ccashwell).
* [#254](https://github.com/intridea/hashie/pull/254): Added public utility methods for stringify and symbolize keys - [@maxlinc](https://github.com/maxlinc).
* [#260](https://github.com/intridea/hashie/pull/260): Added block support to Extensions::DeepMerge - [@galathius](https://github.com/galathius).
* [#271](https://github.com/intridea/hashie/pull/271): Added ability to define defaults based on current hash - [@gregory](https://github.com/gregory).

### Changed

* [#249](https://github.com/intridea/hashie/pull/249): SafeAssignment will now also protect hash-style assignments - [@jrochkind](https://github.com/jrochkind).
* [#264](https://github.com/intridea/hashie/pull/264): Methods such as abc? return true/false with Hashie::Extensions::MethodReader - [@Zloy](https://github.com/Zloy).

### Fixed

* [#247](https://github.com/intridea/hashie/pull/247): Fixed #stringify_keys and #symbolize_keys collision with ActiveSupport - [@bartoszkopinski](https://github.com/bartoszkopinski).
* [#256](https://github.com/intridea/hashie/pull/256): Inherit key coercions - [@Erol](https://github.com/Erol).
* [#259](https://github.com/intridea/hashie/pull/259): Fixed handling of default proc values in Mash - [@Erol](https://github.com/Erol).
* [#261](https://github.com/intridea/hashie/pull/261): Fixed bug where Dash.property modifies argument object - [@d-tw](https://github.com/d-tw).
* [#269](https://github.com/intridea/hashie/pull/269): Add #extractable_options? so ActiveSupport Array#extract_options! can extract it - [@ridiculous](https://github.com/ridiculous).

## [3.3.2] - 2014-11-26

[3.3.2]: https://github.com/intridea/hashie/compare/v3.3.1...v3.3.2

### Added

* [#231](https://github.com/intridea/hashie/pull/231): Added support for coercion on class type that inherit from Hash - [@gregory](https://github.com/gregory).
* [#233](https://github.com/intridea/hashie/pull/233): Custom error messages for required properties in Hashie::Dash subclasses - [@joss](https://github.com/joss).
* [#245](https://github.com/intridea/hashie/pull/245): Added Hashie::Extensions::MethodAccessWithOverride to autoloads - [@Fritzinger](https://github.com/Fritzinger).

### Fixed

* [#221](https://github.com/intridea/hashie/pull/221): Reduce amount of allocated objects on calls with suffixes in Hashie::Mash - [@kubum](https://github.com/kubum).
* [#224](https://github.com/intridea/hashie/pull/224): Merging Hashie::Mash now correctly only calls the block on duplicate values - [@amysutedja](https://github.com/amysutedja).
* [#228](https://github.com/intridea/hashie/pull/228): Made Hashie::Extensions::Parsers::YamlErbParser pass template filename to ERB - [@jperville](https://github.com/jperville).

## [3.3.1] - 2014-08-26

[3.3.1]: https://github.com/intridea/hashie/compare/v3.3.0...v3.3.1

### Added

* [#183](https://github.com/intridea/hashie/pull/183): Added Mash#load with YAML file support - [@gregory](https://github.com/gregory).
* [#189](https://github.com/intridea/hashie/pull/189): Added Rash#fetch - [@medcat](https://github.com/medcat).
* [#204](https://github.com/intridea/hashie/pull/204): Added Hashie::Extensions::MethodOverridingWriter and MethodAccessWithOverride - [@michaelherold](https://github.com/michaelherold).
* [#205](http://github.com/intridea/hashie/pull/205): Added Hashie::Extensions::Mash::SafeAssignment - [@michaelherold](https://github.com/michaelherold).
* [#209](http://github.com/intridea/hashie/pull/209): Added Hashie::Extensions::DeepFind - [@michaelherold](https://github.com/michaelherold).

### Fixed

* [#69](https://github.com/intridea/hashie/pull/69): Fixed regression in assigning multiple properties in Hashie::Trash - [@michaelherold](https://github.com/michaelherold), [@einzige](https://github.com/einzige), [@dblock](https://github.com/dblock).
* [#195](https://github.com/intridea/hashie/pull/195): Ensure that the same object is returned after injecting IndifferentAccess - [@michaelherold](https://github.com/michaelherold).
* [#201](https://github.com/intridea/hashie/pull/201): Hashie::Trash transforms can be inherited - [@fobocaster](https://github.com/fobocaster).
* [#200](https://github.com/intridea/hashie/pull/200): Improved coercion: primitives and error handling - [@maxlinc](https://github.com/maxlinc).
* [#206](http://github.com/intridea/hashie/pull/206): Fixed stack overflow from repetitively including coercion in subclasses - [@michaelherold](https://github.com/michaelherold).
* [#207](http://github.com/intridea/hashie/pull/207): Fixed inheritance of transformations in Trash - [@fobocaster](https://github.com/fobocaster).

## [3.2.0] - 2014-07-10

[3.2.0]: https://github.com/intridea/hashie/compare/v3.1.0...v3.2.0

### Added

* [#177](https://github.com/intridea/hashie/pull/177): Added support for coercing enumerables and collections - [@gregory](https://github.com/gregory).

### Changed

* [#179](https://github.com/intridea/hashie/pull/179): Mash#values_at will convert each key before doing the lookup - [@nahiluhmot](https://github.com/nahiluhmot).
* [#184](https://github.com/intridea/hashie/pull/184): Allow ranges on Rash to match all Numeric types - [@medcat](https://github.com/medcat).

### Fixed

* [#164](https://github.com/intridea/hashie/pull/164), [#165](https://github.com/intridea/hashie/pull/165), [#166](https://github.com/intridea/hashie/pull/166): Fixed stack overflow when coercing mashes that contain ActiveSupport::HashWithIndifferentAccess values - [@numinit](https://github.com/numinit), [@kgrz](https://github.com/kgrz).
* [#187](https://github.com/intridea/hashie/pull/187): Automatically require version - [@medcat](https://github.com/medcat).
* [#190](https://github.com/intridea/hashie/issues/190): Fixed `coerce_key` with `from` Trash feature and Coercion extension - [@gregory](https://github.com/gregory).
* [#192](https://github.com/intridea/hashie/pull/192): Fixed StringifyKeys#stringify_keys! to recursively stringify keys of embedded ::Hash types - [@dblock](https://github.com/dblock).

## [3.1.0] - 2014-06-25

[3.1.0]: https://github.com/intridea/hashie/compare/v3.0.0...v3.1.0

### Added

* [#172](https://github.com/intridea/hashie/pull/172): Added Dash and Trash#update_attributes! - [@gregory](https://github.com/gregory).

### Changed

* [#169](https://github.com/intridea/hashie/pull/169): Hash#to_hash will also convert nested objects that implement to_hash - [@gregory](https://github.com/gregory).
* [#173](https://github.com/intridea/hashie/pull/173): Auto include Dash::IndifferentAccess when IndifferentAccess is included in Dash - [@gregory](https://github.com/gregory).

### Fixed

* [#171](https://github.com/intridea/hashie/pull/171): Include Trash and Dash class name when raising `NoMethodError` - [@gregory](https://github.com/gregory).
* [#174](https://github.com/intridea/hashie/pull/174): Fixed `from` and `transform_with` Trash features when IndifferentAccess is included - [@gregory](https://github.com/gregory).

## [3.0.0] - 2014-06-03

[3.0.0]: https://github.com/intridea/hashie/compare/v2.1.2...v3.0.0

**Note:** This version introduces several backward incompatible API changes. See [UPGRADING](UPGRADING.md) for details.

### Added

* [#149](https://github.com/intridea/hashie/issues/149): Allow IgnoreUndeclared and DeepMerge to be used with undeclared properties - [@jhaesus](https://github.com/jhaesus).

### Changed

* [#152](https://github.com/intridea/hashie/pull/152): Do not convert keys to String in Hashie::Dash and Hashie::Trash, use Hashie::Extensions::Dash::IndifferentAccess to achieve backward compatible behavior - [@dblock](https://github.com/dblock).
* [#152](https://github.com/intridea/hashie/pull/152): Do not automatically stringify keys in Hashie::Hash#to_hash, pass `:stringify_keys` to achieve backward compatible behavior - [@dblock](https://github.com/dblock).

### Fixed

* [#146](https://github.com/intridea/hashie/issues/146): Mash#respond_to? inconsistent with #method_missing and does not respond to #permitted? - [@dblock](https://github.com/dblock).
* [#148](https://github.com/intridea/hashie/pull/148): Consolidated Hashie::Hash#stringify_keys implementation - [@dblock](https://github.com/dblock).
* [#159](https://github.com/intridea/hashie/pull/159): Handle nil intermediate object on deep fetch - [@stephenaument](https://github.com/stephenaument).

## [2.1.2] - 2014-05-12

[2.1.2]: https://github.com/intridea/hashie/compare/v2.1.1...v2.1.2

### Changed

* [#169](https://github.com/intridea/hashie/pull/169): Hash#to_hash will also convert nested objects that implement `to_hash` - [@gregory](https://github.com/gregory).

## [2.1.1] - 2014-04-12

[2.1.1]: https://github.com/intridea/hashie/compare/v2.1.0...v2.1.1

### Fixed

* [#131](https://github.com/intridea/hashie/pull/131): Added IgnoreUndeclared, an extension to silently ignore undeclared properties at intialization - [@righi](https://github.com/righi).
* [#138](https://github.com/intridea/hashie/pull/138): Added Hashie::Rash, a hash whose keys can be regular expressions or ranges - [@epitron](https://github.com/epitron).
* [#144](https://github.com/intridea/hashie/issues/144): Fixed regression invoking `to_hash` with no parameters - [@mbleigh](https://github.com/mbleigh).

## [2.1.0] - 2014-04-06

[2.1.0]: https://github.com/intridea/hashie/compare/v2.0.5...v2.1.0

### Added

* [#134](https://github.com/intridea/hashie/pull/134): Add deep_fetch extension for nested access - [@tylerdooling](https://github.com/tylerdooling).

### Changed

* [#89](https://github.com/intridea/hashie/issues/89): Do not respond to every method with suffix in Hashie::Mash, fixes Rails strong_parameters - [@Maxim-Filimonov](https://github.com/Maxim-Filimonov).

### Removed

* Removed support for Ruby 1.8.7 - [@dblock](https://github.com/dblock).
* [#136](https://github.com/intridea/hashie/issues/136): Removed Hashie::Extensions::Structure - [@markiz](https://github.com/markiz).

### Fixed

* [#69](https://github.com/intridea/hashie/issues/69): Fixed assigning multiple properties in Hashie::Trash - [@einzige](https://github.com/einzige).
* [#99](https://github.com/intridea/hashie/issues/99): Hash#deep_merge raises errors when it encounters integers - [@defsprite](https://github.com/defsprite).
* [#100](https://github.com/intridea/hashie/pull/100): IndifferentAccess#store will respect indifference - [@jrochkind](https://github.com/jrochkind).
* [#103](https://github.com/intridea/hashie/pull/103): Fixed support for Hashie::Dash properties that end in bang - [@thedavemarshall](https://github.com/thedavemarshall).
* [#107](https://github.com/intridea/hashie/pull/107): Fixed excessive value conversions, poor performance of deep merge in Hashie::Mash - [@davemitchell](https://github.com/dblock), [@dblock](https://github.com/dblock).
* [#110](https://github.com/intridea/hashie/pull/110): Correctly use Hash#default from Mash#method_missing - [@ryansouza](https://github.com/ryansouza).
* [#111](https://github.com/intridea/hashie/issues/111): Trash#translations correctly maps original to translated names - [@artm](https://github.com/artm).
* [#113](https://github.com/intridea/hashie/issues/113): Fixed Hash#merge with Hashie::Dash - [@spencer1248](https://github.com/spencer1248).
* [#120](https://github.com/intridea/hashie/pull/120): Pass options to recursive to_hash calls - [@pwillett](https://github.com/pwillett).
* [#129](https://github.com/intridea/hashie/pull/129): Added Trash#permitted_input_keys and inverse_translations - [@artm](https://github.com/artm).
* [#130](https://github.com/intridea/hashie/pull/130): IndifferentAccess now works without MergeInitializer - [@npj](https://github.com/npj).
* [#133](https://github.com/intridea/hashie/pull/133): Fixed Hash##to_hash with symbolize_keys - [@mhuggins](https://github.com/mhuggins).

### Miscellaneous

* Ruby style now enforced with Rubocop - [@dblock](https://github.com/dblock).

## [2.0.5] - 2013-05-10

[2.0.5]: https://github.com/intridea/hashie/compare/v2.0.4...v2.0.5

### Fixed

* [#96](https://github.com/intridea/hashie/pull/96): Make coercion work better with non-symbol keys in Hashie::Mash - [@wapcaplet](https://github.com/wapcaplet).

## [2.0.4] - 2013-04-24

[2.0.4]: https://github.com/intridea/hashie/compare/v2.0.3...v2.0.4

### Fixed

* [#94](https://github.com/intridea/hashie/pull/94): Make #fetch method consistent with normal Hash - [@markiz](https://github.com/markiz).

### Miscellaneous

* [#90](https://github.com/intridea/hashie/pull/90): Various doc tweaks - [@craiglittle](https://github.com/craiglittle).

## [2.0.3] - 2013-03-18

[2.0.3]: https://github.com/intridea/hashie/compare/v2.0.2...v2.0.3

### Fixed

* [#68](https://github.com/intridea/hashie/pull/68): Fix #replace - [@jimeh](https://github.com/jimeh).
* [#88](https://github.com/intridea/hashie/pull/88): Hashie::Mash.new(abc: true).respond_to?(:abc?) works - [@7even](https://github.com/7even).

## [2.0.2] - 2013-02-26

[2.0.2]: https://github.com/intridea/hashie/compare/v2.0.1...v2.0.2

### Fixed

* [#85](https://github.com/intridea/hashie/pull/85): adding symbolize_keys back to to_hash - [@cromulus](https://github.com/cromulus).

## [2.0.1] - 2013-02-26

[2.0.1]: https://github.com/intridea/hashie/compare/v2.0.0...v2.0.1

### Removed

* [#81](https://github.com/intridea/hashie/pull/81): remove Mash#object_id override - [@matschaffer](https://github.com/matschaffer).

### Miscellaneous

* Gem cleanup: removed VERSION, Gemfile.lock [@jch](https://github.com/jch), [@mbleigh](https://github.com/mbleigh).

## [2.0.0] - 2013-02-16

[2.0.0]: https://github.com/intridea/hashie/compare/v1.2.0...v2.0.0

### Added

* [#41](https://github.com/intridea/hashie/pull/41): DeepMerge extension - [@nashby](https://github.com/nashby).
* [#78](https://github.com/intridea/hashie/pull/78): Merge and update accepts a block - [@jch](https://github.com/jch).

### Changed

* [#28](https://github.com/intridea/hashie/pull/28): Hashie::Extensions::Coercion coerce_keys takes arguments - [@mattfawcett](https://github.com/mattfawcett).
* [#77](https://github.com/intridea/hashie/pull/77): Remove id, type, and object_id as special allowable keys [@jch](https://github.com/jch).

### Fixed

* [#27](https://github.com/intridea/hashie/pull/27): Initialized with merge coerces values - [@mattfawcett](https://github.com/mattfawcett).
* [#39](https://github.com/intridea/hashie/pull/39): Trash removes translated values on initialization - [@sleverbor](https://github.com/sleverbor).
* [#49](https://github.com/intridea/hashie/pull/49): Hashie::Hash inherits from ::Hash to avoid ambiguity - [@meh](https://github.com/meh), [@orend](https://github.com/orend).
* [#62](https://github.com/intridea/hashie/pull/62): update respond_to? method signature to match ruby core definition - [@dlupu](https://github.com/dlupu).
* [#63](https://github.com/intridea/hashie/pull/63): Dash defaults are dup'ed before assigned - [@ohrite](https://github.com/ohrite).
* [#66](https://github.com/intridea/hashie/pull/66): Mash#fetch works with symbol or string keys - [@arthwood](https://github.com/arthwood).

### Miscellaneous

* [#72](https://github.com/intridea/hashie/pull/72): Updated gemspec with license info - [@jordimassaguerpla](https://github.com/jordimassaguerpla).
