#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

version=0.3.1
commit=1a4716cde794a59928d9d9fc15f2afc7a95de360
source_root="${AFTER_RAIN_QUICKSHELL_SOURCE:-$HOME/src/quickshell-v$version}"
install_prefix="${AFTER_RAIN_QUICKSHELL_PREFIX:-$HOME/.local}"
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
multiarch=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
deps_root="$source_root/.after-rain-deps"
deps_prefix="$deps_root/root/usr"
build_root="$source_root/build-after-rain-release"

if [[ ! -d "$source_root/.git" ]]; then
  mkdir -p "$(dirname -- "$source_root")"
  git clone --branch "v$version" --depth 1 \
    https://github.com/quickshell-mirror/quickshell.git "$source_root"
fi

actual_commit=$(git -C "$source_root" rev-parse HEAD)
if [[ "$actual_commit" != "$commit" ]]; then
  echo "Refusing to build unexpected Quickshell commit: $actual_commit" >&2
  exit 2
fi

packages=(
  libcli11-dev libqt6shadertools6 qt6-base-private-dev
  qt6-declarative-private-dev qt6-shader-baker qt6-shadertools-dev
  qt6-wayland-private-dev
)
missing=()
for package in "${packages[@]}"; do
  dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' || missing+=("$package")
done

if (( ${#missing[@]} )); then
  echo "Using an isolated user build prefix for: ${missing[*]}"
  mkdir -p "$deps_root/packages" "$deps_root/root"
  (
    cd "$deps_root/packages"
    apt download "${missing[@]}"
    for archive in ./*.deb; do
      dpkg-deb -x "$archive" "$deps_root/root"
    done
    sha256sum ./*.deb > "$deps_root/SHA256SUMS"
  )
fi

cmake_overlay="$deps_root/redirect-private-headers.cmake"
sed -e "s|@DEPENDENCY_PREFIX@|$deps_prefix|g" \
  -e "s|@DEB_HOST_MULTIARCH@|$multiarch|g" \
  "$repo_root/scripts/quickshell-user-prefix.cmake.in" > "$cmake_overlay"

cmake_args=(
  -GNinja -S "$source_root" -B "$build_root"
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
  -DCMAKE_INSTALL_PREFIX="$install_prefix"
  -DINSTALL_QML_PREFIX="lib/$multiarch/qt6/qml"
  '-DDISTRIBUTOR=After Rain source build'
  -DCRASH_HANDLER=OFF -DUSE_JEMALLOC=OFF -DSCREENCOPY=OFF
  -DX11=OFF -DI3=OFF -DSERVICE_PIPEWIRE=OFF -DSERVICE_PAM=OFF
  -DSERVICE_POLKIT=OFF -DSERVICE_GREETD=OFF -DSERVICE_UPOWER=OFF
  -DBLUETOOTH=OFF -DNETWORK=OFF
)

if (( ${#missing[@]} )); then
  cmake_args+=(
    -DCMAKE_PROJECT_INCLUDE="$cmake_overlay"
    -DQt6ShaderTools_DIR="$deps_prefix/lib/$multiarch/cmake/Qt6ShaderTools"
    -DQt6ShaderToolsTools_DIR="$deps_prefix/lib/$multiarch/cmake/Qt6ShaderToolsTools"
    -DCLI11_DIR="$deps_prefix/share/cmake/CLI11"
  )
  export CPLUS_INCLUDE_PATH="$deps_prefix/include:$deps_prefix/include/$multiarch/qt6"
  export LD_LIBRARY_PATH="$deps_prefix/lib/$multiarch${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

cmake "${cmake_args[@]}"
cmake --build "$build_root" --parallel "${AFTER_RAIN_BUILD_JOBS:-4}"
cmake --install "$build_root"

if [[ -d "$deps_prefix/lib/$multiarch" ]]; then
  mkdir -p "$install_prefix/lib/$multiarch"
  cp -a "$deps_prefix/lib/$multiarch/"libQt6ShaderTools.so* "$install_prefix/lib/$multiarch/"
fi

export LD_LIBRARY_PATH="$install_prefix/lib/$multiarch${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
"$install_prefix/bin/qs" --version
printf 'Quickshell %s installed from %s at %s\n' "$version" "$commit" "$install_prefix"
