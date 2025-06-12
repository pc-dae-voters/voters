import psycopg2
import argparse
import sys
import os
import random
from datetime import datetime, timedelta

# --- Database and Setup Functions ---

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

def get_ids_from_table(conn, table_name, column_name="id"):
    ids = []
    try:
        with conn.cursor() as cursor:
            cursor.execute(f"SELECT {column_name} FROM {table_name};")
            results = cursor.fetchall()
            ids = [item[0] for item in results]
            if not ids:
                print(f"Warning: No entries found in '{table_name}' table. Cannot select names for generation.", file=sys.stderr)
    except psycopg2.Error as e:
        print(f"Database error fetching IDs from {table_name}: {e}", file=sys.stderr)
    return ids

def get_first_name_ids_by_gender(conn):
    male_ids = []
    female_ids = []
    neutral_ids = []
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, gender FROM first_names;")
            results = cursor.fetchall()
            for id_val, gender_val in results:
                if gender_val == 'M':
                    male_ids.append(id_val)
                elif gender_val == 'F':
                    female_ids.append(id_val)
                else: # Includes NULL or any other unexpected values
                    neutral_ids.append(id_val)
            
            if not male_ids:
                print("Warning: No male-specific first names found in 'first_names' table.", file=sys.stderr)
            if not female_ids:
                print("Warning: No female-specific first names found in 'first_names' table.", file=sys.stderr)
            if not neutral_ids:
                print("Warning: No neutral/unspecified-gender first names found in 'first_names' table.", file=sys.stderr)
                
    except psycopg2.Error as e:
        print(f"Database error fetching first names by gender: {e}", file=sys.stderr)
        # Depending on desired robustness, could exit here or return empty lists
    return male_ids, female_ids, neutral_ids

def get_all_places_with_country(conn):
    places = []
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, country_id FROM places;")
            places = cursor.fetchall()
            if not places:
                print("Error: No places found in the 'places' table. Cannot generate birth places.", file=sys.stderr)
                sys.exit(1)
    except psycopg2.Error as e:
        print(f"Database error fetching places: {e}", file=sys.stderr)
        sys.exit(1)
    return places

def get_country_id_by_name(conn, country_name="United Kingdom"):
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM countries WHERE name = %s;", (country_name,))
            result = cursor.fetchone()
            if not result:
                print(f"Error: Country '{country_name}' not found in countries table.", file=sys.stderr)
                sys.exit(1)
            return result[0]
    except psycopg2.Error as e:
        print(f"Database error fetching ID for country '{country_name}': {e}", file=sys.stderr)
        sys.exit(1)

# --- Generation Helper Functions ---

def get_random_dob(today):
    """Generates a random date of birth for an age between 0 and 100 years."""
    hundred_years_ago = today - timedelta(days=100 * 365.25)
    total_days_in_100_years = (today - hundred_years_ago).days
    random_days_offset = random.randint(0, total_days_in_100_years -1) 
    return today - timedelta(days=random_days_offset)

def calculate_age(birth_date, today):
    return today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))

# --- Main Generation Logic ---

def main():
    """Main function to load synthetic people."""
    # DB connection details are now sourced from environment variables.
    parser = argparse.ArgumentParser(description="Generate and insert synthetic people data into a PostgreSQL database.")
    parser.add_argument("--num-people", type=int, default=1000, help="Number of people to generate")
    parser.add_argument("--random-seed", type=int, help="Optional random seed for reproducibility")

    args = parser.parse_args()

    if args.random_seed is not None:
        random.seed(args.random_seed)

    conn = get_db_connection()
    today = datetime.now().date()

    try:
        # Load name IDs from database tables
        male_first_name_ids, female_first_name_ids, neutral_first_name_ids = get_first_name_ids_by_gender(conn)
        all_surname_ids = get_ids_from_table(conn, "surnames")

        if not all_surname_ids:
            print("Error: Surnames table is empty or could not be read. Exiting.", file=sys.stderr)
            sys.exit(1)
        
        # Check if we have any first names at all for either gender, considering fallbacks
        can_generate_males = bool(male_first_name_ids or neutral_first_name_ids)
        can_generate_females = bool(female_first_name_ids or neutral_first_name_ids)

        if not (can_generate_males and can_generate_females):
            error_message = "Error: Insufficient first names for generation. "
            if not can_generate_males:
                error_message += "Cannot find male or neutral first names. "
            if not can_generate_females:
                error_message += "Cannot find female or neutral first names. "
            print(error_message + "Exiting.", file=sys.stderr)
            sys.exit(1)
        elif not male_first_name_ids and not female_first_name_ids and not neutral_first_name_ids:
             print("Error: All first name lists (male, female, neutral) are empty. Exiting.", file=sys.stderr)
             sys.exit(1)

        all_places_with_country = get_all_places_with_country(conn)
        uk_country_id = get_country_id_by_name(conn, "United Kingdom")

        print(f"Starting generation of {args.num_people} people using names from database...")
        generated_citizens_dob = [] 

        with conn.cursor() as cursor:
            for i in range(args.num_people):
                gender = random.choice(['M', 'F'])
                first_name_id = None
                
                if gender == 'M':
                    if male_first_name_ids:
                        first_name_id = random.choice(male_first_name_ids)
                    elif neutral_first_name_ids: # Fallback to neutral names if no male names
                        first_name_id = random.choice(neutral_first_name_ids)
                elif gender == 'F':
                    if female_first_name_ids:
                        first_name_id = random.choice(female_first_name_ids)
                    elif neutral_first_name_ids: # Fallback to neutral names if no female names
                        first_name_id = random.choice(neutral_first_name_ids)

                if first_name_id is None:
                    # This should ideally not be reached if initial checks are robust,
                    # but serves as a safeguard.
                    print(f"Critical Error: Could not select a first name for gender '{gender}'. "
                          "This might happen if gender-specific and neutral name lists were initially populated but became exhausted "
                          "or if there's a logic flaw. Exiting.", file=sys.stderr)
                    sys.exit(1)
                    
                surname_id = random.choice(all_surname_ids)
                
                birth_place_id, birth_country_id = random.choice(all_places_with_country)
                dob = get_random_dob(today)
                
                citizen_status = ''
                if birth_country_id == uk_country_id:
                    citizen_status = 'B'
                else:
                    citizen_status = 'N' if random.random() < 0.9 else 'F' 

                cursor.execute(
                    "INSERT INTO citizens (status, died) VALUES (%s, NULL) RETURNING id;",
                    (citizen_status,)
                )
                citizen_id = cursor.fetchone()[0]
                
                cursor.execute(
                    "INSERT INTO births (citizen_id, surname_id, first_name_id, gender, date, place_id, father_id, mother_id) "
                    "VALUES (%s, %s, %s, %s, %s, %s, NULL, NULL);",
                    (citizen_id, surname_id, first_name_id, gender, dob, birth_place_id)
                )
                generated_citizens_dob.append((citizen_id, dob))

                if (i + 1) % 100 == 0:
                    conn.commit()
                    print(f"  Generated and committed {i + 1}/{args.num_people} people.")
            
            conn.commit() 
            print("Finished initial generation of citizens and births.")

            # --- Mortality Pass ---
            print("\nStarting mortality simulation...")
            deaths_applied = 0
            for citizen_id, dob in generated_citizens_dob:
                age = calculate_age(dob, today)
                
                death_chance = 0.0
                if 0 <= age <= 10: death_chance = 0.01
                elif 11 <= age <= 20: death_chance = 0.02
                elif 21 <= age <= 50: death_chance = 0.03
                elif 51 <= age <= 60: death_chance = 0.05
                elif age > 60:
                    death_chance = 0.10 + ( (age - 61) // 2 ) * 0.05
                
                if random.random() < death_chance:
                    if (today - dob).days <=0: 
                        died_date = today
                    else:
                        max_days_after_birth = (today - dob).days
                        random_death_offset = random.randint(0, max_days_after_birth)
                        died_date = dob + timedelta(days=random_death_offset)
                    
                    cursor.execute(
                        "UPDATE citizens SET died = %s WHERE id = %s;",
                        (died_date, citizen_id)
                    )
                    deaths_applied += 1

                if deaths_applied > 0 and deaths_applied % 100 == 0:
                    conn.commit()
                    print(f"  Applied and committed {deaths_applied} deaths so far...")
            
            conn.commit() 
            print(f"Mortality simulation complete. Total deaths applied: {deaths_applied}.")

        print("\nSynthetic data generation completed successfully.")

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

if __name__ == "__main__":
    main() 