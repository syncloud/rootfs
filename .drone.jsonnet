local build(arch) = {
    kind: "pipeline",
    name: arch,

    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "bootstrap",
            image: "syncloud/build-deps-" + arch,
            environment: {
                ARTIFACT_SSH_KEY: {
                    from_secret: "ARTIFACT_SSH_KEY"
                },
                DOCKER_USERNAME: {
                    from_secret: "DOCKER_USERNAME"
                },
                DOCKER_PASSWORD: {
                    from_secret: "DOCKER_PASSWORD"
                }
            },
            commands: [
                "./bootstrap/bootstrap.sh " + arch,
                "./upload-artifact.sh bootstrap-" + arch + ".tar.gz",
                "./docker/build-bootstrap.sh " + arch
            ],
            privileged: true,
            volumes: [
                {
                    name: "docker",
                    path: "/usr/bin/docker"
                },
                {
                    name: "docker.sock",
                    path: "/var/run/docker.sock"
                }
            ]
        },
        {
            name: "rootfs",
            image: "syncloud/build-deps-" + arch,
            commands: [
                "./rootfs.sh stable stable " + arch
            ],
            privileged: true,
            network_mode: "host",
            volumes: [
                {
                    name: "docker",
                    path: "/usr/bin/docker"
                },
                {
                    name: "docker.sock",
                    path: "/var/run/docker.sock"
                }
            ]
        },
        {
            name: "rootfs-ci-artifact",
            image: "syncloud/build-deps-" + arch,
            environment: {
                ARTIFACT_SSH_KEY: {
                    from_secret: "ARTIFACT_SSH_KEY"
                },
            },
            commands: [
                "./upload-artifact.sh integration/log ci/$DRONE_BUILD_NUMBER-syncloud-$(dpkg --print-architecture)"
            ],
            when: {
              status: [ "failure", "success" ]
            }
        },
        {
            name: "upload-artifact",
            image: "syncloud/build-deps-" + arch,
            environment: {
                ARTIFACT_SSH_KEY: {
                    from_secret: "ARTIFACT_SSH_KEY"
                },
            },
            commands: [
                "./upload-artifact.sh rootfs-" + arch + ".tar.gz"
            ],
            privileged: true
        },
        {
            name: "upload-docker",
            image: "syncloud/build-deps-" + arch,
            environment: {
                DOCKER_USERNAME: {
                    from_secret: "DOCKER_USERNAME"
                },
                DOCKER_PASSWORD: {
                    from_secret: "DOCKER_PASSWORD"
                }
            },
            commands: [
                "./docker/build-rootfs.sh " + arch,
                "./docker/build-systemd.sh " + arch
            ],
            privileged: true,
            network_mode: "host",
            volumes: [
                {
                    name: "docker",
                    path: "/usr/bin/docker"
                },
                {
                    name: "docker.sock",
                    path: "/var/run/docker.sock"
                }
            ]
        }
    ],
    services: [{
        name: "syncloud",
        image: "syncloud/systemd-" + arch,
        privileged: true,
        volumes: [
            {
                name: "dbus",
                path: "/var/run/dbus"
            }
        ]
    }],
    volumes: [
        {
            name: "dbus",
            host: {
                path: "/var/run/dbus"
            }
        },
        {
            name: "docker",
            host: {
                path: "/usr/bin/docker"
            }
        },
        {
            name: "docker.sock",
            host: {
                path: "/var/run/docker.sock"
            }
        }
    ]
};

[
   build("arm"),
   build("amd64")
]