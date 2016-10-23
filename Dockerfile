FROM binhex/arch-base:latest
MAINTAINER Albert Hafvenström <albhaf@gmail.com>

RUN echo "[archlinuxfr]" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "Server = http://repo.archlinux.fr/x86_64" >> /etc/pacman.conf &&\
    pacman -Sy

RUN pacman --sync --noconfirm --noprogressbar --quiet sudo base-devel yaourt

RUN useradd --create-home --comment "Arch Build User" build && \
    groupadd sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    echo 'Defaults:nobody !requiretty' >> /etc/sudoers; \
    gpasswd -a build sudo

USER build
WORKDIR /tmp

# Overrides from arch-base
ENV HOME /home/build

RUN yaourt -G mingw-w64-gcc && cd mingw-w64-gcc && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    sed -i 's/--disable-dw2-exceptions/--disable-sjlj-exceptions --with-dwarf2/g' PKGBUILD && \
    sed -i 's/--enable-threads=posix/--enable-threads=win32/g' PKGBUILD && \
    sed -i 's/,ada//g' PKGBUILD && \
    sed -i 's/gcc-ada=${pkgver}//g' PKGBUILD && \
    sed -i 's/,gnat1//g' PKGBUILD && \
    sed -i 's/,fortran//g' PKGBUILD && \
    sed -i 's/,f951//g' PKGBUILD && \
    makepkg -sirc --noconfirm && \
    cd .. && rm -rf mingw-w64-gcc

RUN gpg --recv-key D9C4D26D0E604491 && \
    yaourt -G mingw-w64-zlib && cd mingw-w64-zlib && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    makepkg -sirc --noconfirm && \
    cd .. && rm -rf mingw-w64-zlib

RUN yaourt -G mingw-w64-openssl && cd mingw-w64-openssl && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    sed -i 's/shared/no-shared/g' PKGBUILD && \
    makepkg -sirc --noconfirm && \
    cd .. && rm -rf mingw-w64-openssl

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable && \
    ~/.cargo/bin/rustup target add i686-pc-windows-gnu

ENV OPENSSL_LIB_DIR "/usr/i686-w64-mingw32/lib"
ENV OPENSSL_INCLUDE_DIR "/usr/i686-w64-mingw32/include"
ENV OPENSSL_STATIC 1
ENV OPENSSL_LIBS "ssl:crypto:gdi32"

ENV CARGO_TARGET_I686_PC_WINDOWS_GNU_LINKER "/usr/bin/i686-w64-mingw32-gcc"
ENV CARGO_TARGET_I686_PC_WINDOWS_GNU_AR "/usr/bin/i686-w64-mingw32/bin/ar"
