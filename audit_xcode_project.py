#!/usr/bin/env python3
"""
Xcode Project Structural Audit Script
Scans for duplicate files and orphan files not in project.pbxproj
"""

import os
import hashlib
from pathlib import Path
from collections import defaultdict
import subprocess

# Project configuration
PROJECT_ROOT = Path("/Users/kai/Building Stuff synced/Build with Claude/EchoCast/EchoNotes")
PROJECT_FILE = PROJECT_ROOT / "EchoNotes.xcodeproj" / "project.pbxproj"

def count_lines(file_path):
    """Count lines in a file"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            return sum(1 for _ in f)
    except:
        return 0

def get_file_hash(file_path):
    """Get MD5 hash of file contents"""
    try:
        with open(file_path, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()
    except:
        return None

def get_file_size(file_path):
    """Get file size in bytes"""
    try:
        return os.path.getsize(file_path)
    except:
        return 0

def scan_swift_files(directory):
    """Recursively scan for all .swift files"""
    swift_files = []
    for root, dirs, files in os.walk(directory):
        # Skip build directories and Xcode project file
        dirs[:] = [d for d in dirs if d not in [
            'DerivedData',
            'build',
            '.git',
            'Pods',
            'EchoNotes.xcodeproj'
        ]]

        for file in files:
            if file.endswith('.swift'):
                full_path = Path(root) / file
                swift_files.append(full_path)

    return swift_files

def find_duplicates(swift_files):
    """Find files with duplicate names"""
    by_name = defaultdict(list)
    for file_path in swift_files:
        by_name[file_path.name].append(file_path)

    duplicates = {name: paths for name, paths in by_name.items() if len(paths) > 1}
    return duplicates

def analyze_duplicate(duplicate_paths):
    """Analyze duplicate files to compare contents"""
    results = []

    for i, path1 in enumerate(duplicate_paths):
        for path2 in duplicate_paths[i+1:]:
            hash1 = get_file_hash(path1)
            hash2 = get_file_hash(path2)

            size1 = get_file_size(path1)
            size2 = get_file_size(path2)

            lines1 = count_lines(path1)
            lines2 = count_lines(path2)

            are_identical = hash1 == hash2 and hash1 is not None

            # Determine which is in a more specific directory
            depth1 = len(path1.parts)
            depth2 = len(path2.parts)

            results.append({
                'path1': str(path1),
                'path2': str(path2),
                'identical': are_identical,
                'size1': size1,
                'size2': size2,
                'lines1': lines1,
                'lines2': lines2,
                'depth1': depth1,
                'depth2': depth2,
            })

    return results

def parse_project_pbxproj(project_file):
    """Parse project.pbxproj to find all file references"""
    if not project_file.exists():
        print(f"ERROR: Project file not found: {project_file}")
        return set()

    try:
        with open(project_file, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        # Find all .swift file references in the project
        import re
        # Pattern matches: path/to/file.swift
        pattern = r'([\w/]+\.swift)'
        matches = re.findall(pattern, content)
        return set(matches)
    except Exception as e:
        print(f"ERROR parsing project.pbxproj: {e}")
        return set()

def find_orphans(swift_files, project_files):
    """Find files that exist on disk but not in project.pbxproj"""
    orphans = []

    for file_path in swift_files:
        # Get the path relative to project root
        try:
            rel_path = file_path.relative_to(PROJECT_ROOT)
            # Convert to forward slashes (Xcode format)
            rel_path_str = str(rel_path).replace('\\', '/')

            # Check if this file is referenced in project
            # The project might reference it with or without "EchoNotes/" prefix
            filename = file_path.name

            # Check various reference patterns
            is_referenced = False
            for ref in project_files:
                if filename in ref or rel_path_str in ref:
                    is_referenced = True
                    break

            if not is_referenced:
                orphans.append({
                    'path': str(file_path),
                    'relative_path': rel_path_str,
                    'filename': filename,
                })
        except Exception as e:
            print(f"WARNING: Could not process {file_path}: {e}")

    return orphans

def print_section(title):
    """Print a section header"""
    print("\n" + "=" * 80)
    print(f" {title}")
    print("=" * 80)

def print_duplicates_report(duplicates, all_analyses):
    """Print detailed duplicates report"""
    print_section("DUPLICATE FILES ANALYSIS")

    if not duplicates:
        print("\n✅ No duplicate filenames found!")
        return

    print(f"\nFound {len(duplicates)} unique filenames with duplicates:\n")

    for filename, paths in sorted(duplicates.items()):
        print(f"\n{'─' * 80}")
        print(f" FILE: {filename}")
        print(f"{'─' * 80}")

        for i, path in enumerate(paths, 1):
            lines = count_lines(path)
            size = get_file_size(path)
            depth = len(path.parts)
            rel_path = path.relative_to(PROJECT_ROOT)

            # Mark which appears to be the "correct" location (deeper = more specific)
            marker = ""
            if depth == max(len(p.parts) for p in paths):
                marker = " ← MOST SPECIFIC (likely correct)"
            elif depth == min(len(p.parts) for p in paths):
                marker = " ← LEAST SPECIFIC (possibly stale)"

            print(f"\n  [{i}] {rel_path}{marker}")
            print(f"      Lines: {lines:,} | Size: {size:,} bytes | Depth: {depth}")

        # Show comparison details
        print(f"\n  CONTENTS COMPARISON:")
        for analysis in all_analyses:
            if filename in str(analysis['path1']):
                identical = "IDENTICAL" if analysis['identical'] else "DIFFERENT"
                print(f"     {identical}")
                if not analysis['identical']:
                    print(f"       File 1: {analysis['lines1']:,} lines, {analysis['size1']:,} bytes")
                    print(f"       File 2: {analysis['lines2']:,} lines, {analysis['size2']:,} bytes")
                break

def print_orphans_report(orphans):
    """Print orphans report"""
    print_section("ORPHAN FILES (not in project.pbxproj)")

    if not orphans:
        print("\n✅ All .swift files appear to be in the project!")
        return

    print(f"\nFound {len(orphans)} files on disk not referenced in project.pbxproj:\n")

    for orphan in orphans:
        lines = count_lines(orphan['path'])
        size = get_file_size(orphan['path'])
        print(f"  • {orphan['relative_path']}")
        print(f"    Lines: {lines:,} | Size: {size:,} bytes")
        print()

def generate_action_plan(duplicates, all_analyses, orphans):
    """Generate recommended action plan"""
    print_section("RECOMMENDED ACTION PLAN")

    if not duplicates and not orphans:
        print("\n✅ No structural issues found! No action needed.")
        return

    actions = []

    # Plan for duplicates
    if duplicates:
        print("\n" + "─" * 80)
        print(" PART 1: DUPLICATE FILES RESOLUTION")
        print("─" * 80)

        for filename, paths in sorted(duplicates.items()):
            # Sort by depth (ascending) - shallower is likely stale
            sorted_paths = sorted(paths, key=lambda p: len(p.parts))
            correct_path = sorted_paths[-1]  # Deepest path
            stale_paths = sorted_paths[:-1]   # All others

            print(f"\n📁 {filename}")
            print(f"   KEEP: {correct_path.relative_to(PROJECT_ROOT)}")

            for stale in stale_paths:
                # Check if contents are identical
                analysis = None
                for a in all_analyses:
                    if stale.name in str(a['path1']):
                        analysis = a
                        break

                if analysis and analysis['identical']:
                    print(f"   DELETE: {stale.relative_to(PROJECT_ROOT)} (identical to kept file)")
                else:
                    print(f"   MERGE then DELETE: {stale.relative_to(PROJECT_ROOT)} (DIFFERENT CONTENTS)")
                    print(f"      → Manually review and merge any unique code")

                actions.append({
                    'type': 'duplicate',
                    'filename': filename,
                    'keep': str(correct_path.relative_to(PROJECT_ROOT)),
                    'remove': str(stale.relative_to(PROJECT_ROOT)),
                    'identical': analysis['identical'] if analysis else False,
                })

    # Plan for orphans
    if orphans:
        print("\n" + "─" * 80)
        print(" PART 2: ORPHAN FILES REGISTRATION")
        print("─" * 80)
        print("\nThese files exist on disk but are not in project.pbxproj:")
        print("Add them to Xcode project via:\n")
        print("1. In Xcode: File → Add Files to 'EchoNotes...'")
        print("2. Navigate to each orphan file")
        print("3. Ensure 'Copy items if needed' is UNCHECKED (file already in place)")
        print("4. Ensure correct target is checked")
        print("5. Click Add\n")

        for orphan in orphans:
            print(f"  • {orphan['relative_path']}")

            actions.append({
                'type': 'orphan',
                'path': str(orphan['relative_path']),
            })

    # Summary
    print("\n" + "─" * 80)
    print(" SUMMARY")
    print("─" * 80)
    print(f"\nTotal Issues Found: {len(duplicates) + len(orphans)}")
    print(f"  • Duplicate filenames: {len(duplicates)}")
    print(f"  • Orphan files: {len(orphans)}")

    identical_count = sum(1 for a in all_analyses if a['identical'])
    different_count = len(all_analyses) - identical_count
    print(f"\nDuplicate Analysis:")
    print(f"  • Identical copies (safe to delete): {identical_count}")
    print(f"  • Different copies (need merge): {different_count}")

    return actions

def main():
    print("=" * 80)
    print(" XCODE PROJECT STRUCTURAL AUDIT")
    print("=" * 80)
    print(f"\nScanning project: {PROJECT_ROOT}")
    print(f"Project file: {PROJECT_FILE}")

    # Step 1: Scan for all .swift files
    print("\n[1/4] Scanning for .swift files...")
    swift_files = scan_swift_files(PROJECT_ROOT)
    print(f"       Found {len(swift_files)} .swift files")

    # Step 2: Find duplicates
    print("\n[2/4] Finding duplicate filenames...")
    duplicates = find_duplicates(swift_files)
    print(f"       Found {len(duplicates)} duplicate filenames")

    # Step 3: Analyze duplicates
    print("\n[3/4] Analyzing duplicate contents...")
    all_analyses = []
    for paths in duplicates.values():
        all_analyses.extend(analyze_duplicate(paths))
    print(f"       Analyzed {len(all_analyses)} file pairs")

    # Step 4: Parse project.pbxproj
    print("\n[4/4] Parsing project.pbxproj for file references...")
    project_files = parse_project_pbxproj(PROJECT_FILE)
    print(f"       Found {len(project_files)} file references")

    # Step 5: Find orphans
    print("\n[*] Finding orphan files...")
    orphans = find_orphans(swift_files, project_files)
    print(f"       Found {len(orphans)} potential orphans")

    # Generate reports
    print("\n" + "=" * 80)
    print(" AUDIT COMPLETE - GENERATING REPORTS")
    print("=" * 80)

    print_duplicates_report(duplicates, all_analyses)
    print_orphans_report(orphans)
    actions = generate_action_plan(duplicates, all_analyses, orphans)

    # Save actions to file for later use
    actions_file = PROJECT_ROOT / "audit_actions.json"
    import json
    with open(actions_file, 'w') as f:
        json.dump(actions, f, indent=2)
    print(f"\n📝 Action plan saved to: {actions_file}")

    print("\n" + "=" * 80)
    print(" AUDIT COMPLETE")
    print("=" * 80)
    print("\n⚠️  NO FILES HAVE BEEN MODIFIED")
    print("    Review the report above before proceeding with any changes.")

if __name__ == "__main__":
    main()
