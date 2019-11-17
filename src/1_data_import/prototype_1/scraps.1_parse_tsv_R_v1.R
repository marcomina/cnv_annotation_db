library("data.table")
library(readr)
library(dplyr)
library(DBI)
library(RSQLite)
require(tidyr)

db = "output/dbvar_v1.sqlite"
dbvar_main_table = 'dbvar_tsv'

# Open a connection (i.e. create or access an existing sqlite file)
conn = dbConnect(drv=SQLite(), dbname=db)


src_fname = 'data/raw/GRCh38.nr_duplications.tsv'
tgt_fname = "processing/temp_GRCh38.nr_duplications_parsed.tsv"
src_h = src_fname

src_fname = 'data/raw/GRCh38.nr_insertions.tsv'
tgt_fname = "processing/temp_GRCh38.nr_insertions_parsed.tsv"
src_h = src_fname

src_fname = 'data/raw/GRCh38.nr_deletions.tsv'
tgt_fname = "processing/temp_GRCh38.nr_deletions_parsed.tsv"
src_h = src_fname


############3
# Derive header infos
# header = read_tsv(src_h, skip=1, comment='', col_names=FALSE, n_max=40)
# header %>% data.frame
offset = read_tsv(src_h, skip=1, comment='', col_names=FALSE, n_max=1)
infile_colnames = gsub('#', '', offset %>% data.frame %>% unlist)
names(infile_colnames) = NULL
print(infile_colnames)

# Get sample of data to experiment with 
data = read_tsv(src_h, comment='#', col_names=infile_colnames, n_max= 1000)
df = data
df %>% head()
df1 = tidyr::separate_rows(df, variant, sep=";\\s*")
nrow(df)
nrow(df1)
df1 %>% head



rebase.chunk = function(df, pos) {
	require(tidyr)
	to.append = ifelse(pos > 1, TRUE, FALSE)
	df1 = tidyr::separate_rows(df, variant, sep=";\\s*")
	df1 %>% write_tsv(tgt_fname, append=to.append, quote_escape=FALSE, col_names=!to.append)
}

CHUNK_SIZE = 10000
a = read_tsv_chunked(
  src_h, 
  callback=SideEffectChunkCallback$new(rebase.chunk), 
  chunk_size = CHUNK_SIZE,
  col_names = infile_colnames,
  comment = '#',
  skip=1,
  progress = TRUE
)
