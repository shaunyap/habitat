#!/bin/bash

set -xeuo pipefail

# Currently, we build instances of the habitat/builder-worker package
# from the Builder repository *in this release pipeline*.
#
# As we have a build stage for each supported platform, we need to
# ensure that all are building from the exact same code. It would not
# be good to, say, start a Linux build, then have new code merge to
# the Builder repository, and then start building a Windows build.
#
# This would not be an issue if we were able to trigger a build of a
# pipeline in the Builder repository, but it's not clear it's worth
# the overhead at this point.

source .expeditor/scripts/release_habitat/shared.sh

# Output of this git command is like:
#
#     7b15c46e160a783905495a1c988a36d144385d27	refs/heads/master
sha="$(git ls-remote https://github.com/habitat-sh/builder master | cut -f1)"
echo "--- Using Builder code @ $sha"
set_builder_sha_metadata "${sha}"
