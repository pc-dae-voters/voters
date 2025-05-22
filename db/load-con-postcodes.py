import csv
import psycopg2
import argparse
import sys

def get_db_connection(db_host, db_port, db_name, db_user, db_password):
    """Establishes a connection to the PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            dbname=db_name,
            user=db_user,
            password=db_password
        )
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to PostgreSQL database: {e}", file=sys.stderr)
        sys.exit(1)

def load_data_from_csv(conn, table_name, csv_file_path):
    """Loads data from a CSV file into the con_postcodes table."""
    csv_postcode_col = 'postcode' 
    csv_con_code_col = 'con_code'
    insert_sql = f"INSERT INTO {table_name} (postcode, con_code) VALUES (%s, %s) ON CONFLICT (postcode) DO UPDATE SET con_code = EXCLUDED.con_code;"
    
    successful_ops_count = 0
    error_count = 0

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            if csv_postcode_col not in reader.fieldnames or csv_con_code_col not in reader.fieldnames:
                print(f"Error: CSV file '{csv_file_path}' must contain columns '{csv_postcode_col}' and '{csv_con_code_col}'.", file=sys.stderr)
                print(f"Found columns: {reader.fieldnames}")
                sys.exit(1)

            with conn.cursor() as cursor:
                for row_num, row in enumerate(reader, 1):
                    postcode = row.get(csv_postcode_col)
                    con_code = row.get(csv_con_code_col)

                    if not postcode or not con_code:
                        print(f"Warning: Row {row_num}: Missing postcode or con_code. Skipping. Data: {row}", file=sys.stderr)
                        error_count += 1
                        continue
                    
                    try:
                        normalized_postcode = postcode.upper().replace(" ", "")
                        cursor.execute(insert_sql, (normalized_postcode, con_code))
                        successful_ops_count +=1 
                        conn.commit() # Commit each successful row
                    except psycopg2.Error as e: # Catch DB errors per row
                        print(f"DB Error processing row {row_num}: {e}. Postcode: '{postcode}', Con_Code: '{con_code}'. Skipping.", file=sys.stderr)
                        error_count += 1
                        conn.rollback() # Rollback this row's transaction
            
        print(f"Processed CSV. Successful operations (Inserts/Updates): {successful_ops_count}, Errors/Skipped: {error_count}")
        if error_count > 0:
            # If any row had a DB error and was rolled back, we might want to indicate overall script failure.
            # However, the script currently continues and reports errors.
            # To make the script exit with non-zero if ANY row fails due to DB error, 
            # a flag would be needed, checked after the loop, or raise an exception to be caught by the outer try-except.
            # For now, it completes but reports errors.
            pass # Or: sys.exit(1) if any DB error in loop should mean overall failure

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
    parser = argparse.ArgumentParser(description="Load postcode to constituency mapping from CSV to PostgreSQL.")
    parser.add_argument("--pghost", required=True)
    parser.add_argument("--pgport", required=True)
    parser.add_argument("--pgdatabase", required=True)
    parser.add_argument("--pguser", required=True)
    parser.add_argument("--pgpassword", required=True)
    parser.add_argument("--csv-file", required=True)
    parser.add_argument("--table", default="con_postcodes")
    args = parser.parse_args()

    conn = None
    try:
        conn = get_db_connection(args.pghost, args.pgport, args.pgdatabase, args.pguser, args.pgpassword)
        if conn:
            load_data_from_csv(conn, args.table, args.csv_file)
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