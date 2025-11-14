################################
# Toolchain stage
FROM --platform=linux/riscv64 alpine:3.22.2@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 AS alpine-base

# Update system
RUN apk update && \
    apk upgrade -aU

################################
# Toolchain stage
FROM --platform=linux/riscv64 alpine-base AS toolchain-stage

# Update and install development packages
RUN apk add build-base pkgconf git wget patchelf

# Build other packages inside /root
WORKDIR /root

################################
# Build tools

# Build xhalt (tool used by init system to poweroff the machine)
FROM --platform=linux/riscv64 toolchain-stage AS xhalt-stage
RUN apk add libseccomp-dev
COPY xhalt.c xhalt.c
# RUN wget -O xhalt.c https://raw.githubusercontent.com/cartesi/machine-guest-tools/refs/tags/v0.17.2/sys-utils/xhalt/xhalt.c
RUN gcc xhalt.c -Os -s -o xhalt
RUN mkdir -p /pkg/usr/sbin && \
    cp xhalt /pkg/usr/sbin/ && \
    strip /pkg/usr/sbin/xhalt

# Build https-proxy (proxy used to provide networking in the browser)
FROM --platform=linux/riscv64 toolchain-stage AS proxy-stage
RUN apk add boost-dev openssl-dev
COPY https-proxy https-proxy
RUN make -C https-proxy
RUN mkdir -p /pkg/usr/sbin /pkg/etc/ssl/minux /pkg/etc/ssl/certs /pkg/usr/local/share/ca-certificates && \
    cp https-proxy/https-proxy /pkg/usr/sbin/https-proxy && \
    strip /pkg/usr/sbin/https-proxy

# Build gcompat (tool to run GLIBC programs)
FROM --platform=linux/riscv64 toolchain-stage AS gcompat-stage

# Original
# RUN git clone --revision=d8cf7fbd072a379b9b16991539ba03bbbab4bd9c --depth=1 https://git.adelielinux.org/adelie/gcompat.git

# Local
# git clone --depth=1 https://git.adelielinux.org/adelie/gcompat.git
# cd gcompat
# git reset --hard d8cf7fbd072a379b9b16991539ba03bbbab4bd9c
COPY gcompat gcompat
RUN <<EOF cat >> gcompat/gcompat.patch
diff --git a/libgcompat/resolv.c b/libgcompat/resolv.c
index c63d074..35fe616 100644
--- a/libgcompat/resolv.c
+++ b/libgcompat/resolv.c
@@ -13,6 +13,10 @@

 #include "alias.h" /* weak_alias */

+int __res_init() {
+	return res_init();
+}
+
 int __res_ninit(res_state statp)
 {
 	int rc;

EOF
RUN cd gcompat && git apply gcompat.patch
RUN make -C gcompat -j$(nproc) LINKER_PATH=/lib/ld-musl-riscv64.so.1 LOADER_NAME=ld-linux-riscv64-lp64d.so.1
RUN make -C gcompat install LINKER_PATH=/lib/ld-musl-riscv64.so.1 LOADER_NAME=ld-linux-riscv64-lp64d.so.1 DESTDIR=/pkg

################################
# Download packages
FROM --platform=linux/riscv64 alpine-base AS rootfs-stage

# Install development utilities
RUN apk add \
    # +2
    # bash \
    # \
    # bash-completion \
    make \
    nano \
    curl \
    tmux \
    jq \
    dnsmasq \
    # file \
    # htop \
    # ncdu \
    # cmatrix \
    \
    # +7
    # neovim \
    # vifm \
    \
    # strace \
    # dmesg \
    # libatomic \
    # bc \
    \
    # Already installed:
    # git wget \
    tcc tcc-libs-static musl-dev \
    tcc-libs  tcc-dev \
    lua5.4 \
    micropython \
    \
    # +2
    quickjs \
    sqlite \
    # +1
    quickjs-dev \
    sqlite-dev \
    # \
    # +1
    # mruby \
    # guile \
    # ecl \
    # esbuild \
    # \
    # nodejs \
    # npm \
    # go \
    # rust \
    # \
    # Syntax highlight
    # tree-sitter-c \
    # tree-sitter-bash \
    # tree-sitter-javascript tree-sitter-json \
    # tree-sitter-lua \
    # tree-sitter-python \
    # tree-sitter-scheme \
  && ln -sf lua5.4 /usr/bin/lua \
  # +3
  # && apk add php82 \
  # && apk add php82-pdo_sqlite --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  # && ln -sf php82 /usr/bin/php
  # +13M
  # && apk add wasmtime --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  # && apk add wabt --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
  # && apk add wasm-tools --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  \
  # 4MB
  # && apk add ecl --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
  \
  # && apk add clang21 --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main \
  # && apk add emacs --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  # && apk add clojure --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  ;

# Install init system and base skel
COPY cartesi-init cartesi-init
ADD --chmod=755 cartesi-init /usr/sbin/cartesi-init
# ADD --chmod=755 https://raw.githubusercontent.com/cartesi/machine-guest-tools/refs/tags/v0.17.2/sys-utils/cartesi-init/cartesi-init /usr/sbin/cartesi-init
COPY --from=xhalt-stage /pkg /
COPY --from=proxy-stage /pkg /
COPY --from=gcompat-stage /pkg /
COPY skel /

# Remove unneeded files
RUN rm cartesi-init \
  && rm -rf /var/cache/apk \
  && rm -f /usr/lib/libc.a
  # apk del python3
