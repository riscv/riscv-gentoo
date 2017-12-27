# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit autotools eutils libtool multilib multilib-minimal toolchain-funcs

DESCRIPTION="a portable, high level programming interface to various calling conventions"
HOMEPAGE="https://sourceware.org/libffi/"
SRC_URI="ftp://sourceware.org/pub/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="riscv"
IUSE="debug pax_kernel static-libs test"

RDEPEND="abi_x86_32? ( !<=app-emulation/emul-linux-x86-baselibs-20130224-r1
		!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)] )"
DEPEND="test? ( dev-util/dejagnu )"

DOCS="ChangeLog* README"

ECONF_SOURCE=${S}

pkg_setup() {
	# Check for orphaned libffi, see https://bugs.gentoo.org/354903 for example
	if [[ ${ROOT} == "/" && ${EPREFIX} == "" ]] && ! has_version ${CATEGORY}/${PN}; then
		local base="${T}"/conftest
		echo 'int main() { }' > "${base}".c
		$(tc-getCC) -o "${base}" "${base}".c -lffi >&/dev/null
		if [ $? -eq 0 ]; then
			eerror "The linker reported linking against -lffi to be working while it shouldn't have."
			eerror "This is wrong and you should find and delete the old copy of libffi before continuing."
			die "The system is in inconsistent state with unknown libffi installed."
		fi
	fi
}

src_prepare() {
	sed -i -e 's:@toolexeclibdir@:$(libdir):g' Makefile.in || die #462814
	epatch "${FILESDIR}"/${PN}-3.2.1-o-tmpfile-eacces.patch #529044
	epatch "${FILESDIR}"/${PN}-3.2.1-complex_alpha.patch
	epatch "${FILESDIR}"/${PN}-3.1-darwin-x32.patch
	epatch "${FILESDIR}"/${PN}-3.2.1-complex-ia64.patch
	epatch "${FILESDIR}"/${P}-riscv-${PR}.patch
	epatch_user
	elibtoolize
	eautoreconf
}

multilib_src_configure() {
	use userland_BSD && export HOST="${CHOST}"
	econf \
		$(use_enable static-libs static) \
		$(use_enable pax_kernel pax_emutramp) \
		$(use_enable debug)
}

multilib_src_install_all() {
	prune_libtool_files
	einstalldocs
}
