#!/usr/bin/env python3
"""
Remote file information collector for the Voters Manager instance.
This script runs on the remote instance and creates a JSON file with file information.
"""

import os
import json
import sys
import tempfile
from pathlib import Path
from datetime import datetime

def get_file_info(data_dir="/data"):
    """
    Get information about all files in the data directory.
    
    Args:
        data_dir (str): The data directory to scan
        
    Returns:
        dict: Dictionary with file paths as keys and file info as values
    """
    file_info = {}
    
    try:
        data_path = Path(data_dir)
        if not data_path.exists():
            print(f"Error: Data directory {data_dir} does not exist", file=sys.stderr)
            return file_info
            
        if not data_path.is_dir():
            print(f"Error: {data_dir} is not a directory", file=sys.stderr)
            return file_info
            
        # Walk through all files in the data directory
        for root, dirs, files in os.walk(data_path):
            for file in files:
                file_path = Path(root) / file
                try:
                    # Get relative path from data directory
                    rel_path = file_path.relative_to(data_path)
                    
                    # Get file stats
                    stat = file_path.stat()
                    
                    # Store file information
                    file_info[str(rel_path)] = {
                        "size": stat.st_size,
                        "mtime": stat.st_mtime,
                        "mtime_iso": datetime.fromtimestamp(stat.st_mtime).isoformat()
                    }
                    
                except (OSError, ValueError) as e:
                    # Skip files we can't access or process
                    print(f"Warning: Could not process {file_path}: {e}", file=sys.stderr)
                    continue
                    
    except Exception as e:
        print(f"Error scanning directory {data_dir}: {e}", file=sys.stderr)
        return file_info
    
    return file_info

def main():
    """Main function to collect file information and write to JSON file."""
    # Get file information
    file_info = get_file_info()
    
    # Create a temporary file in /tmp
    try:
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', prefix='remote_files_', delete=False, dir='/tmp') as f:
            json.dump(file_info, f, indent=2)
            temp_filename = f.name
        
        # Output the filename to stdout (this is what the upload script will capture)
        print(temp_filename)
        
    except Exception as e:
        print(f"Error creating JSON file: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main() 