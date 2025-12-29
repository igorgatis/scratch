FROM ubuntu:latest
RUN apt-get update \
  && apt-get install -y \
    binutils ca-certificates curl git llvm make vim xxd yadm \
  && rm -rf /var/lib/apt/lists/*
RUN yadm clone https://github.com/igorgatis/dotfiles.git \
  && yadm checkout --force
COPY --from=jdxcode/mise /usr/local/bin/mise /usr/local/bin/mise

WORKDIR /app
COPY mise.toml .
RUN mise trust
RUN mise install
#RUN echo 'eval "$(mise activate bash)"' >> ~/.bashrc
