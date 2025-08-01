# artsdata-planet-capacoa

This repo runs a workflow on Github that fetches CAPACOA member data (from CAPACOA's Wordpress database), transforms it to RDF and sends it to the Artsdata Databus on a schedule.



Here is a summary of the workflow fetch-and-push-data.yml
1. Run fetch_data.rb to download data to a JSON file (test locally with >ruby fetch_data.rb)
1. Run add_type.rb
1. Run Ontotext Openrefine to convert to RDF (test locally > ./run_ontorefine.sh)
1. Run run_sparql.rb to execute the SPARQL
1. Commits dump to Github (output/data.ttl)
1. Uploads dump to Artsdata (culturecreates/artsdata-pipeline-action@v3)

# How to test locally
1. Install RVM to manage Ruby
1. clone and cd into the project directory
1. run >bundle install
1. run >ruby src/featch_data.rb
1. Once the data is downloaded from Wordpress...
1. run >./run_ontorefine.sh --> check the output RDF
1. if needed you can edit the RDF Mapping using OntoRefine, export the changes and replace ontorefine-config.json.

# Wordpress plugins

The CAPACOA Wordpress website uses 2 plugins:

## capacoa-artsdata-usermeta
- [capacoa-artsdata-usermeta](https://github.com/culturecreates/capacoa-artsdata-usermeta) Wordpress plugin that opens specific fields for export to Artsdata at https://capacoa.ca/wp-json/wp/v2/users

## artsdata-shortcode
- [artsdata-shortcode](https://github.com/culturecreates/artsdata-shortcode) Wordpress plugin that reads data from Artsdata for display on the CAPACAO website 
