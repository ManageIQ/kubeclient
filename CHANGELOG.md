# Change Log

## [v0.4.0](https://github.com/abonas/kubeclient/tree/v0.4.0) (2015-08-23)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.3.0...v0.4.0)

**Merged pull requests:**

- move validate\_auth\_options to common so it can be shared. [\#109](https://github.com/abonas/kubeclient/pull/109) ([moolitayer](https://github.com/moolitayer))
- Add resource quotas and limit ranges. [\#106](https://github.com/abonas/kubeclient/pull/106) ([moolitayer](https://github.com/moolitayer))
- increase max line length from 80 to 100 [\#104](https://github.com/abonas/kubeclient/pull/104) ([abonas](https://github.com/abonas))

## [v0.3.0](https://github.com/abonas/kubeclient/tree/v0.3.0) (2015-07-28)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.2.0...v0.3.0)

**Closed issues:**

- Support Scaling ReplicationControllers [\#103](https://github.com/abonas/kubeclient/issues/103)
- gem release with changes from commit \#91 ? [\#99](https://github.com/abonas/kubeclient/issues/99)

**Merged pull requests:**

- Add Secrets [\#102](https://github.com/abonas/kubeclient/pull/102) ([iterion](https://github.com/iterion))

## [v0.2.0](https://github.com/abonas/kubeclient/tree/v0.2.0) (2015-07-14)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.17...v0.2.0)

**Merged pull requests:**

- Allow bearer token file for auth [\#98](https://github.com/abonas/kubeclient/pull/98) ([jimmidyson](https://github.com/jimmidyson))
- Bugfix: update of a entity not working as the name is not read correctly [\#97](https://github.com/abonas/kubeclient/pull/97) ([simonswine](https://github.com/simonswine))
- Fixes \#93: Remove old API versions, add v1 [\#94](https://github.com/abonas/kubeclient/pull/94) ([jimmidyson](https://github.com/jimmidyson))
- Fixes \#91: Move SSL options, basic auth & bearer token to constructor [\#92](https://github.com/abonas/kubeclient/pull/92) ([jimmidyson](https://github.com/jimmidyson))

## [v0.1.17](https://github.com/abonas/kubeclient/tree/v0.1.17) (2015-06-07)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.16...v0.1.17)

**Closed issues:**

- Drop API versions v1beta1/2 & add v1  [\#93](https://github.com/abonas/kubeclient/issues/93)
- Move ssl\_options & auth options into constructor [\#91](https://github.com/abonas/kubeclient/issues/91)
- Use service account token if available [\#90](https://github.com/abonas/kubeclient/issues/90)
- Using Bearer token impacts any RestClient instance [\#84](https://github.com/abonas/kubeclient/issues/84)

**Merged pull requests:**

- Update KubeException to inherit StandardError [\#95](https://github.com/abonas/kubeclient/pull/95) ([oschreib](https://github.com/oschreib))
- Send bearer token only on relevant instance [\#89](https://github.com/abonas/kubeclient/pull/89) ([oschreib](https://github.com/oschreib))
- update readme, fix section names [\#88](https://github.com/abonas/kubeclient/pull/88) ([abonas](https://github.com/abonas))

## [v0.1.16](https://github.com/abonas/kubeclient/tree/v0.1.16) (2015-05-19)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.15...v0.1.16)

**Merged pull requests:**

- add assert\_requested to basic\_auth tests [\#87](https://github.com/abonas/kubeclient/pull/87) ([abonas](https://github.com/abonas))
- readme fix for basic\_auth documentation and example [\#86](https://github.com/abonas/kubeclient/pull/86) ([abonas](https://github.com/abonas))
- Add HTTP basic authentication support [\#83](https://github.com/abonas/kubeclient/pull/83) ([oschreib](https://github.com/oschreib))

## [v0.1.15](https://github.com/abonas/kubeclient/tree/v0.1.15) (2015-05-14)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.14...v0.1.15)

**Closed issues:**

- Support bearer tokens for authentication ready for service accounts [\#79](https://github.com/abonas/kubeclient/issues/79)
- Wrong options for watch & SSL [\#77](https://github.com/abonas/kubeclient/issues/77)

**Merged pull requests:**

- Update readme [\#82](https://github.com/abonas/kubeclient/pull/82) ([jimmidyson](https://github.com/jimmidyson))
- Fixes \#79: Bearer token support [\#80](https://github.com/abonas/kubeclient/pull/80) ([jimmidyson](https://github.com/jimmidyson))
- Fixes \#77: Use cert & key for SSL opts as detailed at http://apidock.com/ruby/v1\_9\_3\_392/Net/HTTP/start/class\#docs\_body [\#78](https://github.com/abonas/kubeclient/pull/78) ([jimmidyson](https://github.com/jimmidyson))

## [v0.1.14](https://github.com/abonas/kubeclient/tree/v0.1.14) (2015-05-11)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.13...v0.1.14)

**Merged pull requests:**

- move api valid checks to common [\#76](https://github.com/abonas/kubeclient/pull/76) ([abonas](https://github.com/abonas))
- client: improve api\_valid check with version [\#75](https://github.com/abonas/kubeclient/pull/75) ([simon3z](https://github.com/simon3z))

## [v0.1.13](https://github.com/abonas/kubeclient/tree/v0.1.13) (2015-05-05)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.12...v0.1.13)

**Closed issues:**

- DELETE on v1beta3 must include namespace in the url  [\#61](https://github.com/abonas/kubeclient/issues/61)

**Merged pull requests:**

- Add assertRequest checks to tests [\#74](https://github.com/abonas/kubeclient/pull/74) ([abonas](https://github.com/abonas))
- Fix \#61 add namespace to url when delete an entity \(except node, namespa... [\#73](https://github.com/abonas/kubeclient/pull/73) ([abonas](https://github.com/abonas))
- remove camelized resource names [\#72](https://github.com/abonas/kubeclient/pull/72) ([abonas](https://github.com/abonas))

## [v0.1.12](https://github.com/abonas/kubeclient/tree/v0.1.12) (2015-04-28)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.11...v0.1.12)

**Closed issues:**

- GET a single entity must include namespace in the url [\#51](https://github.com/abonas/kubeclient/issues/51)
- POST on v1beta3 must include namespace in the url [\#36](https://github.com/abonas/kubeclient/issues/36)

**Merged pull requests:**

- fix label param documentation in readme [\#71](https://github.com/abonas/kubeclient/pull/71) ([abonas](https://github.com/abonas))
- fix \#51 add namespace to url of GET single entity calls [\#70](https://github.com/abonas/kubeclient/pull/70) ([abonas](https://github.com/abonas))
- Fixed name of label selector parameter [\#69](https://github.com/abonas/kubeclient/pull/69) ([stephenjlevy](https://github.com/stephenjlevy))
- Fix SSL support for api validation [\#68](https://github.com/abonas/kubeclient/pull/68) ([simon3z](https://github.com/simon3z))
- Fix \#36 - add namespace to creation and update urls [\#67](https://github.com/abonas/kubeclient/pull/67) ([abonas](https://github.com/abonas))

## [v0.1.11](https://github.com/abonas/kubeclient/tree/v0.1.11) (2015-04-08)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.10...v0.1.11)

**Merged pull requests:**

- bumpver0.1.11 [\#66](https://github.com/abonas/kubeclient/pull/66) ([abonas](https://github.com/abonas))
- limit recursive open struct version [\#65](https://github.com/abonas/kubeclient/pull/65) ([abonas](https://github.com/abonas))
- watches: ruby http client uses verify\_mode [\#64](https://github.com/abonas/kubeclient/pull/64) ([simon3z](https://github.com/simon3z))
- Added automatic inclusion of object kind and api version for create requ... [\#58](https://github.com/abonas/kubeclient/pull/58) ([stephenjlevy](https://github.com/stephenjlevy))

## [v0.1.10](https://github.com/abonas/kubeclient/tree/v0.1.10) (2015-04-07)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.9...v0.1.10)

**Merged pull requests:**

- limit rubocop version [\#63](https://github.com/abonas/kubeclient/pull/63) ([abonas](https://github.com/abonas))
- fix new rubocop 0.30 offenses [\#62](https://github.com/abonas/kubeclient/pull/62) ([abonas](https://github.com/abonas))
- change service tests to multi ports [\#60](https://github.com/abonas/kubeclient/pull/60) ([abonas](https://github.com/abonas))
- rename id to name due to rename in k8s [\#59](https://github.com/abonas/kubeclient/pull/59) ([abonas](https://github.com/abonas))

## [v0.1.9](https://github.com/abonas/kubeclient/tree/v0.1.9) (2015-04-01)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.8...v0.1.9)

**Merged pull requests:**

- fix version example in readme [\#57](https://github.com/abonas/kubeclient/pull/57) ([abonas](https://github.com/abonas))
- Adding a common client module and class. [\#56](https://github.com/abonas/kubeclient/pull/56) ([abonas](https://github.com/abonas))
- fix method name in readme [\#55](https://github.com/abonas/kubeclient/pull/55) ([abonas](https://github.com/abonas))

## [v0.1.8](https://github.com/abonas/kubeclient/tree/v0.1.8) (2015-03-26)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.7...v0.1.8)

**Closed issues:**

- Labels need to be renamed to label-selector [\#44](https://github.com/abonas/kubeclient/issues/44)
- Add a "connection check" method on api root [\#40](https://github.com/abonas/kubeclient/issues/40)
- Add defaults when kubeclient is initialized [\#38](https://github.com/abonas/kubeclient/issues/38)
- 757: unexpected token at '404: Page Not Found' happens when having a 404 error  [\#35](https://github.com/abonas/kubeclient/issues/35)

**Merged pull requests:**

- Add Kubeclient\#api\_valid? [\#54](https://github.com/abonas/kubeclient/pull/54) ([Fryguy](https://github.com/Fryguy))
- rename exception method [\#53](https://github.com/abonas/kubeclient/pull/53) ([abonas](https://github.com/abonas))
- refactor to keep version separate from uri [\#52](https://github.com/abonas/kubeclient/pull/52) ([abonas](https://github.com/abonas))
- refactor rest\_client method [\#50](https://github.com/abonas/kubeclient/pull/50) ([abonas](https://github.com/abonas))
- remove v1beta1 mention leftovers [\#49](https://github.com/abonas/kubeclient/pull/49) ([abonas](https://github.com/abonas))
- Fix travis badge to show master status [\#48](https://github.com/abonas/kubeclient/pull/48) ([abonas](https://github.com/abonas))
- Add method to retrieve the api versions from server [\#47](https://github.com/abonas/kubeclient/pull/47) ([abonas](https://github.com/abonas))
- Fix \#44 rename label param field [\#46](https://github.com/abonas/kubeclient/pull/46) ([abonas](https://github.com/abonas))
- Remove support of v1beta1 [\#45](https://github.com/abonas/kubeclient/pull/45) ([abonas](https://github.com/abonas))
- Fix \#35 Handle exceptions with non jsonized message [\#43](https://github.com/abonas/kubeclient/pull/43) ([abonas](https://github.com/abonas))
- Fix \#38 add default path and version [\#42](https://github.com/abonas/kubeclient/pull/42) ([abonas](https://github.com/abonas))
- fix Rubocop issue introduced in pr 39 [\#41](https://github.com/abonas/kubeclient/pull/41) ([abonas](https://github.com/abonas))
- move dynamically defined classes under `Kubeclient` [\#39](https://github.com/abonas/kubeclient/pull/39) ([tenderlove](https://github.com/tenderlove))
- switch EntityList from an Array subclass to a delegate [\#37](https://github.com/abonas/kubeclient/pull/37) ([tenderlove](https://github.com/tenderlove))

## [v0.1.7](https://github.com/abonas/kubeclient/tree/v0.1.7) (2015-03-10)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.6...v0.1.7)

**Merged pull requests:**

- add test for empty items list [\#34](https://github.com/abonas/kubeclient/pull/34) ([abonas](https://github.com/abonas))
- add test helper [\#32](https://github.com/abonas/kubeclient/pull/32) ([abonas](https://github.com/abonas))
- add minimal support for labels [\#26](https://github.com/abonas/kubeclient/pull/26) ([kazegusuri](https://github.com/kazegusuri))

## [v0.1.6](https://github.com/abonas/kubeclient/tree/v0.1.6) (2015-03-05)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.5...v0.1.6)

**Merged pull requests:**

- lib: renaming watch to watch\_notice for consistency [\#31](https://github.com/abonas/kubeclient/pull/31) ([simon3z](https://github.com/simon3z))
- define entity class definitions dynamically [\#29](https://github.com/abonas/kubeclient/pull/29) ([abonas](https://github.com/abonas))

## [v0.1.5](https://github.com/abonas/kubeclient/tree/v0.1.5) (2015-03-04)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.4...v0.1.5)

**Merged pull requests:**

- update readme [\#28](https://github.com/abonas/kubeclient/pull/28) ([abonas](https://github.com/abonas))
- add support for namespace entity [\#27](https://github.com/abonas/kubeclient/pull/27) ([abonas](https://github.com/abonas))
- Extract dynamically defined method content to real methods [\#15](https://github.com/abonas/kubeclient/pull/15) ([Fryguy](https://github.com/Fryguy))

## [v0.1.4](https://github.com/abonas/kubeclient/tree/v0.1.4) (2015-02-19)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.3...v0.1.4)

**Merged pull requests:**

- release: kubeclient-0.1.4 [\#25](https://github.com/abonas/kubeclient/pull/25) ([simon3z](https://github.com/simon3z))
- client: prevent watches read\_timeout on inactivity [\#24](https://github.com/abonas/kubeclient/pull/24) ([simon3z](https://github.com/simon3z))
- client: add support for ssl connections [\#23](https://github.com/abonas/kubeclient/pull/23) ([simon3z](https://github.com/simon3z))
- client: support URI objects as api\_endpoint [\#22](https://github.com/abonas/kubeclient/pull/22) ([simon3z](https://github.com/simon3z))
- Add support to stop watching entities [\#21](https://github.com/abonas/kubeclient/pull/21) ([simon3z](https://github.com/simon3z))
- client: add support for kubernetes endpoints [\#16](https://github.com/abonas/kubeclient/pull/16) ([simon3z](https://github.com/simon3z))
- build: add travis continuous integration support [\#13](https://github.com/abonas/kubeclient/pull/13) ([simon3z](https://github.com/simon3z))
- Add Travis support and badges [\#11](https://github.com/abonas/kubeclient/pull/11) ([Fryguy](https://github.com/Fryguy))

## [v0.1.3](https://github.com/abonas/kubeclient/tree/v0.1.3) (2015-02-15)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.2...v0.1.3)

## [v0.1.2](https://github.com/abonas/kubeclient/tree/v0.1.2) (2015-02-15)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.1...v0.1.2)

**Merged pull requests:**

- limit ruby version to 2 and up, increase gem version [\#14](https://github.com/abonas/kubeclient/pull/14) ([abonas](https://github.com/abonas))
- DRY up exception handling [\#12](https://github.com/abonas/kubeclient/pull/12) ([Fryguy](https://github.com/Fryguy))
- client: autodetect entity list resourceVersion [\#10](https://github.com/abonas/kubeclient/pull/10) ([simon3z](https://github.com/simon3z))
- rake: add rubocop execution target [\#9](https://github.com/abonas/kubeclient/pull/9) ([simon3z](https://github.com/simon3z))
- Fix rubocop offenses [\#8](https://github.com/abonas/kubeclient/pull/8) ([simon3z](https://github.com/simon3z))
- Test fixes [\#7](https://github.com/abonas/kubeclient/pull/7) ([simon3z](https://github.com/simon3z))
- client: add event kubernetes entity [\#6](https://github.com/abonas/kubeclient/pull/6) ([simon3z](https://github.com/simon3z))
- add support for watching entities [\#5](https://github.com/abonas/kubeclient/pull/5) ([simon3z](https://github.com/simon3z))
- switch to functional style iteration [\#4](https://github.com/abonas/kubeclient/pull/4) ([tenderlove](https://github.com/tenderlove))
- remove explicit local variable assignment [\#3](https://github.com/abonas/kubeclient/pull/3) ([tenderlove](https://github.com/tenderlove))

## [v0.1.1](https://github.com/abonas/kubeclient/tree/v0.1.1) (2015-01-22)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/abonas/kubeclient/tree/v0.1.0) (2015-01-22)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.0.9...v0.1.0)

## [v0.0.9](https://github.com/abonas/kubeclient/tree/v0.0.9) (2015-01-22)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.0.8...v0.0.9)

## [v0.0.8](https://github.com/abonas/kubeclient/tree/v0.0.8) (2015-01-22)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.0.7...v0.0.8)

## [v0.0.7](https://github.com/abonas/kubeclient/tree/v0.0.7) (2015-01-22)
[Full Changelog](https://github.com/abonas/kubeclient/compare/v0.0.6...v0.0.7)

**Merged pull requests:**

- use `send` instead of getting the method and calling it [\#2](https://github.com/abonas/kubeclient/pull/2) ([tenderlove](https://github.com/tenderlove))
- fix method visibility [\#1](https://github.com/abonas/kubeclient/pull/1) ([tenderlove](https://github.com/tenderlove))

## [v0.0.6](https://github.com/abonas/kubeclient/tree/v0.0.6) (2015-01-13)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*