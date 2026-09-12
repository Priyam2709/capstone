"""
test_syntax_and_integrity.py
Automated integrity and syntax checker for all MATLAB (.m) and JSON files in the Capstone project.
"""

import os
import sys
import json
import re

def check_json(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        json.load(f)
    return True

def check_matlab_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.splitlines()
    errors = []

    # Check for basic bracket matching outside comments and strings
    brackets = {'(': ')', '[': ']', '{': '}'}
    stack = []
    
    in_block_comment = False
    for line_num, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith('%{'):
            in_block_comment = True
            continue
        if stripped.startswith('%}'):
            in_block_comment = False
            continue
        if in_block_comment or stripped.startswith('%'):
            continue

        # Strip line comments
        comment_pos = -1
        in_str = False
        quote_char = None
        for idx, ch in enumerate(line):
            if ch in ("'", '"'):
                if not in_str:
                    in_str = True
                    quote_char = ch
                elif quote_char == ch:
                    in_str = False
            elif ch == '%' and not in_str:
                comment_pos = idx
                break
        if comment_pos != -1:
            code_part = line[:comment_pos]
        else:
            code_part = line

        # Scan code part for brackets
        for ch in code_part:
            if ch in brackets:
                stack.append((ch, line_num))
            elif ch in brackets.values():
                if not stack:
                    errors.append(f"Line {line_num}: Unmatched closing bracket '{ch}'")
                else:
                    open_ch, open_line = stack.pop()
                    if brackets[open_ch] != ch:
                        errors.append(f"Line {line_num}: Mismatched bracket '{open_ch}' from line {open_line} closed with '{ch}'")

    if stack:
        for open_ch, open_line in stack:
            errors.append(f"Unclosed opening bracket '{open_ch}' from line {open_line}")

    return errors

def main():
    root = os.path.dirname(os.path.abspath(__file__))
    print(f"Scanning Capstone project at: {root}\n")

    json_files = []
    matlab_files = []

    for dirpath, _, filenames in os.walk(root):
        for f in filenames:
            rel = os.path.relpath(os.path.join(dirpath, f), root)
            if f.endswith('.json'):
                json_files.append(os.path.join(dirpath, f))
            elif f.endswith('.m'):
                matlab_files.append(os.path.join(dirpath, f))

    print(f"Discovered {len(json_files)} JSON configuration files.")
    print(f"Discovered {len(matlab_files)} MATLAB script/class files.\n")

    all_passed = True

    # 1. Check JSON files
    for jf in json_files:
        rel = os.path.relpath(jf, root)
        try:
            check_json(jf)
            print(f"  [PASS] JSON Valid: {rel}")
        except Exception as e:
            print(f"  [FAIL] JSON Invalid: {rel} - {e}")
            all_passed = False

    print("\n--- Checking MATLAB Source Files ---")
    # 2. Check MATLAB files
    for mf in matlab_files:
        rel = os.path.relpath(mf, root)
        errors = check_matlab_file(mf)
        if not errors:
            print(f"  [PASS] MATLAB Syntax OK: {rel}")
        else:
            print(f"  [FAIL] MATLAB Syntax Error in {rel}:")
            for err in errors:
                print(f"         {err}")
            all_passed = False

    print("\n" + ("=" * 50))
    if all_passed:
        print("ALL INTEGRITY & SYNTAX CHECKS PASSED!")
    else:
        print("SOME INTEGRITY CHECKS FAILED.")
        sys.exit(1)

if __name__ == '__main__':
    main()
