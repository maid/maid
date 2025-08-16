## [0.11.1](https://github.com/maid/maid/compare/v0.11.0...v0.11.1) (2025-08-16)


### Bug Fixes

* **thor:** Upgrade thor to fix vulnerability (ref: ef87ff8) ([24402df](https://github.com/maid/maid/commit/24402df3121ac0b50da3cd51ed07144e30f55c5d))

# Changelog

## [0.11.0](https://github.com/maid/maid/compare/maid-v0.10.0...maid/v0.11.0) (2025-03-30)


### ⚠ BREAKING CHANGES

* Drop support for ruby < 3.2 (EOL rubies)

### Features

* Update to Ruby 3.4 ([770d9d9](https://github.com/maid/maid/commit/770d9d9ca9618ba4669077efd860335efe09d16d))


### Code Refactoring

* Drop support for ruby &lt; 3.2 (EOL rubies) ([770d9d9](https://github.com/maid/maid/commit/770d9d9ca9618ba4669077efd860335efe09d16d))

## [0.10.0](https://github.com/maid/maid/compare/v0.10.0-alpha.3...v0.10.0) (2023-05-01)


### Miscellaneous Chores

* release 0.10.0 ([1f35afd](https://github.com/maid/maid/commit/1f35afd2030bd74a5175ced5cd9766273162dea4))

## [0.10.0-alpha.3](https://github.com/maid/maid/compare/v0.10.0-alpha.2...v0.10.0-alpha.3) (2023-04-04)


### Features

* **maid:** improve `#watch` error message ([#287](https://github.com/maid/maid/issues/287)) ([0894cd6](https://github.com/maid/maid/commit/0894cd69665d5d9fe775b6b3df5a247f22f217d6))
* **tools:** add option to disable clobbering destination for `#move` ([#284](https://github.com/maid/maid/issues/284)) ([979413f](https://github.com/maid/maid/commit/979413fe284b61b43b33ba2169e72ed23043bcca))

## [0.10.0-alpha.2](https://github.com/maid/maid/compare/v0.10.0-alpha.1...v0.10.0-alpha.2) (2023-03-28)


### Bug Fixes

* update syntax for Ruby 3 ([#269](https://github.com/maid/maid/issues/269)) ([ce5b42b](https://github.com/maid/maid/commit/ce5b42b78e53b5ccb9b25926c5af19e31a5c0ed7))

## [0.10.0-alpha.1](https://github.com/maid/maid/compare/v0.9.0.alpha.2...v0.10.0-alpha.1) (2023-03-28)


### ⚠ BREAKING CHANGES

* Drop support for ruby < 2.7

### Features

* Add ruby 3+ support ([008ee83](https://github.com/maid/maid/commit/008ee83f1655a81e3523431ed35bc2dd20c10c6e))
* Pass scheduler options to Rufus for repeating tasks ([06a01d3](https://github.com/maid/maid/commit/06a01d3e847537bf8f3f51e6550969bf6123d9a1))


### Bug Fixes

* Unsafe regex for hostname in example rules ([#229](https://github.com/maid/maid/issues/229)) ([ffc793a](https://github.com/maid/maid/commit/ffc793a9c1e0f1ce433d75710cbd96626fd3835a))
* Use HTTPS for rubygems.org ([#219](https://github.com/maid/maid/issues/219)) ([ad0f81c](https://github.com/maid/maid/commit/ad0f81c6ffaed1fff2b91ce71f9b568b3f11b022))


### Code Refactoring

* Drop support for ruby &lt; 2.7 ([33838aa](https://github.com/maid/maid/commit/33838aaaeed481158613ce620aeb3a7dc5989ced))
