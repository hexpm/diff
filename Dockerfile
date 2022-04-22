FROM hexpm/elixir:1.13.4-erlang-24.3.3-alpine-3.15.3 as build

# install build dependencies
RUN apk add --no-cache --update git build-base nodejs yarn

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

# build assets
COPY assets assets
RUN cd assets && yarn install && yarn run webpack --mode production
RUN mix phx.digest

# build project
COPY priv priv
COPY lib lib
RUN mix compile

# build release
COPY rel rel
RUN mix release

# prepare release image
FROM alpine:3.15.3 AS app
RUN apk add --no-cache --update bash openssl git libstdc++

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/diff ./
RUN chown -R nobody: /app
USER nobody

ENV HOME=/app
