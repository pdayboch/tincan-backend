# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITHOUT="development"


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
# and generate ssl certs.
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential \
  git libpq-dev pkg-config


# Make sure Bundler version matches the bundler version in Gemfile.lock
# and install Bundler
RUN gem install bundler -v 2.6.1

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/


# Final stage for app image
FROM base AS deploy

# Create a non-root webuser that matches the host's user id and group.
ARG UID=2000
ARG GID=1011

RUN groupadd -g $GID webgroup && \
  useradd -u $UID -g webgroup \
  -m --shell /bin/bash webuser


# Install packages needed for deployment
RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y \
  curl postgresql-client && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Own the runtime files as the webuser for security
RUN chown -R webuser:webgroup \
  db log storage tmp

USER webuser:webgroup

# Entrypoint prepares the database and seeds.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3005
CMD ["./bin/rails", "server"]
