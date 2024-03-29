local distro = 'CentOS-8';
local distro_name = 'CentOS 8';
local distro_docker = 'centos:centos8';

local submodules = {
    name: 'submodules',
    image: 'drone/git',
    commands: ['git fetch --tags', 'git submodule update --init --recursive --depth=1'],
};

local dnf(arch) = 'dnf -y --setopt install_weak_deps=False --setopt cachedir=/cache/' + distro + '/' + arch + '/${DRONE_STAGE_MACHINE} ';

local rpm_pipeline(image, buildarch='amd64', rpmarch='x86_64', jobs=6) = {
    kind: 'pipeline',
    type: 'docker',
    name: distro_name + ' (' + rpmarch + ')',
    platform: { arch: buildarch },
    steps: [
        submodules,
        {
            name: 'build',
            image: image,
            environment: {
                SSH_KEY: { from_secret: 'SSH_KEY' },
                RPM_BUILD_NCPUS: jobs,
            },
            commands: [
                'echo "Building on ${DRONE_STAGE_MACHINE}"',
                dnf(rpmarch) + 'clean packages',
                dnf(rpmarch) + 'distro-sync',
                dnf(rpmarch) + 'install epel-release dnf-plugins-core',
                dnf(rpmarch) + 'config-manager --add-repo https://rpm.oxen.io/centos/oxen.repo',
                dnf(rpmarch) + 'config-manager --set-enabled powertools',
                dnf(rpmarch) + 'install rpm-build python3-pip git make wget gcc openssl-devel gzip ccache',
                'pip3 install git-archive-all',
                'pkg_src_base="$(rpm -q --queryformat=\'%{NAME}-%{VERSION}\n\' --specfile SPECS/lokinet.spec | head -n 1)"',
                'git-archive-all --prefix $pkg_src_base/ SOURCES/$pkg_src_base.src.tar.gz',
                'wget https://curl.haxx.se/download/curl-7.79.1.tar.gz',
                'gunzip -c curl-7.79.1.tar.gz | tar xvf -',
                'cd curl-7.79.1',
                './configure --with-ssl',
                'make',
                'make install',
                'cd ..',
                dnf(rpmarch) + 'builddep --spec SPECS/lokinet.spec',
                'if [ -n "$CCACHE_DIR" ]; then mkdir -pv ~/.cache; ln -sv "$CCACHE_DIR" ~/.cache/ccache; fi',
                'rpmbuild --define "_topdir $(pwd)" -bb SPECS/lokinet.spec',
                './SPECS/ci-upload.sh ' + distro + ' ' + rpmarch,
            ],
        },
    ],
};

[
    rpm_pipeline(distro_docker),
    // rpm_pipeline('arm64v8/' + distro_docker, buildarch='arm64', rpmarch='aarch64', jobs=4),
]
