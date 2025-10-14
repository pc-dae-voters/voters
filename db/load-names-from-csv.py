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

def load_names_to_table(conn, names_list, table_name, cursor):
    """Loads a list of names into the specified table."""
    sql = f"INSERT INTO \"{table_name}\" (name) VALUES (%s) ON CONFLICT (name) DO NOTHING;"
    inserted_count = 0
    skipped_count = 0
    error_count = 0
    
    for name in names_list:
        try:
            cursor.execute(sql, (name,))
            if cursor.rowcount > 0:
                inserted_count += 1
            else:
                skipped_count += 1
        except psycopg2.Error as e:
            print(f"DB Error inserting name '{name}' into {table_name}: {e}", file=sys.stderr)
            conn.rollback() 
            error_count += 1
            if error_count > 100:
                print(f"Error limit exceeded for table {table_name}. Aborting.", file=sys.stderr)
                return inserted_count, skipped_count, error_count
        else:
            conn.commit()
    return inserted_count, skipped_count, error_count

def load_first_names_with_gender_to_table(conn, first_names_data, cursor):
    """Loads first names with gender to the first_names table."""
    sql = "UPDATE first_names SET gender = %s WHERE name = %s AND gender IS NULL;"
    updated_count = 0
    error_count = 0
    
    for item in first_names_data:
        try:
            name = item['name']
            gender = item['gender']
            if gender in ['M', 'F']:
                cursor.execute(sql, (gender, name))
                if cursor.rowcount > 0:
                    updated_count += 1
        except psycopg2.Error as e:
            print(f"DB Error updating gender for name '{name}': {e}", file=sys.stderr)
            conn.rollback()
            error_count += 1
            if error_count > 100:
                print(f"Error limit exceeded for table first_names with gender. Aborting.", file=sys.stderr)
                return updated_count, error_count
        else:
            conn.commit()
    print(f"Updated gender for {updated_count} first names.")
    return updated_count, error_count

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

        # Convert dict to list of tuples for the new function
        first_names = [{"name": name, "gender": gender} for name, gender in unique_first_names_data.items()]
        surnames = sorted(list(unique_surnames))

    except Exception as e:
        print(f"An unexpected critical error occurred during name collection: {e}", file=sys.stderr)
        sys.exit(1)

    conn = get_db_connection()
    if not conn:
        sys.exit(1)

    try:
        with conn.cursor() as cursor:
            # Load first names and surnames
            inserted_count_fn, skipped_count_fn, first_name_errors = load_names_to_table(conn, [d['name'] for d in first_names], 'first_names', cursor)
            print(f"Loaded {inserted_count_fn} first names, skipped {skipped_count_fn} duplicates.")

            inserted_count_sn, skipped_count_sn, surname_errors = load_names_to_table(conn, surnames, 'surnames', cursor)
            print(f"Loaded {inserted_count_sn} surnames, skipped {skipped_count_sn} duplicates.")
            
            # Load first names with gender
            _, gender_errors = load_first_names_with_gender_to_table(conn, first_names, cursor)

            if first_name_errors >= 100 or surname_errors >= 100 or gender_errors >= 100:
                print("Data loading process aborted due to excessive errors.", file=sys.stderr)
                sys.exit(1)

    except Exception as e:
        print(f"An unexpected error occurred in main: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main() 