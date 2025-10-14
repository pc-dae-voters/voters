import os
import psycopg2
import argparse
import sys
import random
from datetime import datetime, timedelta

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

def get_available_addresses(conn):
    """Get all available address IDs."""
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM addresses;")
            results = cursor.fetchall()
            address_ids = [item[0] for item in results]
            if not address_ids:
                print("Error: No addresses found in the addresses table.", file=sys.stderr)
                sys.exit(1)
            return address_ids
    except psycopg2.Error as e:
        print(f"Database error fetching addresses: {e}", file=sys.stderr)
        sys.exit(1)

def get_married_couples(conn):
    """Get currently married couples (not divorced)."""
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT partner1_id, partner2_id
                FROM marriages
                WHERE divorced_date IS NULL
                ORDER BY partner1_id
            """)
            return cursor.fetchall()
    except psycopg2.Error as e:
        print(f"Database error fetching married couples: {e}", file=sys.stderr)
        return []

def create_voters(conn, num_people, random_seed):
    """
    Creates voter records for citizens over 18 years old.
    Returns the total number of errors encountered.
    """
    random.seed(random_seed)
    today = datetime.now().date()

    try:
        # Get available addresses
        address_ids = get_available_addresses(conn)
        print(f"Found {len(address_ids)} available addresses.")

        # Get married couples for address sharing
        married_couples = get_married_couples(conn)
        print(f"Found {len(married_couples)} married couples.")
        
        # Create mapping of married partners
        married_partners = {}
        for partner1_id, partner2_id in married_couples:
            married_partners[partner1_id] = partner2_id
            married_partners[partner2_id] = partner1_id

        # Get citizens over 18 who are alive and not already voters
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT c.id, b.date as birth_date
                FROM citizen c
                JOIN births b ON c.id = b.citizen_id
                WHERE c.died IS NULL
                AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, b.date)) >= 18
                AND c.id NOT IN (SELECT citizen_id FROM voters)
                ORDER BY c.id
            """)
            
            eligible_citizens = cursor.fetchall()
            print(f"Found {len(eligible_citizens)} eligible citizens for voter registration.")

            voters_created = 0
            address_assignments = {}  # Track address assignments for married couples
            error_count = 0

            for citizen_id, birth_date in eligible_citizens:
                try:
                    # Calculate 18th birthday
                    eighteenth_birthday = birth_date + timedelta(days=18 * 365.25)
                    
                    # Determine registration date (18th birthday)
                    registration_date = eighteenth_birthday
                    
                    # 90% chance of being on open register
                    open_register = random.random() < 0.9
                    
                    # Assign address
                    if citizen_id in married_partners:
                        # Married person - check if partner already has an address
                        partner_id = married_partners[citizen_id]
                        if partner_id in address_assignments:
                            # Partner already has an address, use the same one
                            address_id = address_assignments[partner_id]
                        else:
                            # Assign new address and share with partner
                            address_id = random.choice(address_ids)
                            address_assignments[citizen_id] = address_id
                            address_assignments[partner_id] = address_id
                    else:
                        # Single person - assign random address
                        address_id = random.choice(address_ids)
                        address_assignments[citizen_id] = address_id

                    # Create voter record
                    cursor.execute(
                        "INSERT INTO voters (citizen_id, address_id, open_register, registration_date) "
                        "VALUES (%s, %s, %s, %s);",
                        (citizen_id, address_id, open_register, registration_date)
                    )
                    
                    voters_created += 1
                    
                    if voters_created % 100 == 0:
                        conn.commit()
                        print(f"  Created {voters_created} voter records so far...")
                
                except psycopg2.Error as e:
                    print(f"DB Error creating voter for citizen {citizen_id}: {e}", file=sys.stderr)
                    conn.rollback()
                    error_count += 1
                    if error_count > 100:
                        print("Error limit exceeded. Aborting.", file=sys.stderr)
                        sys.exit(1)
                    continue

            conn.commit()
            print(f"Voter registration complete. Total voters created: {voters_created}.")
            if error_count > 0:
                print(f"Completed with {error_count} errors.", file=sys.stderr)
                sys.exit(1)

    except psycopg2.Error as e:
        print(f"A PostgreSQL error occurred: {e}", file=sys.stderr)
        if conn: conn.rollback()
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn: conn.rollback()
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

    print(f"Total voters created: {voters_created}")
    if error_count > 0:
        print(f"Total errors: {error_count}")
    
    if error_count > 100:
        print("Error limit exceeded during voter generation. Aborting.", file=sys.stderr)
    
    return error_count

def main():
    """Main function to load voter data."""
    parser = argparse.ArgumentParser(description="Load voter records for citizens over 18 years old.")
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    args = parser.parse_args()

    try:
        conn = get_db_connection()
        if not conn:
            sys.exit(1)
            
        error_count = create_voters(conn, num_people, random_seed)
        
        if error_count > 100:
            print("Voter generation aborted due to excessive errors.", file=sys.stderr)
            sys.exit(1)

    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        if conn: conn.rollback()
        sys.exit(1)
    finally:
        if conn and not conn.closed:
            conn.close()

if __name__ == "__main__":
    main() 