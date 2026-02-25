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
IUSE="+egl +opencl +opengl wayland +wsi X"
KEYWORDS="-* ~arm64"
RESTRICT="bindist mirror strip" # EULA allows distribution, but it's better to not package it

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
	eerror "* * * WARNING * * *"
	eerror "Installation of this proprietary driver WILL BREAK open-source Mesa stack."
	eerror "DO NOT install it unless you know what you're doing."
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
	sed -i \
		"1s/^/${EPREFIX}/" \
		"usr/share/cix-gpu/mali.icd"

	einfo "Adding files"
	mkdir -p etc/ld.so.conf.d
	echo "${EPREFIX}/opt/cixgpu-pro/lib/aarch64-linux-gnu/" >> etc/ld.so.conf.d/00-cixgpu-pro.conf

	# blacklist everything related, open-source stack is already broken
	BLACKLIST_MODULES="panfrost panthor tyr"
	mkdir etc/modprobe.d
	for module in ${BLACKLIST_MODULES}; do
		echo "blacklist ${module}" >> etc/modprobe.d/10-mali.conf
	done

	default
}

src_install() {
	dodoc usr/share/doc/cix-gpu-umd/copyright

	doins -r opt/
	doins -r etc/

	insinto usr/share/vulkan/icd.d
	doins usr/share/cix-gpu/vulkan/mali.json

	if use egl; then
		insinto usr/share/glvnd/egl_vendor.d
		doins usr/share/cix-gpu/40_cix.json
	fi
	if use opencl; then
		insinto etc/OpenCL/vendors
		doins usr/share/cix-gpu/mali.icd
	fi

	insinto usr/share/vulkan/implicit_layer.d
	doins usr/share/cix-gpu/vulkan/VkLayer_sky1_compat.json
	dolib.so usr/share/cix-gpu/vulkan/libVkLayer_sky1_compat.so # TODO: build from source
	if use wsi; then # TODO: build from source
		doins usr/share/cix-gpu/vulkan/VkLayer_window_system_integration.json
		dolib.so usr/share/cix-gpu/vulkan/libVkLayer_window_system_integration.so
	fi

	insinto etc/modprobe.d
	doins etc/modprobe.d/10-mali.conf

	dobin usr/bin/*
}

pkg_postinst() {
	einfo "FIXME: Unless sources are patched, you need to place the correct firmware into"
	einfo "${EPREFIX}/lib/firmware manually. Example for '5th Gen' (v12):"
	einfo "	cp ${EROOT}/lib/firmware/arm/mali/arch12.8/mali_csffw.bin ${EPREFIX}/lib/firmware/"
	ewarn "* * * WARNING * * *"
	ewarn "This proprietary driver may contain bugs, do not work with your"
	ewarn "configuration or randomly crash user apps. Do not report driver problems"
	ewarn "as it's not something that can be easily fixed. YOU AT YOUR OWN RISK!"
}
