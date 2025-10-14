import os
import psycopg2
import csv
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

def load_data_from_csv(conn, table_name, csv_file_path):
    """Loads data from a CSV file into the con-postcodes table."""
    csv_postcode_col = 'postcode' 
    csv_con_code_col = 'short_code'
    insert_sql = f'INSERT INTO "{table_name}" (postcode, con_code) VALUES (%s, %s) ON CONFLICT (postcode) DO UPDATE SET con_code = EXCLUDED.con_code;'
    
    successful_ops_count = 0
    error_count = 0
    warning_count = 0

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            if csv_postcode_col not in reader.fieldnames or csv_con_code_col not in reader.fieldnames:
                print(f"Error: CSV file '{csv_file_path}' must contain columns '{csv_postcode_col}' and '{csv_con_code_col}'.", file=sys.stderr)
                print(f"Found columns: {reader.fieldnames}")
                sys.exit(1)

            with conn.cursor() as cursor:
                for row_num, row in enumerate(reader, 1):
                    try:
                        postcode = row.get(csv_postcode_col)
                        con_code = row.get(csv_con_code_col)

                        if not postcode or not con_code:
                            print(f"Warning: Row {row_num}: Missing postcode or con_code. Skipping. Data: {row}", file=sys.stderr)
                            warning_count += 1
                            continue
                        
                        try:
                            normalized_postcode = postcode.upper().replace(" ", "")
                            cursor.execute(insert_sql, (normalized_postcode, con_code))
                            successful_ops_count += 1
                        except psycopg2.Error as e:
                            print(f"DB Error processing row {row_num}: {e}. Postcode: '{postcode}', Con_Code: '{con_code}'. Skipping.", file=sys.stderr)
                            error_count += 1
                            conn.rollback() # Rollback this row's transaction
                            if error_count > 100:
                                print("Error limit exceeded. Aborting.", file=sys.stderr)
                                return False
                    except Exception as e:
                        print(f"An unexpected error occurred during row processing: {e}", file=sys.stderr)
                        error_count += 1
                        conn.rollback()
                        if error_count > 100:
                            print("Error limit exceeded. Aborting.", file=sys.stderr)
                            return False
            
        conn.commit()
        print(f"Processing complete for {csv_file_path}. Inserted/Updated: {successful_ops_count}, Warnings (skipped rows): {warning_count}, Errors: {error_count}")
        return True

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}", file=sys.stderr)
        sys.exit(1)
    except psycopg2.Error as db_e: # Catch other DB errors (e.g. table not found before loop starts)
        print(f"A PostgreSQL error occurred during data loading: {db_e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1) # Exit with non-zero code
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1)

def main():
    """Main function to load constituency postcode data."""
    # Note: DB connection arguments are removed, using environment variables.
    parser = argparse.ArgumentParser(description="Load constituency postcode data from CSV.")
    parser.add_argument("--csv-file", required=True, help="Path to the constituency postcodes CSV file.")
    parser.add_argument("--table", default="con-postcodes", help="Name of the target table.")
    args = parser.parse_args()

    conn = get_db_connection()
    try:
        if not conn:
            sys.exit(1)
        
        table_name = "con-postcodes"
        success = load_data_from_csv(conn, table_name, args.csv_file)
        if not success:
            print("Data loading process aborted due to excessive errors.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main() 