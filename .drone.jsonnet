local name = "rootfs";
local distro = "buster";

local build(arch, dind) = [{
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
                "./bootstrap/bootstrap-" + distro + ".sh " + arch
            ],
            privileged: true
        },
        {
            name: "build",
            image: "docker:" + dind,
            commands: [
                "./build.sh " + distro + " " + arch
            ],
            volumes: [
         {
                    name: "dockersock",
                    path: "/var/run"
                }
            ]
        },
        {
            name: "test",
            image: "docker:" + dind,
            commands: [
                "./test.sh " + distro + " " + arch
            ],
            volumes: [
                {
                    name: "dockersock",
                    path: "/var/run"
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
            image: "appleboy/drone-scp:1.6.4",
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
services: [
            {
                name: "docker",
                image: "docker:" + dind,
                privileged: true,
                volumes: [
                    {
                        name: "dockersock",
                        path: "/var/run"
                    }
                ]
            }
],
    volumes: [
         {
                name: "dockersock",
                temp: {}
            }
    ]
}];

build("amd64", "20.10.21-dind") +
build("arm64", "19.03.8-dind") +
build("arm", "19.03.8-dind")
