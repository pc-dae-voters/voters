import psycopg2
import argparse
import sys
import os
import random
import json
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
            cursor.execute("SELECT id, gender FROM first-names;")
            results = cursor.fetchall()
            for id_val, gender_val in results:
                if gender_val == 'M':
                    male_ids.append(id_val)
                elif gender_val == 'F':
                    female_ids.append(id_val)
                else: # Includes NULL or any other unexpected values
                    neutral_ids.append(id_val)
            
            if not male_ids:
                print("Warning: No male-specific first names found in 'first-names' table.", file=sys.stderr)
            if not female_ids:
                print("Warning: No female-specific first names found in 'first-names' table.", file=sys.stderr)
            if not neutral_ids:
                print("Warning: No neutral/unspecified-gender first names found in 'first-names' table.", file=sys.stderr)
                
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

def get_marriage_date(birth_date, today):
    """Calculate a marriage date between ages 18 and 35."""
    age_18 = birth_date + timedelta(days=18 * 365.25)
    age_35 = birth_date + timedelta(days=35 * 365.25)
    
    # Ensure marriage date is not in the future
    max_marriage_date = min(age_35, today)
    min_marriage_date = max(age_18, birth_date + timedelta(days=16 * 365.25))  # At least 16 years old
    
    if min_marriage_date >= max_marriage_date:
        return None  # Too young to marry
    
    # Calculate marriage age distribution
    rand = random.random()
    if rand < 0.25:  # 25% marry before 23
        target_age = random.uniform(18, 23)
    elif rand < 0.75:  # 50% between 23 and 30
        target_age = random.uniform(23, 30)
    else:  # 25% after 30
        target_age = random.uniform(30, 35)
    
    marriage_date = birth_date + timedelta(days=target_age * 365.25)
    
    # Ensure marriage date is within valid range
    if marriage_date < min_marriage_date:
        marriage_date = min_marriage_date
    elif marriage_date > max_marriage_date:
        marriage_date = max_marriage_date
    
    return marriage_date

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

                # Get citizen-status ID for the status
                cursor.execute("SELECT id FROM citizen_status WHERE code = %s;", (citizen_status,))
                status_result = cursor.fetchone()
                if not status_result:
                    print(f"Error: Citizen status '{citizen_status}' not found in citizen-status table.", file=sys.stderr)
                    sys.exit(1)
                status_id = status_result[0]

                cursor.execute(
                    "INSERT INTO citizen (status_id, surname_id, first_name_id, gender) VALUES (%s, %s, %s, %s) RETURNING id;",
                    (status_id, surname_id, first_name_id, gender)
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
                        "UPDATE citizen SET died = %s WHERE id = %s;",
                        (died_date, citizen_id)
                    )
                    deaths_applied += 1

                if deaths_applied > 0 and deaths_applied % 100 == 0:
                    conn.commit()
                    print(f"  Applied and committed {deaths_applied} deaths so far...")
            
            conn.commit() 
            print(f"Mortality simulation complete. Total deaths applied: {deaths_applied}.")

            # --- Marriage Generation ---
            print("\nStarting marriage generation...")
            
            # Get all citizens over 16 who are alive and not married
            cursor.execute("""
                SELECT c.id, c.gender, c.surname_id, b.date as birth_date
                FROM citizen c
                JOIN births b ON c.id = b.citizen_id
                WHERE c.died IS NULL 
                AND EXTRACT(YEAR FROM AGE(CURRENT_DATE, b.date)) >= 16
                AND c.id NOT IN (
                    SELECT DISTINCT partner1_id FROM marriages WHERE divorced_date IS NULL
                    UNION
                    SELECT DISTINCT partner2_id FROM marriages WHERE divorced_date IS NULL
                )
                ORDER BY c.id
            """)
            
            eligible_citizens = cursor.fetchall()
            print(f"Found {len(eligible_citizens)} eligible citizens for marriage.")
            
            marriages_created = 0
            used_citizens = set()
            
            for citizen_id, gender, surname_id, birth_date in eligible_citizens:
                if citizen_id in used_citizens:
                    continue
                
                # Only 90% of eligible citizens get married
                if random.random() > 0.9:
                    continue
                
                # Find potential partners
                potential_partners = []
                for other_id, other_gender, other_surname_id, other_birth_date in eligible_citizens:
                    if other_id == citizen_id or other_id in used_citizens:
                        continue
                    
                    # Calculate age difference
                    age_diff = abs(calculate_age(birth_date, today) - calculate_age(other_birth_date, today))
                    
                    # 98% opposite gender, 2% same gender
                    if random.random() < 0.98:
                        if gender != other_gender and age_diff <= 10:  # Similar age, opposite gender
                            potential_partners.append((other_id, other_gender, other_surname_id, other_birth_date))
                    else:
                        if gender == other_gender and age_diff <= 10:  # Similar age, same gender
                            potential_partners.append((other_id, other_gender, other_surname_id, other_birth_date))
                
                if potential_partners:
                    # Select a partner
                    partner_id, partner_gender, partner_surname_id, partner_birth_date = random.choice(potential_partners)
                    
                    # Calculate marriage date
                    marriage_date = get_marriage_date(birth_date, today)
                    if marriage_date is None:
                        continue
                    
                    # Create marriage record
                    cursor.execute(
                        "INSERT INTO marriages (partner1_id, partner2_id, married_date) VALUES (%s, %s, %s);",
                        (citizen_id, partner_id, marriage_date)
                    )
                    
                    # Handle surname change for woman marrying man
                    if gender == 'M' and partner_gender == 'F':
                        # Get old surname for change record
                        cursor.execute("SELECT surname_id FROM citizen WHERE id = %s;", (partner_id,))
                        old_surname_id = cursor.fetchone()[0]
                        
                        # Update woman's surname to man's surname
                        cursor.execute(
                            "UPDATE citizen SET surname_id = %s WHERE id = %s;",
                            (surname_id, partner_id)
                        )
                        
                        # Create citizen change record
                        change_details = {
                            "change_type": "name_change",
                            "reason": "marriage",
                            "old_values": {
                                "surname_id": old_surname_id
                            },
                            "new_values": {
                                "surname_id": surname_id
                            },
                            "marriage_partner_id": citizen_id,
                            "marriage_date": marriage_date.isoformat()
                        }
                        
                        cursor.execute(
                            "INSERT INTO citizen_changes (citizen_id, change_date, details) VALUES (%s, %s, %s);",
                            (partner_id, marriage_date, json.dumps(change_details))
                        )
                    
                    used_citizens.add(citizen_id)
                    used_citizens.add(partner_id)
                    marriages_created += 1
                    
                    if marriages_created % 50 == 0:
                        conn.commit()
                        print(f"  Created {marriages_created} marriages so far...")
            
            conn.commit()
            print(f"Marriage generation complete. Total marriages created: {marriages_created}.")

            # --- Parent Generation ---
            print("\nStarting parent generation...")
            
            # Get married couples (man and woman only) who can have children
            cursor.execute("""
                SELECT 
                    m.id as marriage_id,
                    m.married_date,
                    c1.id as husband_id, c1.gender as husband_gender, c1.surname_id as husband_surname_id,
                    c2.id as wife_id, c2.gender as wife_gender, c2.surname_id as wife_surname_id,
                    b1.date as husband_birth_date,
                    b2.date as wife_birth_date
                FROM marriages m
                JOIN citizen c1 ON m.partner1_id = c1.id
                JOIN citizen c2 ON m.partner2_id = c2.id
                JOIN births b1 ON c1.id = b1.citizen_id
                JOIN births b2 ON c2.id = b2.citizen_id
                WHERE m.divorced_date IS NULL
                AND c1.gender = 'M' AND c2.gender = 'F'
                AND c1.died IS NULL AND c2.died IS NULL
                AND EXTRACT(YEAR FROM AGE(m.married_date, b2.date)) <= 35
                ORDER BY m.married_date
            """)
            
            married_couples = cursor.fetchall()
            print(f"Found {len(married_couples)} eligible married couples for children.")
            
            children_created = 0
            couples_with_children = 0
            
            for marriage_id, married_date, husband_id, husband_gender, husband_surname_id, wife_id, wife_gender, wife_surname_id, husband_birth_date, wife_birth_date in married_couples:
                # Determine number of children based on distribution
                rand = random.random()
                if rand < 0.20:  # 20% have 1 child
                    num_children = 1
                elif rand < 0.80:  # 60% have 2 children
                    num_children = 2
                else:  # 10% have 3 children
                    num_children = 3
                
                # Calculate wife's age at marriage
                wife_age_at_marriage = calculate_age(wife_birth_date, married_date)
                
                # Generate children
                for child_num in range(num_children):
                    # Calculate child birth date (between marriage and wife turning 35)
                    wife_age_35 = wife_birth_date + timedelta(days=35 * 365.25)
                    max_child_birth = min(wife_age_35, today)
                    
                    if married_date >= max_child_birth:
                        continue  # Wife would be too old
                    
                    # Random birth date between marriage and max_child_birth
                    days_after_marriage = (max_child_birth - married_date).days
                    if days_after_marriage <= 0:
                        continue
                    
                    # Add some randomness to birth spacing (9 months to 3 years between children)
                    min_days_after_marriage = 270 + (child_num * 270)  # 9 months minimum between children
                    if min_days_after_marriage > days_after_marriage:
                        continue
                    
                    random_days = random.randint(min_days_after_marriage, days_after_marriage)
                    child_birth_date = married_date + timedelta(days=random_days)
                    
                    # Generate child details
                    child_gender = random.choice(['M', 'F'])
                    first_name_id = None
                    
                    if child_gender == 'M':
                        if male_first_name_ids:
                            first_name_id = random.choice(male_first_name_ids)
                        elif neutral_first_name_ids:
                            first_name_id = random.choice(neutral_first_name_ids)
                    elif child_gender == 'F':
                        if female_first_name_ids:
                            first_name_id = random.choice(female_first_name_ids)
                        elif neutral_first_name_ids:
                            first_name_id = random.choice(neutral_first_name_ids)
                    
                    if first_name_id is None:
                        continue
                    
                    # Child gets father's surname
                    child_surname_id = husband_surname_id
                    
                    # Get birth place (use same place as father or random place)
                    birth_place_id, birth_country_id = random.choice(all_places_with_country)
                    
                    # Determine child's citizen status
                    if birth_country_id == uk_country_id:
                        child_citizen_status = 'B'
                    else:
                        child_citizen_status = 'N' if random.random() < 0.9 else 'F'
                    
                    # Get citizen-status ID for the child
                    cursor.execute("SELECT id FROM citizen_status WHERE code = %s;", (child_citizen_status,))
                    status_result = cursor.fetchone()
                    if not status_result:
                        continue
                    child_status_id = status_result[0]
                    
                    # Create child citizen record
                    cursor.execute(
                        "INSERT INTO citizen (status_id, surname_id, first_name_id, gender) VALUES (%s, %s, %s, %s) RETURNING id;",
                        (child_status_id, child_surname_id, first_name_id, child_gender)
                    )
                    child_citizen_id = cursor.fetchone()[0]
                    
                    # Create birth record with parent information
                    cursor.execute(
                        "INSERT INTO births (citizen_id, surname_id, first_name_id, gender, date, place_id, father_id, mother_id) "
                        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s);",
                        (child_citizen_id, child_surname_id, first_name_id, child_gender, child_birth_date, birth_place_id, husband_id, wife_id)
                    )
                    
                    children_created += 1
                
                couples_with_children += 1
                
                if couples_with_children % 50 == 0:
                    conn.commit()
                    print(f"  Created {children_created} children for {couples_with_children} couples so far...")
            
            conn.commit()
            print(f"Parent generation complete. Total children created: {children_created} for {couples_with_children} couples.")

            # --- Divorce Generation ---
            print("\nStarting divorce generation...")
            
            # Get all marriages that don't have a divorce date
            cursor.execute("""
                SELECT m.id, m.partner1_id, m.partner2_id, m.married_date, c1.died as partner1_died, c2.died as partner2_died
                FROM marriages m
                JOIN citizen c1 ON m.partner1_id = c1.id
                JOIN citizen c2 ON m.partner2_id = c2.id
                WHERE m.divorced_date IS NULL
                AND c1.died IS NULL AND c2.died IS NULL
                ORDER BY m.married_date
            """)
            
            active_marriages = cursor.fetchall()
            print(f"Found {len(active_marriages)} active marriages for divorce consideration.")
            
            divorces_applied = 0
            
            for marriage_id, partner1_id, partner2_id, married_date, partner1_died, partner2_died in active_marriages:
                # 30% chance of divorce
                if random.random() < 0.3:
                    # Calculate divorce date (between marriage date and today)
                    days_married = (today - married_date).days
                    if days_married <= 0:
                        continue
                    
                    # Random divorce date between marriage and today
                    random_days = random.randint(365, days_married)  # At least 1 year married
                    divorce_date = married_date + timedelta(days=random_days)
                    
                    cursor.execute(
                        "UPDATE marriages SET divorced_date = %s WHERE id = %s;",
                        (divorce_date, marriage_id)
                    )
                    divorces_applied += 1
            
            conn.commit()
            print(f"Divorce generation complete. Total divorces applied: {divorces_applied}.")

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