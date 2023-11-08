FROM rust:1.73 as builder
# Update the package lists for upgrades and new packages
RUN apt-get update

# Install dependencies
RUN apt-get install -y git meson ninja-build nasm clang

# Clone dav1d repository
RUN git clone --depth=1 https://code.videolan.org/videolan/dav1d.git

# Build and install dav1d
RUN cd dav1d && \
    mkdir build && \
    cd build && \
    meson .. && \
    ninja && \
    ninja install

RUN mv /usr/local/lib/x86_64-linux-gnu/libdav1d.so* /usr/lib
WORKDIR /usr/src/image-scaling
COPY . .
RUN cargo install --path .

FROM debian:bookworm-slim
WORKDIR /usr/src/image-scaling
RUN apt-get update && apt-get -y install openssl ca-certificates curl \
  && rm -rfv /var/lib/apt/lists/*

COPY --from=builder /usr/lib/libdav1d.so* /usr/lib/

RUN update-ca-certificates
COPY --from=builder /usr/local/cargo/bin/image-scaling /usr/local/bin/image-scaling

RUN adduser --disabled-password --gecos '' image-scaling
USER image-scaling
ENV USER=image-scaling

CMD ["image-scaling"]