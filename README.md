### Runner setup


```
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

apt-get upgrade
GITLAB_RUNNER_DISABLE_SKEL=true apt-get install gitlab-runner docker.io
usermod -aG docker gitlab-runner
ufw allow ssh
ufw allow from 10.128.0.0/24 to any port 5000
ufw enable
```

#### GitLab Runner

1. Register runner (tags - see below): `gitlab-runner register`
1. Restart runner: `service gitlab-runner restart`

#### Docker

1. Add insecure docker registry in `/etc/docker/daemon.json`
```
{
  "insecure-registries" : ["10.128.0.19:5000"]
}
```
1. Reload docker `service docker reload`

#### Worker

* Runner tag: `worker`
* Runner type: `docker`

The worker additionally runs a local docker registry:

1. Run docker registry: `docker run -d -p 5000:5000 --restart=always --name registry registry:2`

The worker needs to allow containers to manage iptables - add this to `/etc/gitlab-runner/config.toml`:

```
[[runners]]
  [runners.docker]
    # ...
    cap_add = ["NET_ADMIN", "NET_RAW"]
```

#### Builder

* Runner tag: `builder`
* Runner type: `shell`


### Security

* NAT setup with Cloud NAT
