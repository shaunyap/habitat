#!/bin/bash

# Builds habitat/builder-worker from the Builder repository
#
# We do this because the builder-worker depends on packages that we
# build in this release pipeline, and we would like to verify that
# they all work together properly *before* we release Habitat, rather
# than build-and-test *after*, as we have been doing.
#
# Yes, it's weird to pull in code from another repository to build in
# *this* repository's build pipeline. However, it's not clear at this
# point that building up the necessary cross-repository communication
# is worth the effort.

set -euo pipefail

source .expeditor/scripts/release_habitat/shared.sh

export HAB_AUTH_TOKEN="${PIPELINE_HAB_AUTH_TOKEN}"
export HAB_BLDR_URL="${PIPELINE_HAB_BLDR_URL}"

########################################################################

channel=$(get_release_channel)
echo "--- Channel: $channel - bldr url: $HAB_BLDR_URL"

declare -g hab_binary
install_release_channel_hab_binary "$BUILD_PKG_TARGET"
import_keys

echo "--- :zap: Cleaning up old studio, if present"
${hab_binary} studio rm

# Download builder code and, um, build
git clone https://github.com/habitat-sh/builder
cd builder

echo "--- :habicat: Building builder-worker"

HAB_BLDR_CHANNEL="${channel}" ${hab_binary} pkg build "components/builder-worker"
source results/last_build.env

echo "--- :habicat: Uploading ${pkg_ident:?} to ${HAB_BLDR_URL} in the '${channel}' channel"
${hab_binary} pkg upload \
              --channel="${channel}" \
              --auth="${HAB_AUTH_TOKEN}" \
              --no-build \
              "results/${pkg_artifact:?}"

echo "<br>* ${pkg_ident:?} (${BUILD_PKG_TARGET:?})" | buildkite-agent annotate --append --context "release-manifest"

set_target_metadata "${pkg_ident}" "${pkg_target}"
