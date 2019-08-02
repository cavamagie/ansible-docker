FROM debian:stretch
USER root
CMD ["bash"]
ENV DEBIAN_FRONTEND noninteractive
ENV ANSIBLE_HOME /home/ansible
ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV DEFAULT_LOCAL_TMP /tmp
ENV DEFAULT_LOCAL_TEMP /tmp
ENV remote_tmp /tmp
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library
ENV pip_packages "ansible cryptography"

ARG ansible_user=ansible
ARG ansible_group=ansible
ARG ansible_uid=1001
ARG ansible_gid=1001

# Install dependencies.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       sudo systemd \
       build-essential wget libffi-dev libssl-dev \
       python-pip python-dev python-setuptools python-wheel \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean \
    && wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py

# Install Ansible via pip.
RUN pip install $pip_packages


# Install Ansible inventory file.
RUN mkdir -p /etc/ansible
RUN mkdir -p /.ansible/tmp
RUN echo "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

RUN groupadd -g ${ansible_gid} ${ansible_group} \
    && useradd -d "$ANSIBLE_HOME" -u ${ansible_uid} -g ${ansible_gid} -m -s /bin/bash ${ansible_user} \
    # Add jenkins and ansible to sudoers with no password
    && echo "jenkins        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/jenkins \
    && echo "ansible        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/ansible

COPY ansible.cfg /etc/ansible/.
USER ansible
WORKDIR /ansible/playbooks
#VOLUME ["/sys/fs/cgroup"]
#CMD ["/lib/systemd/systemd"]
