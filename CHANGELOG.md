# Changelog

Notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).
Kubeclient release versioning follows [SemVer](https://semver.org/).

## Unreleased

## 4.4.0 — 2019-05-03

### Added
- GCP configs with `user[auth-provider][name] == 'gcp'` will execute credential plugin (normally the `gcloud config config-helper` subcommand) when the config specifies it in `cmd-path`, `cmd-args` fields (similar to `exec` support).  This code path works without `googleauth` gem.  Otherwise, `GoogleApplicationDefaultCredentials` path will be tried as before. (#410)
- `AmazonEksCredentials` helper for obtaining a token to authenticate against Amazon EKS. This is not currently integrated in `Config`, you will need to invoke it yourself.  You'll need some aws gems that Kubeclient _does not_ include. (#404, #406)

### Changed
- OpenID Connect tokens which cannot be validaded because we cannot identify the key they were signed with will be considered expired and refreshed as usual. (#407)

## 4.3.0 — 2019-03-03

### Changed
- `GoogleApplicationDefaultCredentials` will now automatically be used by `Config` if the `user[auth-provider][name] == 'gcp'` in the provided context. Note that `user[exec]` is checked first in anticipation of this functionality being added to GCP sometime in the future. Kubeclient _does not_ include the required `googleauth` gem, so you will need to include it in your calling application. (#394)

### Added
- OpenID Connect credentials will automatically be used if the `user[auth-provider][name] == 'oidc'` in the provided context. Note that `user[exec]` is checked first. Kubeclient _does not_ include the required `openid_connect` gem, so you will need to include it in your calling application. (#396)

- Support for `json_patch_#{entity}` and `merge_patch_#{entity}`. `patch_#{entity}` will continue to use strategic merge patch. (#390)

## 4.2.2 — 2019-01-09

### Added
- New `http_max_redirects` option (#374).

### Changed
- Default max redirects for watch increased from 4 to 10, to match other verbs (#374).

## 4.2.1 — 2018-12-26

### Fixed
- For resources that contain dashes in name, there will be an attempt to resolve the method name based on singular name prefix or by replacing the dash in names with underscores (#383).

## 4.2.0 — 2018-12-20

### Added
- Support `user: exec: ...` credential plugins like in Go client (#363, #375).

### Security
- Really made `Kubeclient::Config.new(data, nil)` prevent external file lookups. (#372)
  README documented this since 3.1.1 (#334) but alas that was a lie — absolute paths always worked.
  Now this also prevents credential plugin execution.

  Even in this mode, using config from untrusted sources is not recommended.

This release included all changes up to 4.1.1, but NOT 4.1.2 which was branched off later (4.2.1 does include same fix).

## 4.1.2 — 2018-12-26

### Fixed
- For resources that contain dashes in name, there will be an attempt to resolve the method name based on singular name prefix or by replacing the dash in names with underscores (#382).

## 4.1.1 — 2018-12-17

### Fixed
- Fixed method names for non-suffix plurals such as y -> ies  (#377).

## 4.1.0 — 2018-11-28 — REGRESSION

This version broke method names where plural is not just adding a suffix, notably y -> ies (bug #376).

### Fixed
- Support custom resources with lowercase `kind` (#361).
- `create_security_context_constraint` now works (#366).
- `get_security_context_constraints.kind`, `get_endpoints.kind` are now plural as in kubernetes (#366).

### Added
- Add support for retrieving large lists of objects in chunks (#356).

## 4.0.0 — 2018-07-23

### Removed
- Bumped officially supported kubernetes versions to >= 1.3.
- Specifically `proxy_url` no longer works for <= 1.2 (#323).

### Fixed
- `proxy_url` now works for kubernetes 1.10 and later (#323).

### Changed
- Switched `http` gem dependency from 2.y to 3.y (#321).

## 3.1.2 — 2018-06-11

### Fixed
- Fixed `Kubeclient::Config.read` regression, no longer crashes on YAML timestamps (#338).

## 3.1.1 - 2018-06-01 — REGRESSION

In this version `Kubeclient::Config.read` raises Psych::DisallowedClass on legal yaml configs containing a timestamp, for example gcp access-token expiry (bug #337).

### Security
- Changed `Kubeclient::Config.read` to use `YAML.safe_load` (#334).

  Previously, could deserialize arbitrary ruby classes.  The risk depends on ruby classes available in the application; sometimes a class may have side effects - up to arbitrary code execution - when instantiated and/or built up with `x[key] = value` during YAML parsing.

  Despite this fix, using config from untrusted sources is not recommended.

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

- `as: raw` option for `get_*` methods returning a string (#262 via #271).

## 2.4.0 - 2017-05-10
