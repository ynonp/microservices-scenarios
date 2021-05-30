# syntax=docker/dockerfile:1
FROM ruby:2.7.2

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -\
  && apt-get update -qq && apt-get install -qq --no-install-recommends \
    nodejs postgresql-client \
  && apt-get upgrade -qq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*\
  && npm install -g yarn@1


WORKDIR /myapp
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock


ENV BUNDLER_VERSION 2.1.4
RUN gem update --system \
    && gem install bundler -v $BUNDLER_VERSION \
    && bundle install -j 4

# Add a script to be executed every time the container starts.
COPY entrypoint.sh wait-for-it.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh /usr/bin/wait-for-it.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]
