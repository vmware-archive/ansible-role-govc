#!/bin/bash
# Copyright © 2017 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: MIT

set -e

containers=(
    "tompscanlan/photon-ansible-base"
    "ansible/ansible:fedora24"
    "ansible/ansible:ubuntu1204"
    "ansible/ansible:ubuntu1604"
    "ansible/ansible:opensuse42.2"
    "ansible/ansible:centos7"

    )
inits=(
    "/usr/lib/systemd/systemd"
    "/usr/lib/systemd/systemd"
    "/sbin/init"
    "/lib/systemd/systemd"
    "/usr/lib/systemd/systemd"
    "/usr/lib/systemd/systemd"
)
options=(
    "--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
    "--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
    ""
    "--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
    "--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
    "--privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro"
)

cleanup() {
    echo "Failed tests on $container"

    docker kill "$(cat ${container_id})"
}

trap cleanup EXIT

for ((i=0;i<${#containers[@]};++i)); do

    container="${containers[i]}"
    init="${inits[i]}"
    option="${options[i]}"
    container_id=$(mktemp)

    docker run  --rm  -d $option -v "$PWD:/etc/ansible/roles/ansible-role-govc" "$container" "$init" > "${container_id}"

    #docker exec "$(cat ${container_id})" bash -c 'pip install -U pip;'

    docker exec "$(cat ${container_id})" bash -c 'pip install ansible;'
    docker exec "$(cat ${container_id})" bash -c 'ansible-playbook /etc/ansible/roles/ansible-role-govc/tests/test.yml --syntax-check'
    docker exec "$(cat ${container_id})" bash -c 'ansible-playbook /etc/ansible/roles/ansible-role-govc/tests/test.yml -vv;'

    # verify govc installed
    docker exec "$(cat ${container_id})" bash -c '/tmp/govc version'
    docker exec "$(cat ${container_id})" bash -c '/usr/bin/govc version'
    docker kill "$(cat ${container_id})"
done

trap - EXIT

