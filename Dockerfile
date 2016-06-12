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
RUN mkdir /tmp/mingw-w64-gcc
RUN chown build /tmp/mingw-w64-gcc

RUN groupadd sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers; \
    echo 'Defaults:nobody !requiretty' >> /etc/sudoers; \
    gpasswd -a build sudo

USER build
WORKDIR /tmp/mingw-w64-gcc

ADD PKGBUILD /tmp/mingw-w64-gcc

RUN sed -i 's/--disable-dw2-exceptions/--with-dwarf2/g' PKGBUILD && \
    sed -i 's/--enable-threads=posix/--enable-threads=win32/g' PKGBUILD && \
    sed -i 's/,ada//g' PKGBUILD && \
    sed -i 's/gcc-ada=${pkgver}//g' PKGBUILD && \
    sed -i 's/,gnat1//g' PKGBUILD && \
    sed -i 's/,fortran//g' PKGBUILD && \
    sed -i 's/,f951//g' PKGBUILD

RUN makepkg -sirc --noconfirm

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable

RUN ~/.cargo/bin/rustup target add i686-pc-windows-gnu

ADD config /home/build/.cargo/config

#TODO: remove when not needed for yaourt installation
USER root

#TODO: move up to init to not need switch to root
RUN echo "[archlinuxfr]" >> /etc/pacman.conf && \
    echo "SigLevel = Never" >> /etc/pacman.conf && \
    echo "Server = http://repo.archlinux.fr/x86_64" >> /etc/pacman.conf && \
    pacman -Syyu --noconfirm && \
    pacman -S --noconfirm yaourt

#TODO: remove when not for yaourt installation
USER build

RUN gpg --recv-key D9C4D26D0E604491
RUN yaourt -S mingw-w64-openssl --noconfirm

RUN sudo ln -s /usr/i686-w64-mingw32/bin/ssleay32.dll /usr/i686-w64-mingw32/bin/libssl32.dll

#TODO: yaourt clean?
RUN sudo pacman -Scc --noprogressbar --noconfirm

