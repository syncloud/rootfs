local name = "rootfs";

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
            commands: [
                "./bootstrap/bootstrap.sh " + arch
            ],
            privileged: true
        },
        {
            name: "rootfs",
            image: "syncloud/build-deps-" + arch,
            commands: [
                "./rootfs.sh " + arch
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
                "./docker/build-systemd.sh " + arch,
                "./docker/build-bootstrap.sh " + arch
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
                password: {
                    from_secret: "artifact_password"
                },
                timeout: "2m",
                command_timeout: "2m",
                target: "/home/artifact/repo/" + name + "/${DRONE_BUILD_NUMBER}-" + arch,
                source: [
                    "integration/log/*",
                    "bootstrap-" + arch + ".tar.gz",
                    "rootfs-" + arch + ".tar.gz"
                ],
		             strip_components: 2
            },
            when: {
              status: [ "failure", "success" ]
            }
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
