# Changelog

Notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).
Kubeclient release versioning follows [SemVer](https://semver.org/).

## 3.1.0 - 2018-05-27

### Fixed
- Fixed watch `.finish` sometimes caused `HTTP::ConnectionError` exception from the reading loop (#315).

### Added
- `get_pod_log` now has `timestamps`, `since_time` (#319) and `tail_lines` (#326) params.
- `Kubeclient::Config::Context#namespace` now set, if present in kubeconfig file (#308).
- Improved README directions for authenticating within a kubernetes cluster (#316).
- `Kubeclient::GoogleApplicationDefaultCredentials` helper for Google application default credentials (#213). Needs `googleauth` gem.
- New `as: :parsed` and `as: :parsed_symbolized` formats (#306).
- Allow setting default `as:` format for the whole client (#299, #305).
- Relaxed `recursive-open-struct` dependency to allow 1.1+ as well (#313).

## 3.0.0 - 2018-02-04
### Removed
- Dropped entity classes (`Kubeclient::Pod` etc.), only `Kubeclient::Resource` exists now (#292, #288).
- Ruby 2.0, 2.1 no longer supported (#253, #291).

### Fixed
- Added missing singular `get_security_context_constraint`, fixed `get_security_context_constraints` to mean plural (#261).
- Fixed `@http_proxy_uri` undefined warning (#261).
- Documentation fixes & improvements (#225, #229, #243, #296).

### Added
- `delete_options:` parameter to `delete_*` methods, useful for cascade delete (#267).
- `as: :raw` option for watch (#285).
- Now raises `Kubeclient::HttpError`.  Rescuing `KubeException` still works but is deprecated. (#195, #288)
  - 404 error raise `Kubeclient::ResourceNotFoundError`, a subclass of `HttpError` (#233).
- Include request info in exception message (#221).
- Ruby 2.4 and 2.5 are now supported & tested (#247, #295).

### Changed
- `Kubeclient::Config#context(nonexistent_context_name)` raises `KeyError` instead of `RuntimeError`.
- `update_*`, `delete_*`, `patch_*` now all return `RecursiveOpenStruct` consistently (#290).
- Many dependencies bumped (#204, #231, #253, #269).

## 2.5.2 - 2018-02-04
- Watch results are now `RecursiveOpenStruct` inside arrays too (#279).
- Fixed watch `.finish` sometimes caused `Errno::EBADF` exception from the reading loop (#280).
- Easing dependency version (#287, #301)

## 2.5.1 - 2017-10-12
No changes since 2.5.0, fixed packaging mistake.

## [2.5.0 - 2017-10-12 was YANKED]

### Added

- `as: raw` option for `get_*` methods returning a string (#262 via #271)

## 2.4.0 - 2017-05-10
