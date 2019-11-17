library(dplyr)
library(DBI)
library(RSQLite)

db = "output/dbvar_v1.sqlite"
dbvar_main_table = 'dbvar_tsv'

# Open a connection (i.e. create or access an existing sqlite file)
conn = dbConnect(drv=SQLite(), dbname=db)

# Check out table exists
alltables = dbListTables(conn)
alltables

# Count the number of elements
dbGetQuery(conn, paste('select count(*) from', dbvar_main_table))
# 4298410 should be the total, as of Nov 2019, as reported in the dbVar website 

# get example query to check all is fine
p2 = dbGetQuery(conn, paste('select * FROM', dbvar_main_table, 'WHERE outermost_start < 10000'))
dim(p2)
head(p2)

# get description of columns in the schema
dbListFields(conn, dbvar_main_table)
dbDisconnect(conn)

