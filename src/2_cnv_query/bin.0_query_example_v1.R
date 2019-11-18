source('src/2_cnv_query/lib.0_query_functions_v1.R')
db = "output/dbvar_v1.sqlite" # where is the db?

# Open a connection (i.e. create or access an existing sqlite file)
conn = dbConnect(drv=SQLite(), dbname=db)


# Example of exact match
chr = '1'; start = 10001; stop = 1535693
gen_matching_query(chr, start, stop, strategy = 'exact')
cnv_match(conn, chr, start, stop, strategy = 'exact')

# Example of non exact match
chr = '1'; start = 10001; stop = 1535692
gen_matching_query(chr, start, stop, strategy = 'partial')
pp = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 10, max_dist = NULL)
pp %>% head(20)


# Example relevant to oncology
# TP53 loss
# TP53 
chr = '17'; start = 7668402; stop = 7687550
pp = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 10, max_dist = 1000)
pp %>% head(20)

# Example relevant to oncology
# NRAS
chr = '1'; start = 114704464; stop = 114716894
pp = cnv_match(conn, chr, start, stop, strategy = 'partial', top = 100, max_dist = NULL)
pp %>% head(20)

dbDisconnect(conn)
