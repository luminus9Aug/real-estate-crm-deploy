#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print usage
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 -s <SOURCE_DB_URL> -t <TARGET_DB_URL>"
    echo ""
    echo "This script safely clones a PostgreSQL database from a source to a target."
    echo "It drops the public schema on the target before copying to ensure a clean slate."
    echo ""
    echo "Options:"
    echo "  -s  Source database connection string (URI format)"
    echo "  -t  Target database connection string (URI format)"
    echo "  -h  Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -s \"postgres://user:pass@remote:5432/db\" -t \"postgres://user:pass@localhost:5432/local_db\""
    exit 1
}

# Parse command line arguments
while getopts "s:t:h" opt; do
    case ${opt} in
        s ) SOURCE_DB_URL=$OPTARG ;;
        t ) TARGET_DB_URL=$OPTARG ;;
        h ) usage ;;
        \? ) usage ;;
    esac
done

# Ensure both URLs are provided
if [ -z "${SOURCE_DB_URL}" ] || [ -z "${TARGET_DB_URL}" ]; then
    echo -e "${RED}Error: Both Source (-s) and Target (-t) URLs are required.${NC}"
    usage
fi

# Ensure required commands are available
if ! command -v pg_dump &> /dev/null; then
    echo -e "${RED}Error: pg_dump could not be found. Please install PostgreSQL client tools.${NC}"
    exit 1
fi

if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql could not be found. Please install PostgreSQL client tools.${NC}"
    exit 1
fi

echo -e "${YELLOW}WARNING: This is a destructive operation!${NC}"
echo -e "You are about to completely WIPE the target database and overwrite it with the source database."
echo ""
echo -e "Target DB: ${RED}${TARGET_DB_URL}${NC}"
echo ""
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo    # move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Operation cancelled.${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Step 1/3: Checking connections...${NC}"
# Quick test connection to target
if ! psql "$TARGET_DB_URL" -c "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${RED}Error: Could not connect to the Target Database.${NC}"
    exit 1
fi

# Quick test connection to source
if ! psql "$SOURCE_DB_URL" -c "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${RED}Error: Could not connect to the Source Database.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Step 2/3: Dropping public schema on target to ensure a clean slate...${NC}"
psql "$TARGET_DB_URL" -c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO public;"

echo -e "\n${YELLOW}Step 3/3: Cloning data from source to target...${NC}"
echo "This might take a while depending on the database size..."

# Run the clone pipeline
pg_dump "$SOURCE_DB_URL" -O -x | psql "$TARGET_DB_URL"

echo -e "\n${GREEN}✅ Database cloned successfully!${NC}"
