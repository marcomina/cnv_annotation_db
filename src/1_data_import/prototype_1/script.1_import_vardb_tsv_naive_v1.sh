export DATA_FOLDER="data/raw"

# create folders
mkdir -p ${DATA_FOLDER}
mkdir -p processing
mkdir -p output

# No redundant version
wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/sandbox/sv_datasets/nonredundant/insertions/GRCh38.nr_insertions.tsv.gz
gunzip ${DATA_FOLDER}/GRCh38.nr_insertions.tsv.gz
head GRCh38.nr_insertions.tsv
wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/sandbox/sv_datasets/nonredundant/duplications/GRCh38.nr_duplications.tsv.gz
gunzip ${DATA_FOLDER}/GRCh38.nr_duplications.tsv.gz
wget -P ${DATA_FOLDER} ftp://ftp.ncbi.nlm.nih.gov/pub/dbVar/sandbox/sv_datasets/nonredundant/deletions/GRCh38.nr_deletions.tsv.gz
gunzip ${DATA_FOLDER}/GRCh38.nr_deletions.tsv.gz

# Preprocess input files
# Remove headers
tail -n+3 data/raw/GRCh38.nr_duplications.tsv > processing/GRCh38.nr_duplications.tsv
tail -n+3 data/raw/GRCh38.nr_insertions.tsv > processing/GRCh38.nr_insertions.tsv
tail -n+3 data/raw/GRCh38.nr_deletions.tsv > processing/GRCh38.nr_deletions.tsv

# visually checking first lines
head -n 10 processing/GRCh38.nr_*.tsv

# checking the number of lines is fine
wc processing/GRCh38.nr_*.tsv
# 4298410 should be the total, as of Nov 2019, as reported in the dbVar website 

# Create database and run import script
# sql might complain about shorter than expected columns. this is expected, as there are extra columns in one of the files. this does not affect the results, however.
sqlite3 output/dbvar_v1.sqlite ".read src/1_data_import/prototype_1/sql.1_import_tsv_naive_v1.sql"

# remove temp input files
rm -v processing/GRCh38.nr_*.tsv
rm -v ${DATA_FOLDER}/GRCh38.nr_*.tsv

# remove raw input files
# rm -v ${DATA_FOLDER}/GRCh38.nr_*.tsv.gz
