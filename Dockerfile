FROM debian:bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/kojott/claude-docker

ARG TARGETARCH
ARG NVM_VERSION=0.40.3
ARG NODE_VERSION=24

# System packages - just the minimum
RUN apt-get update && apt-get install -y --no-install-recommends \
    git tmux curl wget ca-certificates \
    build-essential make gcc g++ \
    sudo procps less locales \
    whiptail \
    openssh-client unzip tar gzip xz-utils xclip \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# dev user with passwordless sudo
RUN useradd -m -s /bin/bash -u 1000 -G sudo dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev

# NVM + Node.js (required for Claude Code)
USER dev
WORKDIR /home/dev
ENV NVM_DIR=/home/dev/.nvm
RUN curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
RUN bash -c ". $NVM_DIR/nvm.sh && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION}"

# Claude Code CLI
RUN bash -c ". $NVM_DIR/nvm.sh && npm install -g @anthropic-ai/claude-code"

# claude-gc (orphaned process cleanup) - download script directly, skip crontab/systemd setup
RUN mkdir -p /home/dev/.claude /home/dev/bin && \
    curl -fsSL https://raw.githubusercontent.com/kojott/claude-gc/main/cleanup.sh -o /home/dev/.claude/claude-gc.sh && \
    chmod +x /home/dev/.claude/claude-gc.sh && \
    ln -s /home/dev/.claude/claude-gc.sh /home/dev/bin/claude-gc

# cl session manager + tmux config
COPY --chown=dev:dev config/cl.sh /home/dev/bin/cl
COPY --chown=dev:dev config/tmux-cl.conf /home/dev/.tmux-cl.conf
RUN chmod +x /home/dev/bin/cl

# NVM PATH for login shells (profile.d runs before bashrc)
USER root
COPY config/profile-path.sh /etc/profile.d/00-claude-path.sh
RUN chmod +x /etc/profile.d/00-claude-path.sh

# MOTD + new-project
COPY config/motd.sh /etc/profile.d/claude-motd.sh
RUN chmod +x /etc/profile.d/claude-motd.sh
COPY --chown=dev:dev config/new-project.sh /usr/local/bin/new-project
RUN chmod +x /usr/local/bin/new-project

# bashrc additions
COPY config/bashrc-additions.sh /tmp/bashrc-additions.sh
RUN cat /tmp/bashrc-additions.sh >> /home/dev/.bashrc && rm /tmp/bashrc-additions.sh

# Scripts
COPY --chown=dev:dev scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chown=dev:dev scripts/init-wizard.sh /usr/local/bin/init-wizard
COPY --chown=dev:dev scripts/install-plugins.sh /usr/local/bin/install-plugins
COPY --chown=dev:dev scripts/setup-claude-settings.sh /tmp/setup-claude-settings.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/init-wizard /usr/local/bin/install-plugins

# Final setup - create /work and fix ownership before switching to dev
USER root
RUN mkdir -p /work && chown dev:dev /work
RUN chown -R dev:dev /home/dev

# Claude settings (base)
USER dev
RUN mkdir -p /home/dev/.claude /home/dev/bin && \
    bash /tmp/setup-claude-settings.sh

# Git defaults
RUN git config --global user.name "Claude Dev" && \
    git config --global user.email "dev@localhost" && \
    git config --global init.defaultBranch main

USER dev
WORKDIR /work

ENV TERM=xterm-256color \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    EDITOR=vim \
    NVM_DIR=/home/dev/.nvm \
    CLAUDE_CONFIG_DIR=/home/dev/.claude \
    PATH=/home/dev/.nvm/versions/node/v24.14.0/bin:/home/dev/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash"]
