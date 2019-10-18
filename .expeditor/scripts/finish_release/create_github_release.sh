#!/bin/bash

set -euo pipefail

# TODO: remove me once this function is available in shared.sh and we have published manifets
# Retrieves the current package manifest for the given environment.
#
# After GPG verifying the file, returns the JSON on standard output,
# suitable for piping into `jq`.
#
# e.g. manifest_for_environment acceptance | jq
manifest_for_environment() {
    # local environment_name="${1:?}"
    # curl --silent \
         # --remote-name \
         # "http://${s3_bucket_name}.s3.amazonaws.com/${environment_name}/latest/habitat/manifest.json"
    # curl --silent \
         # --remote-name \
         # "http://${s3_bucket_name}.s3.amazonaws.com/${environment_name}/latest/habitat/manifest.json.asc"
    # gpg_verify "manifest.json"
    cat "manifest.json"
}

# Prototype of what a curl-based release would look like. Prefer to use `hub` if possible 
# as that should handle our GH authentication correctly. This can be deleted 
# generate_gh_release_json() {
  # local release_info=$(manifest_for_environment "$1" | jq -r '.version + " " + .gitsha')
  # local version=$(cut -d' ' -f1 <<< $release_info)
  # local gitsha=$(cut -d' ' -f2 <<< $release_info)
#
  # cat << EOJ
  # {
    # "tag_name": "$version",
    # "target_commitish": "$gitsha",
    # "name": "$version",
    # "body": "",
    # "draft": true,
    # "prerelease": false
  # }
# EOJ
# }
#
# echo "curl --header 'Content-Type: application/json' \
  # --request POST \
  # --data '$(generate_gh_release_json 'dev')' \
  # curl https://api.github.com/repos/habitat-sh/habitat/releases"
#

gem install hub

release_info=$(manifest_for_environment 'dev' | jq -r '.version + " " + .gitsha')
version=$(cut -d' ' -f1 <<< $release_info)
gitsha=$(cut -d' ' -f2 <<< $release_info)

echo "hub release create --message \"$version\" --commitish \"$gitsha\" \"$version\""

