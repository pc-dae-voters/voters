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

def get_country_id(conn, country_name="United Kingdom"):
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM countries WHERE name = %s;", (country_name,))
            result = cursor.fetchone()
            if result:
                return result[0]
            else:
                print(f"Error: Country '{country_name}' not found in countries table. Cannot proceed.", file=sys.stderr)
                sys.exit(1)
    except psycopg2.Error as e:
        print(f"Database error fetching country ID for '{country_name}': {e}", file=sys.stderr)
        sys.exit(1)

def get_place_id(conn, place_name, uk_country_id, cursor):
    try:
        cursor.execute(
            "SELECT id FROM places WHERE name = %s AND country_id = %s;",
            (place_name, uk_country_id)
        )
        result = cursor.fetchone()
        return result[0] if result else None
    except psycopg2.Error as e:
        print(f"DB error looking up place '{place_name}': {e}", file=sys.stderr)
        return None

def parse_address_field(full_address_field):
    if not full_address_field or not isinstance(full_address_field, str):
        return None, None
    if ',' not in full_address_field:
        # Assuming if no comma, the whole thing might be street, and place is unknown from this field
        return full_address_field.strip(), None 
    
    parts = full_address_field.rsplit(',', 1)
    address_part = parts[0].strip()
    place_part = parts[1].strip()
    return address_part, place_part

def normalize_postcode(postcode):
    if not postcode or not isinstance(postcode, str):
        return None
    return postcode.upper().replace(" ", "")

def main():
    """Main function to load addresses."""
    # DB connection details are now sourced from environment variables.
    parser = argparse.ArgumentParser(description="Load address data from multiple CSV files into the database.")
    parser.add_argument("--input-folder", required=True, help="Folder containing address CSV files.")
    parser.add_argument("--address-column", default="Address", help="Name of the column containing the full address string (default: Address)")
    parser.add_argument("--postcode-column", default="Postcode", help="Name of the column containing the postcode (default: Postcode)")
    parser.add_argument("--file-pattern", default="*.csv", help="Pattern for address CSV files (default: *.csv)")
    parser.add_argument("--target-country", default="United Kingdom", help="Target country for place lookup (default: United Kingdom)")

    args = parser.parse_args()

    conn = get_db_connection()
    total_rows_processed = 0
    total_inserted = 0
    total_skipped_place_not_found = 0
    total_skipped_duplicate = 0
    total_errors = 0
    total_warnings = 0
    files_processed_count = 0

    try:
        target_country_id = get_country_id(conn, args.target_country)

        csv_files = glob.glob(os.path.join(args.input_folder, args.file_pattern))
        if not csv_files:
            print(f"No files found in '{args.input_folder}' matching pattern '{args.file_pattern}'. Exiting.", file=sys.stderr)
            sys.exit(0)

        print(f"Found {len(csv_files)} files to process in '{args.input_folder}'.")

        with conn.cursor() as cursor:
            for csv_file_path in csv_files:
                files_processed_count += 1
                print(f"\nProcessing file: {csv_file_path}...")
                rows_in_file = 0
                inserted_in_file = 0
                skipped_place_in_file = 0
                skipped_dup_in_file = 0
                errors_in_file = 0
                warnings_in_file = 0
                
                try:
                    with open(csv_file_path, 'r', encoding='utf-8-sig') as file:
                        reader = csv.DictReader(file)
                        if args.address_column not in reader.fieldnames:
                            print(f"Warning: Address column '{args.address_column}' not found in {csv_file_path}. Skipping file. Headers: {reader.fieldnames}", file=sys.stderr)
                            errors_in_file += 1
                            continue
                        if args.postcode_column not in reader.fieldnames:
                            print(f"Warning: Postcode column '{args.postcode_column}' not found in {csv_file_path}. Skipping file. Headers: {reader.fieldnames}", file=sys.stderr)
                            errors_in_file += 1
                            continue

                        for row_num, row in enumerate(reader, 1):
                            rows_in_file += 1
                            total_rows_processed += 1
                            
                            full_address_field = row.get(args.address_column)
                            csv_postcode = row.get(args.postcode_column)

                            street_address, place_name_from_csv = parse_address_field(full_address_field)
                            normalized_postcode = normalize_postcode(csv_postcode)

                            if not street_address or not place_name_from_csv or not normalized_postcode:
                                print(f"Warning: Row {row_num} in {csv_file_path}: Insufficient data. Skipping.", file=sys.stderr)
                                warnings_in_file += 1
                                continue

                            place_id = get_place_id(conn, place_name_from_csv, target_country_id, cursor)

                            if not place_id:
                                print(f"Warning: Row {row_num} in {csv_file_path}: Place '{place_name_from_csv}' (Country: {args.target_country}) not found in places table. Skipping address.", file=sys.stderr)
                                skipped_place_in_file += 1
                                continue
                            
                            try:
                                cursor.execute(
                                    "INSERT INTO addresses (address, place_id, postcode) VALUES (%s, %s, %s) "
                                    "ON CONFLICT (address, place_id, postcode) DO NOTHING;",
                                    (street_address, place_id, normalized_postcode)
                                )
                                if cursor.rowcount > 0:
                                    inserted_in_file += 1
                                else:
                                    skipped_dup_in_file += 1
                                conn.commit()
                            except psycopg2.Error as e:
                                print(f"DB Error inserting address for row {row_num} ('{street_address}', PlaceID:{place_id}, '{normalized_postcode}'): {e}", file=sys.stderr)
                                conn.rollback()
                                errors_in_file += 1
                                if total_errors + errors_in_file > 100:
                                    print("Error limit exceeded. Aborting.", file=sys.stderr)
                                    sys.exit(1)
                                
                except FileNotFoundError:
                    print(f"Error: CSV file not found during processing: {csv_file_path}", file=sys.stderr)
                    errors_in_file += 1
                except Exception as e:
                    print(f"Error processing file {csv_file_path}: {e}", file=sys.stderr)
                    errors_in_file += 1
                    if total_errors + errors_in_file > 100:
                        print("Error limit exceeded. Aborting.", file=sys.stderr)
                        sys.exit(1)
                    if conn and not conn.closed: conn.rollback()
                
                total_inserted += inserted_in_file
                total_skipped_place_not_found += skipped_place_in_file
                total_skipped_duplicate += skipped_dup_in_file
                total_errors += errors_in_file
                total_warnings += warnings_in_file
                print(f"Finished {csv_file_path}. Rows: {rows_in_file}, Inserted: {inserted_in_file}, Skipped (Place NF): {skipped_place_in_file}, Skipped (Dup): {skipped_dup_in_file}, Errors: {errors_in_file}, Warnings: {warnings_in_file}")

        print("\n--- Overall Summary ---")
        print(f"Total files processed: {files_processed_count}")
        print(f"Total rows processed across all files: {total_rows_processed}")
        print(f"Total new addresses inserted: {total_inserted}")
        print(f"Total addresses skipped (place not found): {total_skipped_place_not_found}")
        print(f"Total addresses skipped (duplicate): {total_skipped_duplicate}")
        print(f"Total row/file processing errors: {total_errors}")
        print(f"Total row/file processing warnings: {total_warnings}")
        
        if total_errors > 0:
            print("Completed with errors.")
            sys.exit(1)
        else:
            print("Completed successfully.")

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