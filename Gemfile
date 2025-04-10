source "https://rubygems.org"
git_source(:github){|repo| "https://github.com/#{repo}.git"}

ruby "3.2.2"

gem "rails", "~> 7.0.5"

gem "sprockets-rails"

gem "mysql2", "~> 0.5"

gem "puma", "~> 5.0"

gem "importmap-rails"

gem "turbo-rails"

gem "stimulus-rails"

gem "jbuilder"

# gem "redis", "~> 4.0"

# gem "kredis"

gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data", platforms: %i(mingw mswin x64_mingw jruby)

gem "bootsnap", require: false

# gem "sassc-rails"

# gem "image_processing", "~> 1.2"
gem "config", "~> 5.1"
gem "figaro", "~> 1.1", ">= 1.1.1"
gem "i18n", "~> 1.14", ">= 1.14.1"
group :development, :test do
  gem "debug", platforms: %i(mri mingw x64_mingw)
  gem "rspec-rails", "~> 4.0.1"
  gem "rubocop", "~> 1.26", require: false
  gem "rubocop-checkstyle_formatter", require: false
  gem "rubocop-rails", "~> 2.14.0", require: false
end

group :development do
  gem "pry-rails", "~> 0.3.4"
  gem "web-console"

  # gem "rack-mini-profiler"

  # gem "spring"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

gem "active_storage_validations", "0.9.8"
gem "cancancan", "~> 3.5"
gem "devise"
gem "image_processing", "1.12.2"
gem "pagy"
gem "paranoia", "~> 2.1", ">= 2.1.5"
gem "ransack"
gem "tailwindcss-rails", "~> 3.3"
