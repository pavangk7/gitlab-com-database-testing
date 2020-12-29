### Runner setup


```
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

apt-get upgrade
GITLAB_RUNNER_DISABLE_SKEL=true apt-get install gitlab-runner docker.io
```

1. Register runner (tags - see below): `gitlab-runner register`
1. Restart runner: `service gitlab-runner restart`

#### Worker

* Runner tag: `worker`
* Runner type: `docker`

The worker additionally runs a local docker registry:

1. Run docker registry: `docker run -d -p 5000:5000 --restart=always --name registry registry:2`

#### Builder

* Runner tag: `builder`
* Runner type: `shell`