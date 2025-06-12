import csv
import psycopg2
import argparse
import sys
import os
import glob
import random

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

def load_names_to_table(conn, table_name, names_to_load, cursor):
    inserted_count = 0
    skipped_count = 0
    error_count = 0
    
    sql = f"INSERT INTO {table_name} (name) VALUES (%s) ON CONFLICT (name) DO NOTHING;"
    for name in names_to_load:
        if not name: # Skip empty names
            continue
        try:
            cursor.execute(sql, (name,))
            if cursor.rowcount > 0:
                inserted_count += 1
            else:
                skipped_count += 1
        except psycopg2.Error as e:
            print(f"DB Error inserting name '{name}' into {table_name}: {e}", file=sys.stderr)
            conn.rollback() # Rollback this insert, but continue with others
            error_count += 1
        else:
            conn.commit() # Commit successful insert or skip
    return inserted_count, skipped_count, error_count

def load_first_names_with_gender_to_table(conn, first_names_data, cursor):
    inserted_count = 0
    skipped_count = 0
    error_count = 0
    
    sql = "INSERT INTO first_names (name, gender) VALUES (%s, %s) ON CONFLICT (name) DO NOTHING;"
    for name, gender in first_names_data:
        if not name: # Skip empty names
            continue
        try:
            cursor.execute(sql, (name, gender))
            if cursor.rowcount > 0:
                inserted_count += 1
            else:
                skipped_count += 1
        except psycopg2.Error as e:
            print(f"DB Error inserting name '{name}' (gender: {gender}) into first_names: {e}", file=sys.stderr)
            conn.rollback() # Rollback this insert, but continue with others
            error_count += 1
        else:
            conn.commit() # Commit successful insert or skip
    return inserted_count, skipped_count, error_count

def main():
    """Main function to load names."""
    # DB connection details are now sourced from environment variables.
    parser = argparse.ArgumentParser(description="Load first and last names from CSV files, with sampling for non-GB files.")
    parser.add_argument("--names-data-folder", default="pc-dae-voters/data/names/data", help="Folder containing country-specific name CSV files.")
    parser.add_argument("--file-pattern", default="*.csv", help="Pattern for name CSV files (default: *.csv)")
    parser.add_argument("--gb-file", default="GB.csv", help="Name of the Great Britain CSV file (process 100% of this). Case-sensitive.")
    parser.add_argument("--other-files-sample-rate", type=float, default=0.1, help="Sample rate (0.0 to 1.0) for names from non-GB files (default: 0.1 for 10%)")
    parser.add_argument("--random-seed", type=int, help="Optional random seed for reproducibility of sampling")

    args = parser.parse_args()

    if args.random_seed is not None:
        random.seed(args.random_seed)

    conn = get_db_connection()
    unique_first_names_data = {} # Changed from set to dict
    unique_surnames = set()
    files_processed_count = 0
    rows_processed_count = 0

    try:
        name_csv_files_path = os.path.join(args.names_data_folder, args.file_pattern)
        csv_files = glob.glob(name_csv_files_path)

        if not csv_files:
            print(f"No name CSV files found in '{args.names_data_folder}' matching pattern '{args.file_pattern}'. Exiting.", file=sys.stderr)
            sys.exit(0)

        print(f"Found {len(csv_files)} name CSV files in '{args.names_data_folder}'.")

        for csv_file_path in csv_files:
            files_processed_count += 1
            file_name = os.path.basename(csv_file_path)
            print(f"\nProcessing file: {file_name}...")
            
            is_gb_file = (file_name == args.gb_file)
            sample_rate = 1.0 if is_gb_file else args.other_files_sample_rate
            if is_gb_file:
                 print(f"  Processing 100% of names from {file_name}.")
            else:
                 print(f"  Sampling approximately {sample_rate*100:.1f}% of names from {file_name}.")

            try:
                with open(csv_file_path, 'r', encoding='utf-8-sig') as file:
                    reader = csv.DictReader(file, fieldnames=['first_name', 'last_name', 'gender', 'country_code'])
                    # No header check, assuming format: first_name,last_name,gender,country_code
                    
                    for row_num, row in enumerate(reader, 1):
                        rows_processed_count +=1
                        if random.random() < sample_rate:
                            first_name = row.get('first_name')
                            surname = row.get('last_name') # Changed from 'surname' to 'last_name' based on description.txt
                            gender = row.get('gender')

                            if first_name:
                                fn_clean = first_name.strip()
                                if fn_clean and fn_clean not in unique_first_names_data: # Store first encountered gender
                                    gender_raw = gender.strip() if gender and gender.strip() else None
                                    actual_gender = gender_raw[0].upper() if gender_raw else None
                                    unique_first_names_data[fn_clean] = actual_gender
                            if surname:
                                surname_clean = surname.strip()
                                if surname_clean:
                                    unique_surnames.add(surname_clean)
            except FileNotFoundError:
                print(f"Error: CSV file disappeared during processing: {csv_file_path}", file=sys.stderr)
            except Exception as e:
                print(f"Error processing file {csv_file_path}, row {row_num if 'row_num' in locals() else 'unknown'}: {e}", file=sys.stderr)
        
        print(f"\n--- Name Collection Summary ---")
        print(f"Total files processed: {files_processed_count}")
        print(f"Total rows scanned: {rows_processed_count}")
        print(f"Unique first names collected: {len(unique_first_names_data)}")
        print(f"Unique surnames collected: {len(unique_surnames)}")

        with conn.cursor() as cursor:
            print("\nLoading first names into 'first_names' table...")
            # Convert dict to list of tuples for the new function
            first_names_list_with_gender = sorted(list(unique_first_names_data.items()))
            fn_inserted, fn_skipped, fn_errors = load_first_names_with_gender_to_table(conn, first_names_list_with_gender, cursor)
            print(f"First names - Inserted: {fn_inserted}, Skipped (duplicates): {fn_skipped}, Errors: {fn_errors}")

            print("\nLoading surnames into 'surnames' table...")
            sn_inserted, sn_skipped, sn_errors = load_names_to_table(conn, "surnames", sorted(list(unique_surnames)), cursor)
            print(f"Surnames - Inserted: {sn_inserted}, Skipped (duplicates): {sn_skipped}, Errors: {sn_errors}")

        total_errors = fn_errors + sn_errors
        if total_errors > 0:
            print(f"\nCompleted with {total_errors} database errors during loading.")
            sys.exit(1)
        else:
            print("\nName loading completed successfully.")

    except psycopg2.Error as e:
        print(f"A critical PostgreSQL error occurred: {e}", file=sys.stderr)
        if conn: conn.rollback()
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected critical error occurred: {e}", file=sys.stderr)
        if conn: conn.rollback()
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 