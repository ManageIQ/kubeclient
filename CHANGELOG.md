# Changelog

Notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

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
