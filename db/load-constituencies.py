import os
import psycopg2
from psycopg2 import sql
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
    """Loads data from a CSV file into the specified PostgreSQL table."""
    db_columns = ["code", "name", "tla", "nation", "region", "ctype", "area"]
    csv_columns_map = {
        "short_code": "code", 
        "three_code": "tla", 
        "con_type": "ctype"
    }
    direct_map_csv_cols = ["name", "nation", "region", "area"]

    insert_sql_template = f"INSERT INTO {table_name} ({', '.join(db_columns)}) VALUES ({', '.join(['%s'] * len(db_columns))}) ON CONFLICT (code) DO NOTHING;"
    
    inserted_count = 0
    skipped_count = 0
    error_count = 0

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            required_csv_headers = sorted(list(set(list(csv_columns_map.keys()) + direct_map_csv_cols)))
            missing_headers = [h for h in required_csv_headers if h not in reader.fieldnames]
            if missing_headers:
                print(f"Error: CSV file '{csv_file_path}' is missing required columns: {', '.join(missing_headers)}", file=sys.stderr)
                sys.exit(1)

            with conn.cursor() as cursor:
                for row_num, row_data in enumerate(reader, 1):
                    try:
                        values_to_insert = []
                        for db_col_name in db_columns:
                            csv_col_name = next((k for k, v in csv_columns_map.items() if v == db_col_name), None)
                            if not csv_col_name and db_col_name in direct_map_csv_cols:
                                csv_col_name = db_col_name
                            
                            if not csv_col_name:
                                raise ValueError(f"Could not find source CSV column for database column: {db_col_name}")

                            val = row_data.get(csv_col_name)
                            if db_col_name == "area":
                                if val == '' or val is None: values_to_insert.append(None)
                                else:
                                    try: values_to_insert.append(float(val))
                                    except ValueError: 
                                        print(f"Warning: Row {row_num}: Could not convert '{val}' to float for area. Using NULL.", file=sys.stderr)
                                        values_to_insert.append(None)
                            else:
                                values_to_insert.append(val if val != '' else None)
                        
                        cursor.execute(insert_sql_template, tuple(values_to_insert))
                        if cursor.rowcount > 0: inserted_count += 1
                        else: skipped_count += 1
                    except Exception as e:
                        print(f"Error processing row {row_num} from CSV: {e}. Row data: {row_data}", file=sys.stderr)
                        error_count += 1
                
                if error_count > 0:
                    print(f"Warning: Encountered {error_count} errors. Rolling back all changes.", file=sys.stderr)
                    conn.rollback()
                    sys.exit(1) # Exit with non-zero code if errors occurred
                else:
                    conn.commit()
                    print(f"Successfully processed CSV. Inserted: {inserted_count}, Skipped (duplicates): {skipped_count}")

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}", file=sys.stderr)
        sys.exit(1)
    except psycopg2.Error as db_e: # Catch database specific errors here
        print(f"Database error during data loading: {db_e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1) # Exit with non-zero code
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1)

def main():
    """
    Main function to parse arguments, connect to the database,
    and load constituency data from a CSV file.
    """
    # Note: Argument parsing for DB connection details is removed.
    # The script now relies on environment variables set by db-env.sh.
    parser = argparse.ArgumentParser(description="Load constituency data from a CSV file.")
    parser.add_argument("--csv-file", required=True, help="Path to the constituency data CSV file.")
    args = parser.parse_args()
    
    conn = get_db_connection()
    try:
        if conn:
            load_data_from_csv(conn, "constituencies", args.csv_file)
    except psycopg2.Error as e: # Catch potential connection errors or others not caught in load_data
        print(f"A PostgreSQL error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e: # Catch any other unexpected errors in main
        print(f"An unexpected error occurred in main: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 