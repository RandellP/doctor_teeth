FROM centos:7
MAINTAINER Eric Thompson <erict@puppet.com>

RUN yum -y update && yum -y install \
  gcc \
  gcc-c++ \
  git \
  make \
  ruby \
  ruby-devel \
  zlib-devel \
  && yum clean all

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"; \
  gem install bundler

COPY Gemfile doctor_teeth/Gemfile
COPY doctor_teeth.gemspec doctor_teeth/
COPY lib/doctor_teeth/version.rb doctor_teeth/lib/doctor_teeth/

# install the bundle elsewhere
ENV BUNDLE_PATH /vendor
WORKDIR doctor_teeth
RUN bundle install --without development

VOLUME doctor_teeth
