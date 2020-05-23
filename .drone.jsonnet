local name = "rootfs";

local build(arch, distro, snapd) = {
    kind: "pipeline",
    name: distro + "-" + arch + "-" + snapd,

    platform: {
        os: "linux",
        arch: arch
    },
    steps: [
        {
            name: "bootstrap",
            image: "syncloud/build-deps-" + arch,
            commands: [
                "./bootstrap/bootstrap-" + distro + ".sh"
            ],
            privileged: true
        },
        {
            name: "build",
            image: "syncloud/build-deps-" + arch,
            commands: [
                "./build.sh " + distro + " " + arch + " " + snapd
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
            image: "syncloud/build-deps-" + arch,
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
            image: "syncloud/build-deps-" + arch,
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
	if snapd == "stable" then
        {
            name: "docker",
            image: "syncloud/build-deps-" + arch,
            environment: {
                DOCKER_USERNAME: {
                    from_secret: "DOCKER_USERNAME"
                },
                DOCKER_PASSWORD: {
                    from_secret: "DOCKER_PASSWORD"
                }
            },
	    when: {
	    	branch: ["stable"]
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
        } else {},
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
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + distro + "-" + arch + "-" + snapd,
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
    build(arch, distro, snapd)
    for arch in ["arm", "amd64"]
    for distro in ["jessie", "buster"]
    for snapd in ["stable", "rc"]
]
