# Changelog

Notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## 2.5.2 - 2018-02-04
### Fixed
- Watch results are now `RecursiveOpenStruct` inside arrays too (#279).
- Fixed watch `.finish` sometimes caused `Errno::EBADF` exception from the reading loop (#280).
- Easing dependency version (#287, #301)  

## 2.5.1 - 2017-10-12
No changes since 2.5.0, fixed packaging mistake.

## [2.5.0 - 2017-10-12 was YANKED]

### Added

- `as: raw` option for `get_*` methods returning a string (#262 via #271)

## 2.4.0 - 2017-05-10
