FROM base/archlinux

RUN curl -o /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=all&protocol=https&ip_version=6&use_mirror_status=on" && \
  sed -i 's/^#//' /etc/pacman.d/mirrorlist

RUN echo "[archlinuxfr]" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "Server = http://repo.archlinux.fr/x86_64" >> /etc/pacman.conf 

RUN pacman -Sy archlinux-keyring --noprogressbar --noconfirm && \
    pacman-key --populate && \
    pacman-key --refresh-keys && \
    pacman -Sy --noprogressbar --noconfirm && \
    pacman -S --force openssl --noconfirm && \
    pacman -S pacman --noprogressbar --noconfirm && \
    pacman-db-upgrade && \
    pacman -Syyu --noprogressbar --noconfirm

RUN pacman --sync --noconfirm --noprogressbar --quiet sudo base-devel yaourt

RUN useradd --create-home --comment "Arch Build User" build && \
    groupadd sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    echo 'Defaults:nobody !requiretty' >> /etc/sudoers; \
    gpasswd -a build sudo

USER build
WORKDIR /tmp

RUN yaourt -G mingw-w64-gcc && cd mingw-w64-gcc && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    sed -i 's/--disable-dw2-exceptions/--disable-sjlj-exceptions --with-dwarf2/g' PKGBUILD && \
    sed -i 's/--enable-threads=posix/--enable-threads=win32/g' PKGBUILD && \
    sed -i 's/,ada//g' PKGBUILD && \
    sed -i 's/gcc-ada=${pkgver}//g' PKGBUILD && \
    sed -i 's/,gnat1//g' PKGBUILD && \
    sed -i 's/,fortran//g' PKGBUILD && \
    sed -i 's/,f951//g' PKGBUILD && \
    makepkg -sirc --noconfirm

RUN gpg --recv-key D9C4D26D0E604491 && \
    yaourt -G mingw-w64-zlib && cd mingw-w64-zlib && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    makepkg -sirc --noconfirm

RUN yaourt -G mingw-w64-openssl && cd mingw-w64-openssl && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    sed -i 's/shared/no-shared/g' PKGBUILD && \
    makepkg -sirc --noconfirm

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable && \
    ~/.cargo/bin/rustup target add i686-pc-windows-gnu
ADD config /home/build/.cargo/config

ENV OPENSSL_LIB_DIR "/usr/i686-w64-mingw32/lib"
ENV OPENSSL_INCLUDE_DIR "/usr/i686-w64-mingw32/include"
ENV OPENSSL_STATIC 1
ENV OPENSSL_LIBS "ssl:crypto:gdi32"

RUN sudo pacman -Scc --noprogressbar --noconfirm && \
    sudo yaourt -Scc --noconfirm
