FROM rustlang/rust:nightly

# update the system
RUN apt-get -y update \
  && apt-get -y upgrade

# install utils
RUN apt-get install -y --no-install-recommends \
  nasm \
  grub-common \
  grub-pc-bin \
  xorriso \
  qemu-kvm

  # install rust specific packages and components
  RUN cargo install xargo && rustup component add rust-src
