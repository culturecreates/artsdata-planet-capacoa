# artsdata-planet-capacoa

This repo runs a workflow on Github that fetches CAPACOA member data (from CAPACOA's Wordpress database), transforms it to RDF and sends it to the Artsdata Databus on a schedule.

It also contains the CAPACOA controlled vocabulary derived from the questionnaire when members create their account. 

# Controlled Vocabulary
The controlled vocabulary, derived from the questionnaire when members create their account, is modeled using SKOS and the triples are stored in Github. To update the triples please use this [spreadsheet](https://docs.google.com/spreadsheets/d/1kzujMClBYcjWpoXJ2_fz30rrrKuGceqDE76rnjMNw_E/edit#gid=0) to edit the CAPACOA vocabulary and copy/paste the generated SKOS from the "Export" tab into the Github controlled-vocabulary directory. The commit will trigger a workflow to publish to Artsdata.

# Workflow to fetch CAPACOA's Wordpress database
Here is a summary of the workflow fetch-and-push-data.yml
1. Run fetch_data.rb to download data from the CAPACOA Wordpress API to a JSON file (https://www.capacoa.ca/wp-json/wp/v2/users?per_page=100&offset=1)
1. Run filter_and_add_type.rb to modify JSON file:
    - remove members who are missing either "operating_name1", "pmpro_approval_12" or "pmpro_approval_13"
    - remove members who do not agree to terms and conditions to share data
    - add member type (organization|ind|indlife) and schema type (Organization|Person) to each remaining member
1. Run Ontotext Openrefine to convert to RDF
1. Run run_sparql.rb to execute the SPARQL (infer presenter type)
1. Commits dump to Github (output/data.ttl)
1. Uploads dump to Artsdata (culturecreates/artsdata-pipeline-action@v3)

## How to test locally
1. Clone and cd into the project directory
1. `bundle install`
1. `ruby src/fetch_data.rb`
1. `ruby src/filter_and_add_type.rb`
1. `./run_ontorefine.sh` --> opens your browser to OpenRefine with the data loaded
1. You can edit the RDF Mapping using OntoRefine, export the changes and replace `ontorefine-config.json`.

# Wordpress plugins

The CAPACOA Wordpress website uses 2 plugins:

## capacoa-artsdata-usermeta
- [capacoa-artsdata-usermeta](https://github.com/culturecreates/capacoa-artsdata-usermeta) Wordpress plugin that opens specific fields for export to Artsdata at https://capacoa.ca/wp-json/wp/v2/users

## artsdata-shortcode
- [artsdata-shortcode](https://github.com/culturecreates/artsdata-shortcode) Wordpress plugin that reads data from Artsdata for display on the CAPACAO website 
