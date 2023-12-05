# syntax=docker/dockerfile:1
# build libetebase
FROM rust:latest as libetebase
ARG LIBETEBASE_VERSION=0.5.6

ADD https://github.com/etesync/libetebase.git#v$LIBETEBASE_VERSION /src/libetebase
WORKDIR /src/libetebase
RUN cargo build --release

# build etesync-fixer
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get --enforce-lockfile

COPY . .
RUN dart pub get --offline --enforce-lockfile
RUN dart run build_runner build
RUN dart compile exe bin/etesync_fixer.dart -o bin/etesync-fixer

# build final image
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/etesync-fixer /app/bin/
COPY --from=libetebase /src/libetebase/target/release/libetebase.so /app/lib/libetebase.so

VOLUME /app/config
ENTRYPOINT [ "/app/bin/etesync-fixer", \
  "--libetebase", "/app/lib/libetebase.so", \
  "--encryption-key", "/run/secrets/account-encryption-key", \
  "--config", "/app/config/etesync-fixer.json" ]
CMD [ "sync" ]
