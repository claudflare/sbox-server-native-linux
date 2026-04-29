# Stage 1: Download the server via SteamCMD
FROM steamcmd/steamcmd:debian-13 AS builder

# Invalidates the SteamCMD layer when set to a new value (the CI passes
# github.run_id), so every build re-fetches the latest s&box server binary.
ARG CACHE_BUST=0
# Run app_update twice to work around steamcmd's empty-cache "Missing configuration" error.
RUN echo "cache bust: $CACHE_BUST" && steamcmd \
        +@sSteamCmdForcePlatformType linux \
        +force_install_dir /sbox-server \
        +login anonymous \
        +app_update 1892930 validate \
        +app_update 1892930 validate \
        +quit

# Stage 2: Lean runtime image
FROM mcr.microsoft.com/dotnet/runtime:10.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libfontconfig1 \
        libxcb1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -u 1001 -m -s /bin/bash steam

COPY --from=builder --chown=steam:steam /sbox-server /sbox

# Engine native libs (libengine2, librendersystemempty, libschemasystem,
# libmaterialsystem2, etc.) are dlopen via absolute path /usr/share/dotnet/.
RUN for lib in /sbox/bin/linuxsteamrt64/*.so; do \
        ln -sf "$lib" "/usr/share/dotnet/$(basename "$lib")"; \
    done

RUN mkdir -p /sbox/download /sbox/logs /sbox/data && \
    chown -R steam:steam /sbox/download /sbox/logs /sbox/data

VOLUME ["/sbox/download", "/sbox/logs", "/sbox/data"]

USER steam
WORKDIR /sbox

# Force .NET's TLS shim to use Debian's libcrypto/libssl rather than the older
# bundled copies in /sbox/bin/linuxsteamrt64. Without this, LD_LIBRARY_PATH
# below causes Steam's bundled OpenSSL to win the linker search, ABI mismatches
# break TLS, and HttpClient fails with "An error occurred while sending the request".
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libcrypto.so.3:/usr/lib/x86_64-linux-gnu/libssl.so.3

ENV DOTNET_SYSTEM_NET_DISABLEIPV6=true

ENV LD_LIBRARY_PATH=/sbox/bin/linuxsteamrt64

ENTRYPOINT ["dotnet", "/sbox/sbox-server.dll"]
CMD ["+game", "facepunch.sandbox", "facepunch.flatgrass", "+hostname", "My Dedicated Server"]
