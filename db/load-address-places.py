import csv
import psycopg2
import argparse
import sys
import os
import glob

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

def get_uk_country_id(conn):
    """Fetches the ID for 'United Kingdom' from the countries table."""
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM countries WHERE name = %s;", ("United Kingdom",))
            result = cursor.fetchone()
            if result:
                return result[0]
            else:
                print("Error: 'United Kingdom' not found in countries table. Please ensure it exists.", file=sys.stderr)
                sys.exit(1) # Critical if we are processing UK addresses
    except psycopg2.Error as e:
        print(f"Database error fetching UK country ID: {e}", file=sys.stderr)
        sys.exit(1)

def get_all_countries(conn):
    """Fetches all country IDs and names from the countries table."""
    countries_data = []
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, name FROM countries ORDER BY name;")
            countries_data = cursor.fetchall()
            if not countries_data:
                print("Warning: No countries found in the countries table. 'not specified' places cannot be added.", file=sys.stderr)
    except psycopg2.Error as e:
        print(f"Database error fetching all countries: {e}", file=sys.stderr)
        # Continue, as UK place processing might still be valuable
    return countries_data

def extract_place_from_address(address_string):
    """Extracts the place name (last part) from a comma-separated address string."""
    if not address_string or not isinstance(address_string, str):
        return None
    parts = [part.strip() for part in address_string.split(',')]
    if not parts or not parts[-1]: 
        return None
    # Heuristic from get-uk-places.py to avoid postcodes / long strings
    if len(parts[-1]) > 30 or any(char.isdigit() for char in parts[-1]):
        if len(parts) > 1 and parts[-2] and len(parts[-2]) < 30 and not any(char.isdigit() for char in parts[-2]):
            return parts[-2]
        return None
    return parts[-1]

def load_places_from_address_csv(conn, places_table_name, csv_file_path, uk_country_id, address_column_name, cursor):
    """Processes a single address CSV file and loads extracted UK place names."""
    inserted_in_file = 0
    skipped_in_file = 0 
    error_in_file = 0
    processed_rows = 0

    print(f"Processing UK places from file: {csv_file_path}...")
    insert_sql = f"INSERT INTO {places_table_name} (name, country_id) VALUES (%s, %s) ON CONFLICT (name, country_id) DO NOTHING;"

    try:
        with open(csv_file_path, 'r', encoding='utf-8-sig') as file:
            reader = csv.DictReader(file)
            if address_column_name not in reader.fieldnames:
                print(f"Error: Address column '{address_column_name}' not found in {csv_file_path}. Found: {reader.fieldnames}", file=sys.stderr)
                return processed_rows, inserted_in_file, skipped_in_file, error_in_file + 1
            
            for row_num, row in enumerate(reader, 1):
                processed_rows += 1
                full_address = row.get(address_column_name)
                place_name = extract_place_from_address(full_address)

                if not place_name:
                    error_in_file += 1
                    continue
                
                try:
                    cursor.execute(insert_sql, (place_name, uk_country_id))
                    if cursor.rowcount > 0:
                        inserted_in_file += 1
                    else:
                        skipped_in_file += 1
                except psycopg2.Error as e:
                    print(f"DB Error inserting UK place '{place_name}' from {csv_file_path}, row {row_num}: {e}", file=sys.stderr)
                    conn.rollback() 
                    error_in_file += 1
                else:
                    conn.commit() 
            
    except FileNotFoundError:
        print(f"Error: CSV file not found: {csv_file_path}", file=sys.stderr)
        error_in_file +=1 
    except Exception as e:
        print(f"Error processing file {csv_file_path}: {e}", file=sys.stderr)
        error_in_file +=1 
        if conn and not conn.closed: conn.rollback() 
    
    print(f"Finished {csv_file_path}. UK Places - Processed: {processed_rows}, Inserted: {inserted_in_file}, Skipped: {skipped_in_file}, Errors: {error_in_file}")
    return processed_rows, inserted_in_file, skipped_in_file, error_in_file

def load_not_specified_places(conn, places_table_name, all_countries, cursor):
    """Loads 'not specified' place entries for all provided countries."""
    inserted_ns = 0
    skipped_ns = 0
    errors_ns = 0
    
    if not all_countries:
        print("No countries available to create 'not specified' place entries.")
        return inserted_ns, skipped_ns, errors_ns

    print(f"\nAttempting to load 'not specified' place entries for {len(all_countries)} countries...")
    insert_sql = f"INSERT INTO {places_table_name} (name, country_id) VALUES (%s, %s) ON CONFLICT (name, country_id) DO NOTHING;"
    
    for country_id, country_name in all_countries:
        try:
            cursor.execute(insert_sql, ("not specified", country_id))
            if cursor.rowcount > 0:
                inserted_ns += 1
            else:
                skipped_ns += 1
        except psycopg2.Error as e:
            print(f"DB Error inserting 'not specified' for country '{country_name}' (ID: {country_id}): {e}", file=sys.stderr)
            conn.rollback()
            errors_ns += 1
        else:
            conn.commit()
            
    print(f"Finished loading 'not specified' places. Inserted: {inserted_ns}, Skipped (duplicates): {skipped_ns}, Errors: {errors_ns}")
    return inserted_ns, skipped_ns, errors_ns

def load_uk_places_from_addresses_folder(conn, folder_path, file_pattern, address_column, country_id):
    """
    Scans a folder for address CSV files, extracts unique place names, and inserts them into the 'places' table for the UK.
    """
    total_inserted = 0
    total_skipped = 0
    total_errors = 0
    total_warnings = 0
    files_with_errors = 0
    total_rows_processed = 0

    csv_files = glob.glob(os.path.join(folder_path, file_pattern))
    if not csv_files:
        print(f"No address files found in '{folder_path}' matching pattern '{file_pattern}'. UK place extraction will be skipped.", file=sys.stderr)
        return total_inserted, total_skipped, total_errors, total_warnings, 0, 0, 0

    print(f"Found {len(csv_files)} address files to process for UK places in folder '{folder_path}' with pattern '{file_pattern}'.")
    with conn.cursor() as cursor:
        insert_sql = f"INSERT INTO places (name, country_id) VALUES (%s, %s) ON CONFLICT (name, country_id) DO NOTHING;"
        for csv_file_path in csv_files:
            print(f"Processing UK places from file: {csv_file_path}...")
            inserted_in_file = 0
            skipped_in_file = 0
            errors_in_file = 0
            warnings_in_file = 0
            rows_in_file = 0

            try:
                with open(csv_file_path, mode='r', encoding='utf-8') as csv_file:
                    reader = csv.DictReader(csv_file)
                    if address_column not in reader.fieldnames:
                        print(f"Error: Address column '{address_column}' not found in {csv_file_path}. Found: {reader.fieldnames}", file=sys.stderr)
                        errors_in_file += 1
                        warnings_in_file += 1 # Treat as a warning for now
                        continue

                    for row in reader:
                        rows_in_file += 1
                        address = row.get(address_column)
                        if not address:
                            warnings_in_file += 1
                            continue

                        parts = [part.strip() for part in address.split(',') if part.strip()]
                        if len(parts) > 1:
                            place_name = parts[-1]
                            try:
                                cursor.execute(insert_sql, (place_name, country_id))
                                if cursor.rowcount > 0:
                                    inserted_in_file += 1
                                else:
                                    skipped_in_file += 1
                            except psycopg2.Error as e:
                                print(f"DB Error on row {rows_in_file} in {csv_file_path}: {e}", file=sys.stderr)
                                conn.rollback()
                                errors_in_file += 1
                                if errors_in_file > 100:
                                    print(f"Error limit exceeded in {csv_file_path}. Aborting file.", file=sys.stderr)
                                    break # Stop processing this file
                            else:
                                conn.commit()
                        else:
                            warnings_in_file += 1

            except Exception as e:
                print(f"Error processing file {csv_file_path}: {e}", file=sys.stderr)
                errors_in_file += 1
            
            # After processing each file
            conn.commit()
            if errors_in_file > 0:
                files_with_errors += 1
            
            total_inserted += inserted_in_file
            total_skipped += skipped_in_file
            total_errors += errors_in_file
            total_warnings += warnings_in_file
            total_rows_processed += rows_in_file

            print(f"Finished {csv_file_path}. UK Places - Processed: {rows_in_file}, Inserted: {inserted_in_file}, Skipped: {skipped_in_file}, Warnings: {warnings_in_file}, Errors: {errors_in_file}")

    return total_inserted, total_skipped, total_errors, total_warnings, len(csv_files), files_with_errors, total_rows_processed

def main():
    # DB connection details are now sourced from environment variables.
    parser = argparse.ArgumentParser(description="Extract UK place names from address CSVs and add 'not specified' place entries for all countries into PostgreSQL.")
    parser.add_argument("--input-folder", required=True, help="Folder containing address CSV files (e.g., addresses-AL.csv)")
    parser.add_argument("--address-column", default="Address", help="Name of the column containing the full address string (default: Address)")
    parser.add_argument("--places-table", default="places", help="Name of the target places table (default: places)")
    parser.add_argument("--file-pattern", default="addresses*.csv", help="Pattern for address CSV files (default: addresses*.csv)")

    args = parser.parse_args()

    conn = None
    total_processed_rows_uk = 0
    total_inserted_uk = 0
    total_skipped_uk = 0
    total_errors_uk_files = 0 # Errors in file processing or individual rows for UK places
    files_with_errors_uk = 0

    total_inserted_ns = 0
    total_skipped_ns = 0
    total_errors_ns = 0

    try:
        conn = get_db_connection()
        uk_country_id = get_uk_country_id(conn) # Needed for UK places
        
        # --- Part 1: Process Address CSVs for UK Places ---
        (
            uk_inserted, uk_skipped, uk_errors, uk_warnings, 
            total_files, files_with_errors, total_rows
        ) = load_uk_places_from_addresses_folder(
            conn, args.input_folder, args.file_pattern, args.address_column, uk_country_id
        )

        # --- Part 2: Load "not specified" for all countries ---
        all_countries = get_all_countries(conn)
        if all_countries:
            with conn.cursor() as cursor: # New cursor or reuse if appropriate, new for safety
                i_ns, s_ns, e_ns = load_not_specified_places(conn, args.places_table, all_countries, cursor)
                total_inserted_ns += i_ns
                total_skipped_ns += s_ns
                total_errors_ns += e_ns
        else:
            print("Skipping 'not specified' place loading as no countries were retrieved.")


        print("\n--- Overall Summary ---")
        print("UK Places from Address CSVs:")
        print(f"  Total address files processed: {total_files}")
        print(f"  Address files with one or more errors: {files_with_errors}")
        print(f"  Total address rows processed: {total_rows}")
        print(f"  Total new UK places inserted: {uk_inserted}")
        print(f"  Total UK places skipped (duplicates): {uk_skipped}")
        print(f"  Total UK place data warnings (no place found): {uk_warnings}")
        print(f"  Total UK place row/file processing errors: {uk_errors}")

        print("'Not Specified' Places for All Countries:")
        print(f"  Total 'not specified' places inserted: {total_inserted_ns}")
        print(f"  Total 'not specified' places skipped (duplicates): {total_skipped_ns}")
        print(f"  Total errors during 'not specified' place loading: {total_errors_ns}")
        
        total_errors = uk_errors + total_errors_ns
        if total_errors > 0:
            print(f"\nCompleted with a total of {total_errors} errors.")
            sys.exit(1)
        else:
            print("\nCompleted successfully.")

    except psycopg2.Error as e:
        print(f"A critical PostgreSQL error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected critical error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 