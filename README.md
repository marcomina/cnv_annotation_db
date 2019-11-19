# cnv_annotation_db

The code in this repository implements an annotation system for CNV data, with annotations coming from the dbVar dataset. The system relies on a SQL database and provides some query scripts that allow searching for variants by genomic range.

## How to deploy and run ##

1. Clone the repository and enter into the cnv_annotaion_db folder:

	git clone https://github.com/marcomina/cnv_annotation_db.git
	
	cd cnv_annotation_db 
	
2. (Optional) Create, activate and populate a new conda environment. You can use the script src/0_setup_env/bin.0_gen_env_v1.sh:

	bash src/bin.0_gen_env_v1.sh

3. Generate the database (requires aroound 50 minutes):

	bash src/1_data_import/prototype_2/script.2_import_vardb_vcf_v1.sh

4. (Optional) Run test queries:

	bash ./src/2_cnv_query/run.0_query_example_v2.sh
	
