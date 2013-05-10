# CHANGELOG

## 2.0.5

* make coercion work better with non-symbol keys in mash wapcaplet #96

## 2.0.4

* make #fetch method consistent with normal Hash markiz #94
* various doc tweaks craiglittle #90

## 2.0.3

* Hashie::Mash.new(abc: true).respond_to?(:abc?) works 7even #88
* Fix #replace jimeh #68

## 2.0.2

* adding symbolize_keys back to to_hash cromulus #85

## 2.0.1

* remove Mash#object_id override matschaffer #81
* gem cleanup: remove VERSION, Gemfile.lock jch, mbleigh

## 2.0.0

* update gemspec with license info jordimassaguerpla #72
* fix readme typo jcamenisch #71
* initialize with merge coerces values mattfawcett #27
* Hashie::Extensions::Coercion coerce_keys takes arguments mattfawcett #28
* Trash removes translated values on initialization sleverbor #39
* Mash#fetch works with symbol or string keys arthwood #66
* Hashie::Hash inherits from ::Hash to avoid ambiguity meh, orend #49
* update respond_to? method signature to match ruby core definition dlupu #62
* DeepMerge extension nashby #41
* Dash defaults are dup'ed before assigned ohrite #63
* remove id, type, and object_id as special allowable keys jch #77
* merge and update accepts a block jch #78
