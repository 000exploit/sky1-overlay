# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

COMMIT="c6a90cd2fd4b8eae979396d5dabbd0544c226c76"

DESCRIPTION="User-mode Mali driver for CIX Sky1 platform"
HOMEPAGE="https://github.com/Sky1-Linux/sky1-gpu-support"
SRC_URI="
	https://github.com/Sky1-Linux/sky1-gpu-support/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
"
S="${WORKDIR}/sky1-gpu-support-${COMMIT}/cix-gpu-umd"

LICENSE="CIX-EULA"
SLOT="0"
IUSE="+opengl +egl wayland wsi X"
KEYWORDS="-* ~arm64"
RESTRICT="bindist mirror strip"

RDEPEND="
	egl? ( media-libs/libglvnd )
	opengl? ( media-libs/mesa[video_cards_zink] )
	wayland? ( dev-libs/wayland )
	X? (
		x11-libs/libX11
		x11-libs/libxcb
		x11-libs/libxshmfence
	)
	media-libs/vulkan-loader[wayland?,X?]
	x11-drivers/cix-gpu-kmd
"
DEPEND="${RDEPEND}"

pkg_pretend() {
	use arm64 || die "libmali only works on arm64"
}

src_prepare() {
	einfo "Correcting library paths"
	sed -i -E \
		"s|(\"library_path\"[[:space:]]*:[[:space:]]*\")([^\"]+\.so)(\")|\1${EPREFIX}/opt/cixgpu-pro/lib/aarch64-linux-gnu/\2\3|" \
		"usr/share/cix-gpu/vulkan/mali.json"
	sed -i -E \
		"s|(\"library_path\"[[:space:]]*:[[:space:]]*\")([^\"]+\.so)(\")|\1${EPREFIX}/opt/cixgpu-pro/lib/aarch64-linux-gnu/\2\3|" \
		"usr/share/cix-gpu/40_cix.json"
	sed -i -E \
		's|("library_path"[[:space:]]*:[[:space:]]*")[^"]+(")|\1libVkLayer_sky1_compat.so\2|' \
		"usr/share/cix-gpu/vulkan/VkLayer_sky1_compat.json"
	sed -i -E \
		's|("library_path"[[:space:]]*:[[:space:]]*")[^"]+(")|\1libVkLayer_window_system_integration.so\2|' \
		"usr/share/cix-gpu/vulkan/VkLayer_window_system_integration.json"
	default
}

src_install() {
	dodoc usr/share/doc/cix-gpu-umd/copyright

	doins -r opt/

	insinto usr/share/vulkan/icd.d
	doins usr/share/cix-gpu/vulkan/mali.json
	doins usr/share/cix-gpu/vulkan/VkLayer_sky1_compat.json
	dolib.so usr/share/cix-gpu/vulkan/libVkLayer_sky1_compat.so
	if use wsi; then # TODO: build from source
		doins usr/share/cix-gpu/vulkan/VkLayer_window_system_integration.json
		dolib.so usr/share/cix-gpu/vulkan/libVkLayer_window_system_integration.so
	fi
	if use egl; then
		insinto /usr/share/glvnd/egl_vendor.d
		doins usr/share/cix-gpu/40_cix.json
	fi

	dobin usr/bin/*
}

pkg_postinst() {
	ewarn "This proprietary driver may contain bugs, do not work with your"
	ewarn "configuration or randomly crash user apps. Do not report driver problems"
	ewarn "as it's not something that can be easily fixed. YOU AT YOUR OWN RISK!"
}
