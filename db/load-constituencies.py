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
    # Map CSV columns to database columns
    csv_to_db_map = {
        'short_code': 'code',
        'three_code': 'tla',
        'con_type': 'ctype'
    }
    
    # Direct mapping columns (same name in CSV and DB)
    direct_map_cols = ['name', 'nation', 'region', 'area']
    
    # All database columns in order
    db_columns = ['code', 'name', 'tla', 'nation', 'region', 'ctype', 'area']
    
    insert_sql = f"""
        INSERT INTO {table_name} ({', '.join(db_columns)})
        VALUES ({', '.join(['%s'] * len(db_columns))})
        ON CONFLICT (code) DO NOTHING;
    """
    
    inserted_count = 0
    skipped_count = 0
    error_count = 0

    try:
        with open(csv_file_path, 'r', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            
            # Verify required columns exist
            required_headers = list(csv_to_db_map.keys()) + direct_map_cols
            missing_headers = [h for h in required_headers if h not in reader.fieldnames]
            if missing_headers:
                print(f"Error: CSV file '{csv_file_path}' is missing required columns: {', '.join(missing_headers)}", file=sys.stderr)
                sys.exit(1)

            with conn.cursor() as cursor:
                for row_num, row in enumerate(reader, 1):
                    try:
                        values = []
                        for db_col in db_columns:
                            # Find the corresponding CSV column
                            csv_col = next((k for k, v in csv_to_db_map.items() if v == db_col), None)
                            if not csv_col and db_col in direct_map_cols:
                                csv_col = db_col
                            
                            if not csv_col:
                                raise ValueError(f"Could not find source CSV column for database column: {db_col}")

                            value = row.get(csv_col, '')
                            
                            # Handle empty values
                            if value == '':
                                values.append(None)
                                continue
                                
                            # Handle area as float
                            if db_col == 'area':
                                try:
                                    values.append(float(value))
                                except ValueError:
                                    print(f"Warning: Row {row_num}: Could not convert '{value}' to float for area. Using NULL.", file=sys.stderr)
                                    values.append(None)
                            else:
                                values.append(value)

                        cursor.execute(insert_sql, tuple(values))
                        if cursor.rowcount > 0:
                            inserted_count += 1
                        else:
                            skipped_count += 1
                            
                    except psycopg2.Error as db_e:
                        print(f"Database error on row {row_num}: {db_e}", file=sys.stderr)
                        error_count += 1
                        conn.rollback()
                        if error_count > 100:
                            print("Error limit exceeded. Aborting.", file=sys.stderr)
                            return False
                        continue
                    except Exception as e:
                        print(f"Error processing row {row_num}: {e}", file=sys.stderr)
                        error_count += 1
                        conn.rollback()
                        if error_count > 100:
                            print("Error limit exceeded. Aborting.", file=sys.stderr)
                            return False
                        continue

                conn.commit()
                print(f"Processing complete. Inserted: {inserted_count}, Skipped (duplicates): {skipped_count}, Errors: {error_count}")
                if error_count > 0:
                    print(f"Warning: {error_count} rows had errors and were skipped.", file=sys.stderr)
                    return False
                return True

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_file_path}", file=sys.stderr)
        sys.exit(1)
    except psycopg2.Error as db_e:
        print(f"Database error during data loading: {db_e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn and not conn.closed: conn.rollback()
        sys.exit(1)

def main():
    """
    Main function to parse arguments, connect to the database,
    and load constituency data from a CSV file.
    """
    parser = argparse.ArgumentParser(description="Load constituency data from a CSV file.")
    parser.add_argument("--csv-file", required=True, help="Path to the constituency data CSV file.")
    args = parser.parse_args()
    
    conn = get_db_connection()
    try:
        if conn:
            success = load_data_from_csv(conn, "constituencies", args.csv_file)
            if not success:
                sys.exit(1)
    except psycopg2.Error as e:
        print(f"A PostgreSQL error occurred: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred in main: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 