# Releasing Kubeclient

## Versioning
Kubeclient release versioning follows [SemVer](https://semver.org/).
At some point in time it is decided to release version x.y.z.
Prerequisite: A [changelog](CHANGELOG.md) is generated & merged into the release branch.

```bash
RUBYGEMS_USERNAME=bob
RELEASE_BRANCH="master"
RELEASE_VERSION="x.y.z"
GIT_REMOTE="origin"
GIT_UPSTREAM="upstream"

#
# Install the release gem
#At this point Open & merge a PR in github.
gem install gem-release

#
# Checking out the release branch
#
git fetch $GIT_UPSTREAM
git checkout $GIT_UPSTREAM/$RELEASE_BRANCH -b $RELEASE_BRANCH
git status # Make sure there are no local changes

#
# Preparing to release
#
bundle install
bundle exec rake test rubocop

#
# Grabbing an authentication token for rubygems.org api
#
curl -u $RUBYGEMS_USERNAME https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials; chmod 0600 ~/.gem/credentials

cat ~/.gem/credentials
---
:rubygems_api_key: ****

#
# Bumping the gem's version can be done manually, or by using
#
gem bump --version $RELEASE_VERSION
git show # View version bump change.

git push $GIT_REMOTE $RELEASE_BRANCH

#
# At this point Open & merge a PR in github.
#

git pull --ff-only $GIT_UPSTREAM

#
# In github, generate a new release and make sure you have the tag locally.
#

#
# Release the gem
#
gem release
```
