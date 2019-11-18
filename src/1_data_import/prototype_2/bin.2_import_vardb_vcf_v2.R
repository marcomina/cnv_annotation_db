library("data.table")
library(readr)
library(plyr)
library(dplyr)
library(DBI)
library(RSQLite)
library(tidyr)

##############################
# Set parameters
##############################
# For sake of simplicity, filenames are hardcoded here.
# Possible Enhancement: use argparse to parse parameters from the command line. Overkilling for now
db = "output/dbvar_v2.sqlite"
CHUNK_SIZE = 200000
src_fname = 'processing/temp_GRCh38.variant_call.vcf'
src_h = src_fname


##############################
# Define schemas
##############################


############
# Derive header infos
header = read_tsv(src_h, skip=1, comment='', col_names=FALSE, n_max=45)
header %>% data.frame
offset = read_tsv(src_h, skip=34, comment='', col_names=FALSE, n_max=1)
infile_colnames = gsub('#', '', offset %>% data.frame %>% unlist)
names(infile_colnames) = NULL
print(infile_colnames)

INFO_subfields = c("DBVARID", "CHR2", "EVENT", "SVTYPE", "EXPERIMENT", "SAMPLE", "SAMPLESET", "AC", "AF", "AN", "LINKS", "DESC", "SEQ", "END", "REGIONID", "ALT_class", "CLNSIG", "clinical_source", "PHENO", "ORIGIN", "CLNACC", "SVLEN", "CIPOS", "CIEND", "VALIDATED", "SOMATIC")

############
# Data to ignore
fields_to_mask = c("DBVARID", "CHR2", "EVENT", "REF", "QUAL", "FILTER", "SVTYPE", "EXPERIMENT", "SAMPLE", "SAMPLESET", "AC", "AF", "AN", "LINKS", "DESC", "SEQ")

############
# CNV ROI table
fields_to_cnv_roi_table = c("cnv_roi_id", "CHROM", "POS", "END", 'REGIONID')
cnv_roi_table_schema = "
  id TEXT PRIMARY KEY,
  chr TEXT,
  roi_start INTEGER,
  roi_end INTEGER,
  REGIONID TEXT
  "

############
# CNV CALL table
fields_to_cnv_call_table = c("ID", "cnv_roi_id", "ALT_class", "ALT", "CLNSIG", "clinical_source", "PHENO", "ORIGIN", "CLNACC", "SVLEN", "CIPOS", "CIEND", "imprecise", "VALIDATED", "SOMATIC")
cnv_call_table_schema = "
  id TEXT PRIMARY KEY,
  cnv_roi_id TEXT EXTERNAL KEY,
  variant_type TEXT,
  variant_type_detailed TEXT,
  CLNSIG TEXT,
  clinical_source TEXT,
  PHENO TEXT,
  ORIGIN TEXT,
  CLNACC TEXT,
  SVLEN INTEGER,
  CIPOS TEXT,
  CIEND TEXT,
  imprecise BOOL,
  somatic INTEGER,
  validated BOOL
  "

# check that no 
if(length(intersect(fields_to_mask, c(fields_to_cnv_call_table, fields_to_cnv_roi_table)))>0) stop('Inconsistent field selection.')
schemas = list('dbvar_vcf_cnv_roi' = cnv_roi_table_schema, 'dbvar_vcf_cnv_call' = cnv_call_table_schema)





##############################
# Functions
##############################

split_info <- function(data, only.known=FALSE) {
	INFOs = strsplit(data %>% pull(INFO), ';', fixed=TRUE)
	# Split infos
	default = c('no_info' = TRUE)
	if(only.known) {
		fields_to_retain = INFO_subfields
		default = rep(NA, length(fields_to_retain))
		names(default) = fields_to_retain
	}

	INFOs = lapply(INFOs, function(x) {
		if(length(grep('=', x, fixed=TRUE))==0) return(default)
		x = x[(grep('=', x, fixed=TRUE))]
		x = strsplit(x, '=', fixed=TRUE)
		values = sapply(x, function(x) x[[2]])
		names(values) = sapply(x, function(x) x[[1]])

		if(only.known) {
			values = values[fields_to_retain]
			names(values) = fields_to_retain
		}
		return(values)
	})
	return(INFOs)
}

# This function converts the input cvf data into the consistnt format ready to be injected into the database.
# The implementation is awufully inefficient as it was developed for exploring the data and is flexible upon changes in the number, order and type of fields of the input data. Can be sped up by replacing the data.frame and rbind.fill coversions with an exact declaration of the fields to be retained. Nevertheless, it takes around 100 minutes to process the entire dbvar dataset with this version.
interpret_info <- function(df, speedup=TRUE) {
	# annotate the call with its precision
	df = df %>% mutate(imprecise = grepl('IMPRECISE', INFO, fixed=TRUE))
	df = df %>% mutate(ALT = gsub('<|>', '', ALT))
	# Aggregate the event according to the guidelines
	df$ALT_class = 'other'
	df = df %>% mutate(ALT_class = ifelse(grepl('INV', ALT, fixed=TRUE), 'inversion', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('DUP', ALT, fixed=TRUE), 'duplication', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('CNV', ALT, fixed=TRUE), 'duplication', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('DEL', ALT, fixed=TRUE), 'deletion', ALT_class))
	df = df %>% mutate(ALT_class = ifelse(grepl('INS', ALT, fixed=TRUE), 'insertion', ALT_class))

	# process INFOs
	if(!speedup) { # Fast version. Only retains subfields we know a-priori will be inserted in the database. Way faster (~3x faster) than the other version
		dfi = split_info(df)
		# Convert to consistent dataframe
		dfi = lapply(dfi, function(x) data.frame(t(x), stringsAsFactors=FALSE))
		dfi2 = plyr::rbind.fill(dfi)
	} else { # Versatile version. Retains all subfields at cost of time complexity. Good for exploring data
		dfi = split_info(df, only.known=TRUE)
		# Convert to consistent dataframe
		dfi = do.call(rbind, dfi)
		dfi2 = data.frame(dfi, stringsAsFactors=FALSE)
	}
	df$INFO = NULL

	# merge back INFO and othr fields
	if(nrow(dfi2) != nrow(df)) stop('Error in interpret_info!')
	df = cbind(df, dfi2 %>% select(setdiff(colnames(dfi2), colnames(df))))
	# convert some fields into INTegers
	# df = df %>% mutate(CHROM = as.character(CHROM)) # should not be necessary
	df = df %>% mutate(POS = as.numeric(POS))
	df = df %>% mutate(END = as.numeric(END))
	df = df %>% mutate(SVLEN = as.numeric(SVLEN))
	df = df %>% mutate(cnv_roi_id = paste(CHROM, POS, END, REGIONID, sep='_')) # this will be the primary key. CHROM, POS and END alone are not a valid superkey

	return(df)
}

# This function initializes the tables in the DB.
# Should be run just once at the beginning of the parsing
init_tables <- function(conn, schemas) {
	# Loop through the schemas and send a CREATE TABLE query with the schema
	nil = lapply(names(schemas), function(x) {
		temp_query = paste("CREATE TABLE", x,"(", schemas[[x]], ");")
		if(x %in% dbListTables(conn)) a = DBI::dbSendQuery(conn, paste('DROP TABLE', x))
		a = DBI::dbSendQuery(conn, temp_query)
	})
}

# Routine to split the input data in the correct tables and inserting them into the db.
insert_data <- function(conn, df1) {

	# take care of the missing columns, if any
	good_fields = unique(c(fields_to_cnv_roi_table, fields_to_cnv_call_table))
	if(length(setdiff(colnames(df1), c(good_fields, fields_to_mask)))>0) {
		warning(paste('Fields unaccounted for:', paste(setdiff(colnames(df1), c(good_fields, fields_to_mask)), collapse = ', ')))
	}
	df1 = df1 %>% select(setdiff(colnames(df1), fields_to_mask))
	# Set to NA the unknow values
	if(length(setdiff(good_fields, colnames(df1)))>0) df1[, setdiff(good_fields, colnames(df1))] = NA
	
	# split input data in tables
	df_roi = df1 %>% select(fields_to_cnv_roi_table)
	df_call = df1 %>% select(fields_to_cnv_call_table)

	###############
	# Prepare ROIs
	
	# Get unique rois
	df_roi = df_roi %>% unique()
	
	# Ignore rois already inserted
	res <- dbGetQuery(conn, 'SELECT id FROM dbvar_vcf_cnv_roi') %>% pull(id)
	df_roi = df_roi %>% filter(! cnv_roi_id %in% res)

	# check that all is fine
	if((nrow(df_roi) > 0) & ((df_roi %>% count(cnv_roi_id) %>% arrange(-n) %>% pull(n) %>% max) > 1)) stop('Error in insert data. the primary key of th ROI table is not a valid superkey.')
	# --- Debugging code
	# df_roi %>% count(cnv_roi_id) %>% arrange(-n)
	# df_roi <<- df_roi
	# nrow(df_roi)
	# nrow(df_call)
	# df_call %>% head
	# --- END Debugging code

	###############
	# Insert cnv rois
	dbBegin(conn)
	# Possible enhancement: remove the hardcoded fields and automatically create the query based on the schema definition
	# Overkilling right now, can easily be implemented
	res <- dbSendQuery(conn, 'INSERT INTO dbvar_vcf_cnv_roi VALUES (:cnv_roi_id, :CHROM, :POS, :END, :REGIONID);', df_roi)
	dbClearResult(res)
	dbCommit(conn)

	###############
	# Insert cnv calls
	# Possible enhancement: remove the hardcoded fields and automatically create the query based on the schema definition
	# Overkilling right now, can easily be implemented
	dbBegin(conn)
	res <- dbSendQuery(conn, 'INSERT INTO dbvar_vcf_cnv_call VALUES (:ID, :cnv_roi_id, :ALT_class, :ALT, :CLNSIG, :clinical_source, :PHENO, :ORIGIN, :CLNACC, :SVLEN, :CIPOS, :CIEND, :imprecise, :VALIDATED, :SOMATIC);', df_call)
	dbClearResult(res)
	dbCommit(conn)
}


##############################
# Primary script
##############################
# Create and/or access the DB
# Create the tables
# Batch process the input file and populate the DB
# Create indexes to speed-up queries
# check imported data

# Open a connection (i.e. create or access an existing sqlite file)
conn = dbConnect(drv=SQLite(), dbname=db)

# Callback function run on each single chunk of data
callback_bridge_function = function(df, pos) {
	to.append = ifelse(pos > 1, TRUE, FALSE)
	if(!to.append) init_tables(conn, schemas)
	df1 = interpret_info(df)
	print(paste(pos))
	insert_data(conn, df1)
}

# Process chunks of data of size CHUNK_SIZE to avoid loading all the data into R memory space at once

start.time <- Sys.time()

a = read_tsv_chunked(
  src_h, 
  callback=SideEffectChunkCallback$new(callback_bridge_function), 
  chunk_size = CHUNK_SIZE,
  col_types = cols(.default = "c"),
  col_names = infile_colnames,
  comment = '#',
  skip=0,
  progress = TRUE,
)

end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)


# Build indexes for fast sarch
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_chr ON dbvar_vcf_cnv_roi (chr);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_start ON dbvar_vcf_cnv_roi (roi_start);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_stop ON dbvar_vcf_cnv_roi (roi_end);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_external_roi_id ON dbvar_vcf_cnv_call (cnv_roi_id);')
res <- dbSendQuery(conn, 'CREATE INDEX dbvar_vcf_variant_type ON dbvar_vcf_cnv_call (variant_type);')


#############################
# Optional 

# check imported data
dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_roi' )
res <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_roi LIMIT 100')
res %>% head

# check imported data
dbGetQuery(conn, 'select count(*) from dbvar_vcf_cnv_call' )
res1 <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_call LIMIT 100')
res1 %>% head

# check imported data
res1 <- dbGetQuery(conn, 'SELECT * FROM dbvar_vcf_cnv_call WHERE variant_type == "other" AND variant_type_detailed != "INV"')
res1 <- dbGetQuery(conn, 'SELECT COUNT(*) FROM dbvar_vcf_cnv_call GROUP BY variant_type;')

