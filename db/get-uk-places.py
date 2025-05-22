import csv
import argparse
import sys
import os
import glob

def extract_place_from_address(address_string):
    """Extracts the place name (last part) from a comma-separated address string."""
    if not address_string or not isinstance(address_string, str):
        return None
    parts = [part.strip() for part in address_string.split(',')]
    # Ensure there is a last part and it's not empty, and it's not a postcode (simple check)
    if not parts or not parts[-1] or len(parts[-1]) > 30 or any(char.isdigit() for char in parts[-1]): 
        # Basic postcode check: if it contains digits, it might be a postcode or part of one.
        # This is a heuristic and might need refinement based on actual data patterns.
        # Also added a length check to avoid overly long "place names".
        # Consider if the second to last part is more reliable if the last part is often a postcode.
        if len(parts) > 1 and parts[-2] and len(parts[-2]) < 30 and not any(char.isdigit() for char in parts[-2]):
             # Try second to last if last looks like postcode or is problematic
             # print(f"Using second to last part for: {address_string} -> {parts[-2]}")
             return parts[-2]
        # print(f"Could not reliably extract place from: {address_string}")
        return None
    return parts[-1]

def main():
    parser = argparse.ArgumentParser(description="Extract unique place names from address CSVs and generate a new CSV for UK cities.")
    parser.add_argument("--input-folder", required=True, help="Folder containing address CSV files.")
    parser.add_argument("--output-csv", required=True, help="Path to the output CSV file (e.g., places.csv). This file will be overwritten.")
    parser.add_argument("--address-column", default="Address", help="Name of the column containing the full address string (default: Address). Case-sensitive.")
    parser.add_argument("--file-pattern", default="addresses*.csv", help="Pattern for address CSV files (default: addresses*.csv).")

    args = parser.parse_args()

    if not os.path.isdir(args.input_folder):
        print(f"Error: Input folder '{args.input_folder}' not found or is not a directory.", file=sys.stderr)
        sys.exit(1)

    unique_place_names = set()
    files_processed_count = 0
    rows_processed_count = 0
    extraction_failures = 0

    csv_files = glob.glob(os.path.join(args.input_folder, args.file_pattern))
    if not csv_files:
        print(f"No files found in '{args.input_folder}' matching pattern '{args.file_pattern}'.", file=sys.stderr)
        sys.exit(0)

    print(f"Found {len(csv_files)} files to process in folder '{args.input_folder}' with pattern '{args.file_pattern}'.")

    for csv_file_path in csv_files:
        files_processed_count += 1
        print(f"Processing file: {csv_file_path}...")
        try:
            with open(csv_file_path, 'r', encoding='utf-8-sig') as file: # utf-8-sig for potential BOM
                reader = csv.DictReader(file)
                if args.address_column not in reader.fieldnames:
                    print(f"Warning: Address column '{args.address_column}' not found in {csv_file_path}. Skipping this file. Found headers: {reader.fieldnames}", file=sys.stderr)
                    continue # Skip to next file
                
                for row_num, row in enumerate(reader, 1):
                    rows_processed_count += 1
                    full_address = row.get(args.address_column)
                    place_name = extract_place_from_address(full_address)

                    if place_name:
                        unique_place_names.add(place_name)
                    elif full_address: # Only count as failure if there was an address to parse
                        # print(f"Debug: Failed to extract place from: '{full_address}' in {csv_file_path}, row {row_num}")
                        extraction_failures += 1
                        
        except FileNotFoundError:
            print(f"Error: CSV file disappeared during processing: {csv_file_path}", file=sys.stderr)
        except Exception as e:
            print(f"Error processing file {csv_file_path}: {e}", file=sys.stderr)

    if not unique_place_names:
        print("No unique place names were extracted.", file=sys.stderr)
        # Decide if an empty output file should be created or not
        # Creating an empty one with headers for consistency with load-places.py
        # Or: sys.exit(0)

    print(f"\n--- Extraction Summary ---")
    print(f"Total files processed: {files_processed_count}")
    print(f"Total rows processed: {rows_processed_count}")
    print(f"Unique place names extracted: {len(unique_place_names)}")
    print(f"Rows where place extraction failed (and address was present): {extraction_failures}")

    try:
        with open(args.output_csv, 'w', newline='', encoding='utf-8') as outfile:
            writer = csv.writer(outfile)
            writer.writerow(['city_name', 'country_reference_name'])
            for place in sorted(list(unique_place_names)):
                writer.writerow([place, "United Kingdom"])
        print(f"Successfully wrote {len(unique_place_names)} unique place names to '{args.output_csv}'.")
    except IOError as e:
        print(f"Error writing to output file '{args.output_csv}': {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred during file writing: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main() 