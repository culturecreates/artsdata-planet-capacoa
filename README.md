# artsdata-planet-capacoa

This repo runs a workflow on Github that fetches CAPACOA member data (from CAPACOA's Wordpress database), transforms it to RDF and sends it to the Artsdata Databus.

Here is a summary of the workflow fetch-and-push-data.yml
1. Run fetch_data.rb to download data to a JSON file (test locally with >ruby fetch_data.rb)
1. Run add_type.rb
1. Run Ontotext Openrefine to convert to RDF (test locally > ./run_ontorefine.sh)
1. Run run_sparql.rb to execute the SPARQL
1. Commits dump to Github (output/data.ttl)
1. Uploads dump to Artsdata (culturecreates/artsdata-pipeline-action@v3)