FROM archlinux:base

RUN pacman --quiet --noconfirm -Syu
RUN pacman --quiet --noconfirm -S base-devel git sudo time wget nano inetutils

WORKDIR /app

ENV Racket_VER=8.8
RUN wget https://mirror.racket-lang.org/installers/${Racket_VER}/racket-${Racket_VER}-x86_64-linux.sh \
    && chmod a+x racket-${Racket_VER}-x86_64-linux.sh \
    && ./racket-${Racket_VER}-x86_64-linux.sh --in-place --dest /root/racket
ENV PATH="/root/racket/bin:$PATH"

# installing Gambit-C compiler for Scheme
RUN pacman --quiet --noconfirm -S gambit-c

# installing OCaml
RUN pacman --quiet --noconfirm -S ocaml opam

RUN pacman --quiet --noconfirm -S bc
RUN raco pkg install --auto csv-reading require-typed-check

# These are needed for building the dynamizer and grift programs, they should
# not be installed after invalidating the cache because arch linux could have
# moved on by then and some of the dependencies will not be in the correct
# state.
RUN pacman --quiet --noconfirm -S stack
RUN pacman --quiet --noconfirm -S clang

# Invalidate Cache so that a fresh Grift is Installed.
# ARG CACHE_DATE=not_a_date # Commented out for PLDI Artifact

# installing the Dynamizer
RUN git clone https://github.com/Gradual-Typing/Dynamizer.git \
    && mkdir -p /home/root && cd Dynamizer && stack setup \
    && stack build && stack install \
    && cp /root/.local/bin/dynamizer /usr/local/bin

# to create figures of multiple plots
RUN pacman --quiet --noconfirm -S imagemagick

# installing Chez Scheme
RUN pacman --quiet --noconfirm -S libx11 \
    && git clone https://github.com/cisco/ChezScheme.git \
    && cd ChezScheme && ./configure --threads --installschemename=chez-scheme \
    && make -j 4 && make install

RUN pacman --quiet --noconfirm -S gnuplot

# installing Grift
RUN raco pkg install --deps search-auto grift
WORKDIR /app
ENV PATH="/root/.racket/${Racket_VER}/bin/:$PATH"

ARG EXPR_DIR=not_a_path

WORKDIR $EXPR_DIR/scripts

CMD make test
