local name = "rootfs";

local build(arch, distro) = {
    kind: "pipeline",
    name: distro + "-" + arch,

    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "bootstrap",
            image: "debian:buster-slim",
            commands: [
                "./bootstrap/bootstrap-" + distro + ".sh"
            ],
            privileged: true
        },
        {
            name: "build",
            image: "debian:buster-slim",
            commands: [
                "./build.sh " + distro + " " + arch
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
            name: "test",
            image: "python:3.8-slim-buster",
            commands: [
                "./test.sh " + distro + " " + arch
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
            name: "cleanup",
            image: "debian:buster-slim",
            commands: [
                "./cleanup.sh"
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
            ],
            when: {
              status: [ "failure", "success" ]
            }
        },
        {
            name: "publish to github",
            image: "plugins/github-release:1.0.0",
            settings: {
                api_key: {
                    from_secret: "github_token"
                },
                files: "rootfs-*.tar.gz",
                overwrite: true,
                file_exists: "overwrite"
            },
            when: {
                event: [ "tag" ]
            }
        },
        {
            name: "docker bootstrap",
            image: "debian:buster-slim",
            environment: {
                DOCKER_USERNAME: {
                    from_secret: "DOCKER_USERNAME"
                },
                DOCKER_PASSWORD: {
                    from_secret: "DOCKER_PASSWORD"
                }
            },
            when: {
                event: [ "tag" ]
            },
            commands: [
                "./docker/push-bootstrap.sh " + distro + " " + arch
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
            name: "docker platform",
            image: "debian:buster-slim",
            environment: {
                DOCKER_USERNAME: {
                    from_secret: "DOCKER_USERNAME"
                },
                DOCKER_PASSWORD: {
                    from_secret: "DOCKER_PASSWORD"
                }
            },
            when: {
                event: [ "tag" ]
            },
            commands: [
                "./docker/push-platform.sh " + distro + " " + arch
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
            name: "artifact",
            image: "appleboy/drone-scp",
            settings: {
                host: {
                    from_secret: "artifact_host"
                },
                username: "artifact",
                key: {
                    from_secret: "artifact_key"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + distro + "-" + arch,
                source: [
                    "integration/log/*",
                    "log/*",
                    "rootfs-" + distro + "-" + arch + ".tar.gz"
                ]
            },
            when: {
              status: [ "failure", "success" ]
            }
        }
    ],
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
    build(arch, distro)
    for arch in [
       "arm",
       "amd64",
       "arm64"
    ]
    for distro in ["buster"]
]

