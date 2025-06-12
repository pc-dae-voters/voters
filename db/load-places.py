import os
import csv
import psycopg2
import argparse
import sys

def get_db_connection():
    """Establishes a database connection using environment variables."""
    try:
        conn = psycopg2.connect(
            host=os.environ['PGHOST'],
            port=os.environ['PGPORT'],
            dbname=os.environ['PGDATABASE'],
            user=os.environ['PGUSER'],
            password=os.environ['PGPASSWORD']
        )
        return conn
    except KeyError as e:
        print(f"Error: Environment variable {e} not set.")
        raise
    except psycopg2.OperationalError as e:
        print(f"Error: Database connection failed: {e}")
        raise

def get_country_id(conn, country_name):
    """Fetches the ID of a given country from the countries table."""
    # This function now assumes the countries table exists and the country_name is present.
    # If not, a psycopg2.Error will be raised by the execute and caught by the caller.
    with conn.cursor() as cursor:
        cursor.execute("SELECT id FROM countries WHERE name = %s;", (country_name,))
        result = cursor.fetchone()
        if result:
            return result[0]
        else:
            # If country is not found, we let the psycopg2.Error propagate or handle it as a non-DB error.
            # For this version, we'll raise a more specific error if not found, to be caught by the main try-except.
            raise ValueError(f"Country '{country_name}' not found in countries table.")

# Removed create_places_table_if_not_exists function

def insert_places_from_csv(conn, table_name, csv_file_path):
    """Inserts places from a CSV file into the places table."""
    insert_sql = f"INSERT INTO {table_name} (name, country_id) VALUES (%s, %s) ON CONFLICT (name, country_id) DO NOTHING;"
    inserted_count = 0
    skipped_count = 0
    error_count = 0
    country_id_cache = {}

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            if 'city_name' not in reader.fieldnames or 'country_reference_name' not in reader.fieldnames:
                print(f"CSV file must contain 'city_name' and 'country_reference_name' columns.", file=sys.stderr)
                sys.exit(1)

            with conn.cursor() as cursor:
                for row_num, row in enumerate(reader, 1):
                    city_name = row.get('city_name')
                    country_reference_name = row.get('country_reference_name')

                    if not city_name or not country_reference_name:
                        print(f"Skipping row {row_num} due to missing city_name or country_reference_name.", file=sys.stderr)
                        error_count += 1
                        continue

                    country_id = country_id_cache.get(country_reference_name)
                    if not country_id:
                        country_id = get_country_id(conn, country_reference_name) # This might raise psycopg2.Error or ValueError
                        if country_id: # Should always be true if no error above
                            country_id_cache[country_reference_name] = country_id
                        # else case is handled by exception from get_country_id
                    
                    cursor.execute(insert_sql, (city_name, country_id))
                    if cursor.rowcount > 0: inserted_count += 1
                    else: skipped_count +=1
                conn.commit()
        print(f"Successfully processed CSV. Inserted: {inserted_count}, Skipped (duplicates): {skipped_count}, Errors: {error_count}")
        if error_count > 0: # If any row-level errors were caught and counted (but didn't stop the script)
             print(f"Note: {error_count} rows had issues and were skipped.")
             # sys.exit(1) # Optionally exit with error if even one row failed processing within the loop

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}", file=sys.stderr)
        sys.exit(1)
    except (psycopg2.Error, ValueError) as db_val_e: # Catch DB errors or ValueErrors from get_country_id
        print(f"Database or data error during place insertion: {db_val_e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1) # Exit with non-zero code
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1)

def main():
    """Main function to load places data."""
    # DB connection details are now sourced from environment variables.
    parser = argparse.ArgumentParser(description="Load UK places data from a CSV file into the database.")
    parser.add_argument('--csv-file', required=True, help='Path to the CSV file containing place names.')
    parser.add_argument('--table', default='places', help='The name of the database table to load data into.')
    args = parser.parse_args()

    conn = get_db_connection()
    try:
        if conn:
            # Removed call to ensure table exists
            insert_places_from_csv(conn, args.table, args.csv_file)
    except (psycopg2.Error, ValueError) as e:
        print(f"A PostgreSQL or data validation error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred in main: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 