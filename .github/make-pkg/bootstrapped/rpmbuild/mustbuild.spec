Name:           mustbuild
Version:        VERSION
Release:        1%{?dist}
Summary:        Mustbuild generic build system

License:        Apache-2.0
URL:            https://github.com/oreiche/mustbuild
Source0:        mustbuild-VERSION.tar.gz

BuildRequires:  make, BUILD_DEPENDS
Recommends:     python3, bash-completion, git >= 2.29

%description
Mustbuild is a friendly fork of Justbuild. It is is maintained as a patch
series. This fork introduces extensions that mainly focus on improving usability
while being fully compatible with existing Justbuild projects.


%global debug_package %{nil}
%global _build_id_links none


%prep
%autosetup


%build
make -f rpmbuild/mustbuild.makefile clean
make -f rpmbuild/mustbuild.makefile all


%install
make -f rpmbuild/mustbuild.makefile DESTDIR=$RPM_BUILD_ROOT install


%files
%license LICENSE
%{_bindir}/*
%{_datadir}/bash-completion/completions/*
%{_mandir}/man1/*
%{_mandir}/man5/*


%changelog
* Sun Apr 14 2024 Oliver Reiche <oliver.reiche@gmail.com>
- Initial release
