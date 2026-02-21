# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

MODULES_KERNEL_MIN=6.12
MODULES_KERNEL_MAX=7.0

COMMIT="1cf5a3a4418a5ebdf219b6dacbd4b14e3bb4f5ba"

DESCRIPTION="CIX Mali GPU driver (fork)"
HOMEPAGE="https://github.com/000exploit/cix-gpu-kmd"
SRC_URI="
	https://github.com/000exploit/cix-gpu-kmd/archive/${COMMIT}.tar.gz -> ${P}.tar.gz
"
S="${WORKDIR}/cix-gpu-kmd-${COMMIT}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* ~arm64"


pkg_setup() {
	get_version
	require_configured_kernel

	local CONFIG_CHECK="
		DRM
		~!DRM_PANTHOR
	"

	local ERROR_DRM_PANTHOR="CONFIG_DRM_PANTHOR: is set, and it may prevent
	mali_kbase from loading without blacklisting 'panthor' explicitly, e.g. in ${EPREFIX}/etc/modprobe.d/"

	if [[ KV_MAJOR -ge 6 && KV_MINOR -ge 17 ]]; then
		ewarn "Kernel 6.17 changed the page migration movable_ops API to a"
		ewarn "page-type-based scheme. Instead of fixing the actual problem,"
		ewarn "Google decided to stub-out these APIs until it's resolved"
		ewarn "on the ARM's side. Driver may fail."
	fi

	linux-mod-r1_pkg_setup
}

src_prepare() {
	default
}

src_compile() {
	local modlist=(
		mali_kbase=gpu/arm/midgard::drivers/gpu/arm/midgard
		protected_memory_allocator=base/arm/protected_memory_allocator::drivers/base/arm/protected_memory_allocator
		memory_group_manager=base/arm/memory_group_manager::drivers/base/arm/memory_group_manager
	)
	local modargs=(
		KERNEL_SRC=/lib/modules/${KV_FULL}/build
		CONFIG_MALI_BASE_MODULES=y
		CONFIG_MALI_MEMORY_GROUP_MANAGER=y
		CONFIG_MALI_PROTECTED_MEMORY_ALLOCATOR=y
		CONFIG_MALI_PLATFORM_NAME="sky1"
		CONFIG_MALI_CSF_SUPPORT=y
		CONFIG_MALI_CIX_POWER_MODEL=y
	)

	linux-mod-r1_src_compile
}
