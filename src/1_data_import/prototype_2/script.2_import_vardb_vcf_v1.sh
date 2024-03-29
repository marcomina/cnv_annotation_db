export DATA_FOLDER="data/raw"

mkdir -p ${DATA_FOLDER}
mkdir processing
mkdir output

# -------
# Download data - With redundance version - vcf format
wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/data/Homo_sapiens/by_assembly/GRCh38/vcf/GRCh38.variant_call.vcf.gz

# Old versions
# wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/archive/Homo_sapiens/by_assembly/GRCh38/vcf/GRCh38.2019_11_03.variant_call.vcf.gz
# wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/archive/Homo_sapiens/by_assembly/GRCh38/vcf/GRCh38.2019_11_10.variant_call.vcf.gz
# wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/archive/Homo_sapiens/by_assembly/GRCh38/vcf/GRCh38.2019_11_03.variant_region.vcf.gz

# -------
# Filter out the cnvs that are not insertions, deletions, duplications (according to the task) or inversions,
zcat ${DATA_FOLDER}/GRCh38.variant_call.vcf.gz | grep -v 'SVTYPE=BND' > processing/temp_GRCh38.variant_call.vcf # Warnings! Could generates a big file. Can directly load the gzipped file in R if necessary
#
# USE THIS TO EXTRACT A SUBSET OF CALLS ONLY
# zcat data/raw/GRCh38.variant_call.vcf.gz | grep -v 'SVTYPE=BND' | head -n 1000000 > processing/temp_GRCh38.variant_call.vcf # Only extracts the top 10k rows to test the code

# -------
# Run the import procedure, based on R scripting.
Rscript src/1_data_import/prototype_2/bin.2_import_vardb_vcf_v2.R

# Remove temporary files
rm -v processing/temp_GRCh38.variant_call.vcf
rm -v ${DATA_FOLDER}/GRCh38.variant_call.vcf.gz
