#!/bin/bash

set -euo pipefail 
 
# shellcheck source=.expeditor/scripts/shared.sh 
source .expeditor/scripts/shared.sh 

branch="ci/cargo-update-$(date +"%Y%m%d%H%M%S")"
git checkout -b "$branch"

toolchain="$(get_toolchain)"

install_rustup
rustup install $toolchain

echo "--- :ruby: Install hub"
gem install hub

echo "--- :habicat: Installing and configuring build dependencies"
hab pkg install core/libsodium core/libarchive core/openssl core/zeromq


PKG_CONFIG_PATH="$(< $(hab pkg path core/libarchive)/PKG_CONFIG_PATH)"
PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(< $(hab pkg path core/libsodium)/PKG_CONFIG_PATH)"
PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(< $(hab pkg path core/openssl)/PKG_CONFIG_PATH)"
PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(< $(hab pkg path core/zeromq)/PKG_CONFIG_PATH)"

export PKG_CONFIG_PATH 

echo "--- :rust: Cargo Update"
cargo clean
cargo +"$toolchain" update

echo "--- :rust: Cargo Check"
cargo +"$toolchain" check --all --tests

git add Cargo.lock

git commit -s -m "Update Cargo.lock"

echo "--- :github: Open Pull Request"
hub pull-request --no-edit --draft

