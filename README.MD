# Network Info Parser

This repository includes automated daily exports of the complete RIR database via GitHub Actions.

**What it does:**
- Downloads the latest RIR database dumps from all regional registries (ARIN, RIPE, APNIC, LACNIC, AfriNIC)
- Parses the data into a PostgreSQL database
- Exports the complete database to a gzipped CSV file
- Creates a GitHub Release with the exported file

**Schedule:** Runs daily at 00:00 UTC (can also be triggered manually)

**Download latest exports:** https://github.com/bralbral/network_info/releases

**File format:** Gzipped CSV containing all network blocks with fields:
- inetnum (CIDR notation)
- netname
- country
- description
- maintained_by
- created
- last_modified
- source (RIR)
- status

# If you want to do it locally

## Docker

If you have checked out the GIT repo you can run the script via `docker compose`.
I included some binstubs so you don't have to deal with all the docker commands.

If you run

```sh
./bin/network_info
```

the image will be built, a postgres database is connected, the files are downloaded and the parsing begins.
The database stays up after the run (you can see it via `docker ps`) so you can connect it to your script.

For a one shot query you can run

```
./bin/query IPv4
```

or

```
./bin/query IPv6
```

Or for a psql prompt

```
./bin/psql
```

# Export block table

If you need to export data from PG to another source (Clickhouse, Elasticsearch, etc.) you can use:
```
./bin/export_to_gzip
```
A compressed CSV file will be created with the current date in the filename.

The script supports various options:
```
./bin/export_to_gzip [OPTIONS]

Options:
  -d, --delimiter DELIMITER   Field delimiter (default: ',')
  -t, --table TABLE           Table name to export (default: block)
  -o, --output PREFIX         Output file prefix (default: block_dump)
  -h, --host HOST             Database host (default: db)
  -u, --user USER             Database user (default: network_info)
  -n, --database NAME         Database name (default: network_info)
  -p, --password PASSWORD     Database password (default: network_info)
  --help                       Show this help message
```

Examples:
```
# Default export (comma delimiter)
./bin/export_to_gzip

# Export with semicolon delimiter
./bin/export_to_gzip -d ';'

# Export as TSV (tab-separated)
./bin/export_to_gzip -d $'\t'

# Export custom table with pipe delimiter
./bin/export_to_gzip -t users -d '|' -o users_dump
```

## Export to MMDB format

You can also export the database to MaxMind DB (MMDB) format for use with GeoIP2-compatible tools:
```
./bin/export_to_mmdb
```
An MMDB file will be created with the current date in the filename.

**⚠️ HIGH MEMORY USAGE WARNING**
The MMDB export process loads all data into memory before writing the final file. For large databases (millions of records), this can require several GB of RAM. Ensure you have sufficient memory available before running the export.

The script supports various options:
```
./bin/export_to_mmdb [OPTIONS]

Options:
  -t, --table TABLE           Table name to export (default: block)
  -o, --output PREFIX         Output file prefix (default: block_dump)
  -h, --host HOST             Database host (default: db)
  -u, --user USER             Database user (default: network_info)
  -n, --database NAME         Database name (default: network_info)
  -p, --password PASSWORD     Database password (default: network_info)
  --help                       Show this help message
```

Examples:
```
# Default export
./bin/export_to_mmdb

# Export custom table
./bin/export_to_mmdb -t users -o users_dump

# Export with custom database connection
./bin/export_to_mmdb -h localhost -u myuser -n mydb -p mypass
```

## Using the MMDB file

The MMDB file contains the following network information fields for each IP range:

- **netname** - Network name identifier
- **country** - Country code (e.g., US, RU, DE)
- **description** - Network description
- **maintained_by** - Maintainer information
- **created** - Creation date (YYYY-MM-DD format)
- **last_modified** - Last modification date (YYYY-MM-DD format)
- **source** - Source RIR (ARIN, RIPE, APNIC, LACNIC, AfriNIC)
- **status** - Network status

Once you have the MMDB file, you can use it with various tools:

### Python examples

Simple lookup:
```python
import maxminddb

# Open the MMDB file
with maxminddb.open_database('block_dump_2026-05-01.mmdb') as reader:
    # Lookup an IP address
    result = reader.get('8.8.8.8')
    if result:
        print(f"Network: {result['netname']}")
        print(f"Country: {result['country']}")
        print(f"Source: {result['source']}")
```

### Command line example
```bash
# Install mmdblookup tool
sudo apt install mmdb-bin

# Lookup an IP address
mmdblookup --file block_dump_2026-05-01.mmdb --ip 8.8.8.8
```
