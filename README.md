__# Redcap2omop
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'redcap2omop'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install redcap2omop
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Initial setup
Do not forget to create secrets.yaml or add to existing one the following keys:

```yaml
development:
  redcap:
    api_token:
    api_url:
    verify_ssl: true
```

```bash
$ bundle exec rake db:create
$ rails g redcap2omop:install ( for dummy app use $ rails g redcap2omop:install --migrations=false)
```
Download the latest OMOP vocabulary distribution from http://athena.ohdsi.org

Unzip and copy the vocabulary to /db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport
```bash
$ bundle exec rake redcap2omop:data:load_omop_vocabulary_tables
$ bundle exec rake redcap2omop:data:compile_omop_vocabulary_indexes
```

# CCC19 workflow
```bash
$ bundle exec rake redcap2omop:setup:ccc19:project
$ bundle exec rake redcap2omop:ingest:data_dictionary:cleanup
$ bundle exec rake redcap2omop:ingest:data_dictionary:from_csv PROJECT_ID=0 FILE=../support/data/test_dictionary.csv
$ bundle exec rake redcap2omop:setup:omop_tables
$ bundle exec rake redcap2omop:setup:ccc19:maps
$ bundle exec rake redcap2omop:ingest:data
$ bundle exec rake redcap2omop:ingest:redcap2omop
```

# Neurofiles workflow
```bash
$ bundle exec rake redcap2omop:setup:neurofiles:projects
$ bundle exec rake redcap2omop:setup:neurofiles:project_sandbox
$ bundle exec rake redcap2omop:ingest:data_dictionary:cleanup
$ bundle exec rake redcap2omop:ingest:data_dictionary:from_redcap
$ bundle exec rake redcap2omop:setup:omop_tables
$ bundle exec rake redcap2omop:setup:neurofiles:insert_people
$ bundle exec rake redcap2omop:setup:neurofiles:maps
$ bundle exec rake redcap2omop:setup:neurofiles:maps_sandbox
$ bundle exec rake redcap2omop:ingest:data
$ bundle exec rake redcap2omop:ingest:redcap2omop
```

## Compile indexes after loading data
```bash
$ bundle exec rake redcap2omop:data:compile_omop_indexes
$ bundle exec rake redcap2omop:data:compile_omop_constraints
```

## Drop stuff
```bash
$ bundle exec rake redcap2omop:data:truncate_omop_clinical_data_tables
$ bundle exec rake redcap2omop:data:drop_omop_constraints
$ bundle exec rake redcap2omop:data:drop_omop_indexes
$ bundle exec rake redcap2omop:data:drop_omop_vocabulary_indexes
$ bundle exec rake redcap2omop:data:drop_all_tables
```

## Testing
Download the latest OMOP vocabulary distribution from http://athena.ohdsi.org

Unzip and copy the vocabulary to spec/dummy/db/migrate/CommonDataModel-5.3.1/PostgreSQL/VocabImport

Run the following rake tasks to prepare the testing environment.
```bash
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake app:redcap2omop:data:load_omop_vocabulary_tables
RAILS_ENV=test bundle exec rake app:redcap2omop:data:compile_omop_vocabulary_indexes
bundle exec rspec
```
