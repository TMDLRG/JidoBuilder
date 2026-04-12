# syntax=docker/dockerfile:1
ARG ELIXIR_VERSION=1.19.5
ARG ERLANG_VERSION=28.4.2
ARG ALPINE_VERSION=3.20

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} AS build

RUN apk add --no-cache build-base git python3 curl nodejs npm

ENV MIX_ENV=prod

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

# Copy upstream jido library first (needed via path dep at ../../..)
COPY lib /jido/lib
COPY mix.exs /jido/mix.exs
COPY mix.lock /jido/mix.lock

# Copy umbrella
WORKDIR /app/builder
COPY builder/mix.exs builder/mix.lock ./
COPY builder/config ./config
COPY builder/apps ./apps

RUN mix deps.get --only prod
RUN mix deps.compile

# Assets
RUN cd apps/jido_builder_web && \
    mix assets.setup && \
    mix assets.deploy

RUN mix compile
RUN mix release jido_builder

# ---------- runtime ----------
FROM alpine:${ALPINE_VERSION} AS runtime

RUN apk add --no-cache libstdc++ libgcc openssl ncurses-libs sqlite sqlite-libs ca-certificates tini wget

ENV LANG=C.UTF-8 \
    MIX_ENV=prod \
    PORT=4000

RUN addgroup -S app && adduser -S app -G app && \
    mkdir -p /var/lib/jido_builder && \
    chown -R app:app /var/lib/jido_builder

WORKDIR /app
COPY --from=build --chown=app:app /app/builder/_build/prod/rel/jido_builder ./

USER app
VOLUME /var/lib/jido_builder
EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:4000/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/bin/jido_builder", "start"]
