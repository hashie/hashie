## 2.1.2 (5/12/2014)

* [#169](https://github.com/intridea/hashie/pull/169): Hash#to_hash will also convert nested objects that implement `to_hash` - [@gregory](https://github.com/gregory).

## 2.1.1 (4/12/2014)

* [#144](https://github.com/intridea/hashie/issues/144): Fixed regression invoking `to_hash` with no parameters - [@mbleigh](https://github.com/mbleigh).

## 2.1.0 (4/6/2014)

* [#134](https://github.com/intridea/hashie/pull/134): Add deep_fetch extension for nested access - [@tylerdooling](https://github.com/tylerdooling).
* Removed support for Ruby 1.8.7 - [@dblock](https://github.com/dblock).
* Ruby style now enforced with Rubocop - [@dblock](https://github.com/dblock).
* [#138](https://github.com/intridea/hashie/pull/138): Added Hashie::Rash, a hash whose keys can be regular expressions or ranges - [@epitron](https://github.com/epitron).
* [#131](https://github.com/intridea/hashie/pull/131): Added IgnoreUndeclared, an extension to silently ignore undeclared properties at intialization - [@righi](https://github.com/righi).
* [#136](https://github.com/intridea/hashie/issues/136): Removed Hashie::Extensions::Structure - [@markiz](https://github.com/markiz).
* [#107](https://github.com/intridea/hashie/pull/107): Fixed excessive value conversions, poor performance of deep merge in Hashie::Mash - [@davemitchell](https://github.com/dblock), [@dblock](https://github.com/dblock).
* [#69](https://github.com/intridea/hashie/issues/69): Fixed assigning multiple properties in Hashie::Trash - [@einzige](https://github.com/einzige).
* [#100](https://github.com/intridea/hashie/pull/100): IndifferentAccess#store will respect indifference - [@jrochkind](https://github.com/jrochkind).
* [#103](https://github.com/intridea/hashie/pull/103): Fixed support for Hashie::Dash properties that end in bang - [@thedavemarshall](https://github.com/thedavemarshall).
* [89](https://github.com/intridea/hashie/issues/89): Do not respond to every method with suffix in Hashie::Mash, fixes Rails strong_parameters - [@Maxim-Filimonov](https://github.com/Maxim-Filimonov).
* [#110](https://github.com/intridea/hashie/pull/110): Correctly use Hash#default from Mash#method_missing - [@ryansouza](https://github.com/ryansouza).
* [#120](https://github.com/intridea/hashie/pull/120): Pass options to recursive to_hash calls - [@pwillett](https://github.com/pwillett).
* [#113](https://github.com/intridea/hashie/issues/113): Fixed Hash#merge with Hashie::Dash - [@spencer1248](https://github.com/spencer1248).
* [#99](https://github.com/intridea/hashie/issues/99): Hash#deep_merge raises errors when it encounters integers - [@defsprite](https://github.com/defsprite).
* [#133](https://github.com/intridea/hashie/pull/133): Fixed Hash##to_hash with symbolize_keys - [@mhuggins](https://github.com/mhuggins).
* [#130](https://github.com/intridea/hashie/pull/130): IndifferentAccess now works without MergeInitializer - [@npj](https://github.com/npj).
* [#111](https://github.com/intridea/hashie/issues/111): Trash#translations correctly maps original to translated names - [@artm](https://github.com/artm).
* [#129](https://github.com/intridea/hashie/pull/129): Added Trash#permitted_input_keys and inverse_translations - [@artm](https://github.com/artm).

## 2.0.5

* [#96](https://github.com/intridea/hashie/pull/96): Make coercion work better with non-symbol keys in Hashie::Mash - [@wapcaplet](https://github.com/wapcaplet).

## 2.0.4

* [#04](https://github.com/intridea/hashie/pull/94): Make #fetch method consistent with normal Hash - [@markiz](https://github.com/markiz).
* [#90](https://github.com/intridea/hashie/pull/90): Various doc tweaks - [@craiglittle](https://github.com/craiglittle).

## 2.0.3

* [#88](https://github.com/intridea/hashie/pull/88): Hashie::Mash.new(abc: true).respond_to?(:abc?) works - [@7even](https://github.com/7even).
* [#68](https://github.com/intridea/hashie/pull/68): Fix #replace - [@jimeh](https://github.com/jimeh).

## 2.0.2

* [#85](https://github.com/intridea/hashie/pull/85): adding symbolize_keys back to to_hash - [@cromulus](https://github.com/cromulus).

## 2.0.1

* [#81](https://github.com/intridea/hashie/pull/81): remove Mash#object_id override - [@matschaffer](https://github.com/matschaffer).
* Gem cleanup: removed VERSION, Gemfile.lock [@jch](https://github.com/jch), [@mbleigh](https://github.com/mbleigh).

## 2.0.0

* [#72](https://github.com/intridea/hashie/pull/72): Updated gemspec with license info - [@jordimassaguerpla](https://github.com/jordimassaguerpla).
* [#27](https://github.com/intridea/hashie/pull/27): Initialized with merge coerces values - [@mattfawcett](https://github.com/mattfawcett).
* [#28](https://github.com/intridea/hashie/pull/28): Hashie::Extensions::Coercion coerce_keys takes arguments - [@mattfawcett](https://github.com/mattfawcett).
* [#39](https://github.com/intridea/hashie/pull/39): Trash removes translated values on initialization - [@sleverbor](https://github.com/sleverbor).
* [#66](https://github.com/intridea/hashie/pull/66): Mash#fetch works with symbol or string keys - [@arthwood](https://github.com/arthwood).
* [#49](https://github.com/intridea/hashie/pull/49): Hashie::Hash inherits from ::Hash to avoid ambiguity - [@meh](https://github.com/meh), [@orend](https://github.com/orend).
* [#62](https://github.com/intridea/hashie/pull/62): update respond_to? method signature to match ruby core definition - [@dlupu](https://github.com/dlupu).
* [#41](https://github.com/intridea/hashie/pull/41): DeepMerge extension - [@nashby](https://github.com/nashby).
* [#63](https://github.com/intridea/hashie/pull/63): Dash defaults are dup'ed before assigned - [@ohrite](https://github.com/ohrite).
* [#77](https://github.com/intridea/hashie/pull/77): Remove id, type, and object_id as special allowable keys [@jch](https://github.com/jch).
* [#78](https://github.com/intridea/hashie/pull/78): Merge and update accepts a block - [@jch](https://github.com/jch).
