FROM mcr.microsoft.com/vscode/devcontainers/rust:latest as libetebase-build
ARG TAG

RUN git clone https://github.com/etesync/libetebase.git -b "$TAG" /src/libetebase
WORKDIR /src/libetebase
RUN make
RUN make install DESTDIR=/build
RUN ln -s libetebase.so /build/usr/lib/libetebase.so.0

FROM skycoder42/devcontainers-dart:latest
COPY --from=libetebase-build /build /

