FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt update \
    && apt install -y \
        iputils-ping \
        sshpass


RUN <<EOT bash
set -ex

# .bashrc
cat <<BASHRC >> /home/vscode/.bashrc
    if [ ! -f ~/.kube/completion.bash ]; then
        mkdir -p ~/.kube/
        kubectl completion bash > ~/.kube/completion.bash
    fi

    alias k=kubectl
    source ~/.kube/completion.bash
    complete -o default -F __start_kubectl k
BASHRC

cat <<ZSHRC >> /home/vscode/.zshrc
    if [ ! -f ~/.kube/completion.zsh  ]; then
        mkdir -p ~/.kube/
        kubectl completion zsh > ~/.kube/completion.zsh
    fi

    alias k=kubectl
    source ~/.kube/completion.zsh
    complete -o default -F __start_kubectl k
ZSHRC
EOT
