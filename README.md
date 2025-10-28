# artsdata-planet-capacoa

This repo runs a workflow on Github that fetches CAPACOA member data (from CAPACOA's Wordpress database), transforms it to RDF and sends it to the Artsdata Databus on a schedule.

It also contains the CAPACOA controlled vocabulary derived from the questionnaire when members create their account on the CAPACOA website. 

# Controlled Vocabulary
The controlled vocabulary, derived from the questionnaire when members create their account, is modeled using SKOS and the triples are stored in Github. To update the triples please use this [spreadsheet](https://docs.google.com/spreadsheets/d/1kzujMClBYcjWpoXJ2_fz30rrrKuGceqDE76rnjMNw_E/edit#gid=0) to edit the CAPACOA vocabulary and copy/paste the generated SKOS from the "Export" tab into the Github controlled-vocabulary directory. The commit will trigger a workflow to publish to Artsdata.


# Workflow to fetch CAPACOA's Wordpress database
Here is a summary of the workflow fetch-and-push-data.yml
1. Run `ruby src/fetch_data.rb`
    - downloads data from the CAPACOA [Wordpress API](https://www.capacoa.ca/wp-json/wp/v2/users?per_page=100&offset=1) to a JSON file
1. Run Ontotext Openrefine
    - remove members unless they "agree" to share data. See issue [#8](https://github.com/culturecreates/artsdata-planet-capacoa/issues/8) 
    - remove members unless they have "type": `https://schema.org/Organization` or `https://schema.org/Person`. See issue [#9](https://github.com/culturecreates/capacoa-artsdata-usermeta/issues/9)
    - remove members with a MemberTerminationDate (active members have no value meaning `MemberTerminationDate=''`)
    - map JSON to RDF using ontorefine-config.json
1. Run `ruby src/run_sparql.rb` to execute the SPARQL to infer presenter type
1. Commit dump to Github (output/data.ttl)
1. Upload dump to Artsdata (culturecreates/artsdata-pipeline-action@v3)

## How to test locally
1. Clone and cd into the project directory
1. `bundle install`
1. `ruby src/fetch_data.rb`
1. `./run_ontorefine.sh`
    - launches your browser to OpenRefine (Docker must be running) with the data loaded
    - use OpenRefine to:
        - view the existing project with the data already loaded
        - edit the RDF Mapping
        - filter by facet to delete members
    - export the changes in OpenRefine projet settings and replace `ontorefine-config.json` in Github.
1. `ruby src/run_sparql.rb`

# Wordpress plugins

The CAPACOA Wordpress website uses 2 plugins:

## capacoa-artsdata-usermeta
- [capacoa-artsdata-usermeta](https://github.com/culturecreates/capacoa-artsdata-usermeta) Wordpress plugin that opens specific fields for export to Artsdata at https://capacoa.ca/wp-json/wp/v2/users

## artsdata-shortcode
- [artsdata-shortcode](https://github.com/culturecreates/artsdata-shortcode) Wordpress plugin that reads data from Artsdata for display on the CAPACAO website 
