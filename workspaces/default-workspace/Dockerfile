FROM codercom/enterprise-base:ubuntu

ARG DOTFILES_BRANCH='Rock/WSL'

USER root

RUN apt-get update && apt-get install -y build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils libffi-dev liblzma-dev python3-openssl gdb tree \
    redis-server zsh vim-tiny lld clang pkg-config libssl-dev postgresql pipx

RUN chsh -s $(which zsh) coder

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8     

WORKDIR /home/coder

ADD . /home/coder/dotfiles
RUN chown -R coder /home/coder/dotfiles

WORKDIR /home/coder/dotfiles

USER coder
RUN ./install

# Install pipx and ansible
RUN pipx ensurepath
RUN pipx install --include-deps ansible

WORKDIR /home/coder/downloads

# Setup go toolchain.
RUN wget https://go.dev/dl/go1.20.3.linux-amd64.tar.gz && sudo tar -C /usr/local/ -xzf go1.20.3.linux-amd64.tar.gz
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/coder/.bashrc

WORKDIR /home/coder

