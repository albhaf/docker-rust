FROM base/archlinux

RUN curl -o /etc/pacman.d/mirrorlist "https://www.archlinux.org/mirrorlist/?country=all&protocol=https&ip_version=6&use_mirror_status=on" && \
  sed -i 's/^#//' /etc/pacman.d/mirrorlist

RUN pacman -Sy archlinux-keyring --noprogressbar --noconfirm && \
    pacman-key --populate && \
    pacman-key --refresh-keys && \
    pacman -Sy --noprogressbar --noconfirm && \
    pacman -S --force openssl --noconfirm && \
    pacman -S pacman --noprogressbar --noconfirm && \
    pacman-db-upgrade && \
    pacman -Syyu --noprogressbar --noconfirm

RUN pacman --sync --noconfirm --noprogressbar --quiet sudo base-devel
RUN useradd --create-home --comment "Arch Build User" build
RUN mkdir /tmp/mingw-w64-gcc && chown build /tmp/mingw-w64-gcc

RUN echo "[archlinuxfr]" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "Server = http://repo.archlinux.fr/x86_64" >> /etc/pacman.conf && \
    pacman -Syyu --noconfirm && \
    pacman -S --noconfirm yaourt

RUN groupadd sudo && \
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

RUN gpg --recv-key D9C4D26D0E604491
RUN yaourt -G mingw-w64-zlib && cd mingw-w64-zlib && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    makepkg -sirc --noconfirm

RUN yaourt -G mingw-w64-openssl && cd mingw-w64-openssl && \
    sed -i 's/ x86_64-w64-mingw32//g' PKGBUILD && \
    makepkg -sirc --noconfirm

RUN sudo ln -s /usr/i686-w64-mingw32/bin/ssleay32.dll /usr/i686-w64-mingw32/bin/libssl32.dll
ENV OPENSSL_LIB_DIR "/usr/i686-w64-mingw32/bin"
ENV OPENSSL_INCLUDE_DIR "/usr/i686-w64-mingw32/include"

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable

RUN ~/.cargo/bin/rustup target add i686-pc-windows-gnu

ADD config /home/build/.cargo/config

#TODO: yaourt clean?
RUN sudo pacman -Scc --noprogressbar --noconfirm
