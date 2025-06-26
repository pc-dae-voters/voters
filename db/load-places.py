import os
import csv
import psycopg2
import argparse
import sys
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

def get_country_id(conn, country_name):
    """Fetches the ID of a given country from the countries table."""
    with conn.cursor() as cursor:
        cursor.execute("SELECT id FROM countries WHERE name = %s;", (country_name,))
        result = cursor.fetchone()
        if result:
            return result[0]
        else:
            raise ValueError(f"Country '{country_name}' not found in countries table.")

def extract_place_name(address):
    """Extract place name from address string (last element after comma)."""
    if not address:
        return None
    
    # Split by comma and get the last element
    parts = address.split(',')
    if len(parts) < 2:
        return None
    
    # Get the last part and strip whitespace
    place_name = parts[-1].strip()
    
    # Remove quotes if present
    if place_name.startswith('"') and place_name.endswith('"'):
        place_name = place_name[1:-1]
    
    return place_name if place_name else None

def process_addresses_folder(conn, addresses_folder_path, table_name):
    """Process all CSV files in the addresses folder to extract place names."""
    insert_sql = f"INSERT INTO {table_name} (name, country_id) VALUES (%s, %s) ON CONFLICT (name, country_id) DO NOTHING;"
    
    # Get United Kingdom country ID
    uk_country_id = get_country_id(conn, "United Kingdom")
    
    # Find all CSV files in the addresses folder
    csv_pattern = os.path.join(addresses_folder_path, "*.csv")
    csv_files = glob.glob(csv_pattern)
    
    if not csv_files:
        print(f"No CSV files found in {addresses_folder_path}")
        return
    
    print(f"Found {len(csv_files)} CSV files to process")
    
    inserted_count = 0
    skipped_count = 0
    error_count = 0
    processed_places = set()  # Track unique places to avoid duplicates
    
    with conn.cursor() as cursor:
        for csv_file in csv_files:
            print(f"Processing {os.path.basename(csv_file)}...")
            
            try:
                with open(csv_file, 'r', encoding='utf-8') as file:
                    reader = csv.DictReader(file)
                    
                    if 'Address' not in reader.fieldnames:
                        print(f"Warning: CSV file {csv_file} does not contain 'Address' column, skipping")
                        continue
                    
                    for row_num, row in enumerate(reader, 1):
                        address = row.get('Address')
                        if not address:
                            continue
                        
                        place_name = extract_place_name(address)
                        if not place_name:
                            continue
                        
                        # Skip if we've already processed this place
                        if place_name in processed_places:
                            continue
                        
                        try:
                            cursor.execute(insert_sql, (place_name, uk_country_id))
                            if cursor.rowcount > 0:
                                inserted_count += 1
                                processed_places.add(place_name)
                            else:
                                skipped_count += 1
                        except psycopg2.Error as e:
                            print(f"Database error inserting place '{place_name}': {e}")
                            error_count += 1
                            continue
                
                conn.commit()
                
            except FileNotFoundError:
                print(f"Error: CSV file not found at {csv_file}")
                error_count += 1
            except Exception as e:
                print(f"Error processing {csv_file}: {e}")
                error_count += 1
                if conn and not conn.closed:
                    conn.rollback()
    
    # Add "not specified" place for United Kingdom
    try:
        with conn.cursor() as cursor:
            cursor.execute(insert_sql, ("not specified", uk_country_id))
            if cursor.rowcount > 0:
                inserted_count += 1
                print("Added 'not specified' place for United Kingdom")
            else:
                print("'not specified' place already exists for United Kingdom")
        conn.commit()
    except psycopg2.Error as e:
        print(f"Error adding 'not specified' place: {e}")
        error_count += 1
    
    print(f"Processing complete. Inserted: {inserted_count}, Skipped (duplicates): {skipped_count}, Errors: {error_count}")

def main():
    """Main function to load places data from addresses folder."""
    parser = argparse.ArgumentParser(description="Load UK places data from addresses CSV files into the database.")
    parser.add_argument('--addresses-folder', required=True, help='Path to the folder containing address CSV files.')
    parser.add_argument('--table', default='places', help='The name of the database table to load data into.')
    args = parser.parse_args()

    # Validate addresses folder path
    if not os.path.isdir(args.addresses_folder):
        print(f"Error: {args.addresses_folder} is not a valid directory")
        sys.exit(1)

    conn = get_db_connection()
    try:
        if conn:
            process_addresses_folder(conn, args.addresses_folder, args.table)
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