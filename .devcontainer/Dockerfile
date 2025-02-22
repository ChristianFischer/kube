FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt update \
    && apt install -y \
        sshpass


RUN <<EOT bash
    set -ex

    # add alias k = kubectl
    echo -e "\nalias k=kubectl\n" >> "/home/vscode/.bashrc"
    echo -e "\nalias k=kubectl\n" >> "/home/vscode/.zshrc"
EOT
