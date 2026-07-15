#!/usr/bin/env python3
# @date 2026-07-15
# @file manage_headers.py
# @brief Script to parse, check, and update file headers in the Ascension repository.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done

import os
import sys
import re
import subprocess
import datetime
import argparse

# Supported file extensions
SUPPORTED_EXTENSIONS = ['.go', '.dart', '.py']

# Patterns for Go and Dart (C-style line comments)
C_LINE_HEADER_RE = re.compile(
    r'^(\s*//\s*@date.*?\n'
    r'(?:\s*//\s*@(?:date|file|brief|project|author|copyright|status)\s+.*?\n)*)',
    re.DOTALL
)

# Old C block style for cleanup
C_HEADER_RE = re.compile(r'^\s*/\*\*(.*?)\*/', re.DOTALL)

# Clean Python header style
PY_HEADER_RE = re.compile(
    r'^(\s*#!.*?\n)?'
    r'(\s*#\s*-\*-\s*coding:.*?\n)?'
    r'(\s*#\s*@date.*?\n'
    r'(?:\s*#\s*@(?:date|file|brief|project|author|copyright|status)\s+.*?\n)*)',
    re.DOTALL
)

# Old pseudo-C style Python header for cleanup
OLD_PY_HEADER_RE = re.compile(
    r'^(\s*#!.*?\n)?'
    r'(\s*#\s*-\*-\s*coding:.*?\n)?'
    r'(\s*#\s*/\*\*.*?\n'
    r'(?:\s*#\s*\*.*?\n)*'
    r'\s*#\s*\*/\s*\n)',
    re.DOTALL
)

PY_PREFIX_RE = re.compile(
    r'^(\s*#!.*?\n)?(\s*#\s*-\*-\s*coding:.*?\n)?',
    re.DOTALL
)

def run_cmd(args):
    try:
        res = subprocess.run(args, capture_output=True, text=True, check=True)
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return None

def strip_header_c(content):
    # Try new line header style first
    match = C_LINE_HEADER_RE.match(content)
    if match:
        return content[match.end():].lstrip('\r\n')
        
    # Try old block comment style next
    match_old = C_HEADER_RE.match(content)
    if match_old:
        return content[match_old.end():].lstrip('\r\n')
        
    return content.lstrip('\r\n')

def strip_header_py(content):
    # Try new Python header style first
    match = PY_HEADER_RE.match(content)
    if match:
        return content[match.end():].lstrip('\r\n')
        
    # Try old style Python header next
    match_old = OLD_PY_HEADER_RE.match(content)
    if match_old:
        return content[match_old.end():].lstrip('\r\n')
        
    # If no header, strip optional shebang/encoding to get the body
    _, body = split_py_file(content)
    return body.lstrip('\r\n')

def strip_header(content, style):
    if style == 'c':
        return strip_header_c(content)
    elif style == 'hash':
        return strip_header_py(content)
    return content

def split_py_file(content):
    match = PY_PREFIX_RE.match(content)
    if match:
        prefix = match.group(0)
        body = content[match.end():]
        return prefix, body
    return "", content

def parse_header_fields_c(header_text):
    fields = {}
    for line in header_text.splitlines():
        # Remove // or * and leading spaces
        line_clean = re.sub(r'^\s*(?://|\*)\s*', '', line)
        m = re.match(r'^@(\w+)\s+(.*)$', line_clean)
        if m:
            key = m.group(1)
            val = m.group(2).strip()
            fields[key] = val
    return fields

def parse_header_fields_py(header_text):
    fields = {}
    for line in header_text.splitlines():
        # Remove # and any leading spaces or comment/decorations
        line_clean = re.sub(r'^\s*#\s*\*?\s*', '', line)
        m = re.match(r'^@(\w+)\s+(.*)$', line_clean)
        if m:
            key = m.group(1)
            val = m.group(2).strip()
            fields[key] = val
    return fields

def generate_header(fields, style):
    lines = [
        f"@date {fields.get('date', '')}",
        f"@file {fields.get('file', '')}",
        f"@brief {fields.get('brief', '')}",
        f"@project {fields.get('project', '')}",
        f"@author {fields.get('author', '')}",
        f"@copyright {fields.get('copyright', '')}",
        f"@status {fields.get('status', '')}"
    ]
    if style == 'c':
        return '\n'.join(f"// {line}" for line in lines) + '\n'
    else: # Python style
        return '\n'.join(f"# {line}" for line in lines) + '\n'

def get_file_metadata(path, ext, style):
    try:
        with open(path, 'r', encoding='utf-8', newline='') as f:
            local_content = f.read()
    except Exception:
        today = datetime.date.today().strftime('%Y-%m-%d')
        return today, 'local'

    is_tracked = run_cmd(['git', 'ls-files', '--error-unmatch', path]) is not None
    if not is_tracked:
        today = datetime.date.today().strftime('%Y-%m-%d')
        return today, 'local'

    head_content = run_cmd(['git', 'show', f'HEAD:{path}'])
    if head_content is None:
        today = datetime.date.today().strftime('%Y-%m-%d')
        return today, 'modified'

    local_stripped = strip_header(local_content, style).strip()
    head_stripped = strip_header(head_content, style).strip()

    has_local_code_mod = (local_stripped != head_stripped)

    log_output = run_cmd(['git', 'log', '--follow', '--format=%H %as %an <%ae>', '--', path])
    if not log_output:
        today = datetime.date.today().strftime('%Y-%m-%d')
        return today, 'unknown'

    commits = []
    for line in log_output.splitlines():
        parts = line.strip().split(' ', 2)
        if len(parts) == 3:
            commits.append((parts[0], parts[1], parts[2]))

    resolved_date = None
    authors = []
    seen_names = set()
    seen_emails = set()

    for commit_hash, commit_date, author_info in commits:
        parent_hash = f"{commit_hash}~1"
        parent_content = run_cmd(['git', 'show', f'{parent_hash}:{path}'])
        if parent_content is None:
            parent_content = ""

        commit_content = run_cmd(['git', 'show', f'{commit_hash}:{path}'])
        if commit_content is None:
            continue

        commit_stripped = strip_header(commit_content, style).strip()
        parent_stripped = strip_header(parent_content, style).strip()

        if commit_stripped != parent_stripped:
            if resolved_date is None:
                if has_local_code_mod:
                    resolved_date = datetime.date.today().strftime('%Y-%m-%d')
                else:
                    resolved_date = commit_date

            name = author_info.split('<')[0].strip().lower() if '<' in author_info else author_info.strip().lower()
            email = None
            m = re.search(r'<(.*?)>', author_info)
            if m:
                email = m.group(1).strip().lower()

            if name not in seen_names and (not email or email not in seen_emails):
                seen_names.add(name)
                if email:
                    seen_emails.add(email)
                authors.append(author_info)

    authors.reverse()

    if resolved_date is None:
        if has_local_code_mod:
            resolved_date = datetime.date.today().strftime('%Y-%m-%d')
        else:
            resolved_date = commits[-1][1] if commits else datetime.date.today().strftime('%Y-%m-%d')

    authors_str = ", ".join(authors) if authors else ("unknown" if is_tracked else "local")

    return resolved_date, authors_str

def get_files_to_process():
    files = set()
    
    # Get tracked files
    tracked = run_cmd(['git', 'ls-files'])
    if tracked:
        for line in tracked.splitlines():
            files.add(line.strip())
            
    # Get untracked files
    status = run_cmd(['git', 'status', '--porcelain'])
    if status:
        for line in status.splitlines():
            if line.startswith('?? '):
                files.add(line[3:].strip())
                
    # Filter
    filtered_files = []
    for f in sorted(files):
        # Check extension
        _, ext = os.path.splitext(f)
        if ext in SUPPORTED_EXTENSIONS:
            filtered_files.append(f)
            
    # Filter out files ignored by git
    if filtered_files:
        try:
            process = subprocess.Popen(
                ['git', 'check-ignore', '--stdin'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            stdout, _ = process.communicate(input='\n'.join(filtered_files))
            ignored = set(line.strip() for line in stdout.splitlines() if line.strip())
            return [f for f in filtered_files if f not in ignored]
        except Exception:
            return filtered_files
            
    return filtered_files

def main():
    parser = argparse.ArgumentParser(description="Manage Ascension file headers.")
    parser.add_argument('--check', action='store_true', help="Check headers without modifying files. Returns non-zero on failure.")
    args = parser.parse_args()

    files = get_files_to_process()
    failed = False
    
    current_year = datetime.date.today().year
    copyright_str = f"(c) 2026-{current_year} Ascension" if current_year > 2026 else "(c) 2026 Ascension"
    
    for path in files:
        _, ext = os.path.splitext(path)
        style = 'c' if ext in ['.go', '.dart'] else 'hash'
        
        try:
            with open(path, 'r', encoding='utf-8', newline='') as f:
                content = f.read()
        except Exception as e:
            print(f"Error reading {path}: {e}")
            continue

        existing_fields = {}
        if style == 'c':
            match = C_LINE_HEADER_RE.match(content)
            if match:
                existing_fields = parse_header_fields_c(match.group(1))
            else:
                match_old = C_HEADER_RE.match(content)
                if match_old:
                    existing_fields = parse_header_fields_c(match_old.group(1))
        else:
            match = PY_HEADER_RE.match(content)
            if match:
                existing_fields = parse_header_fields_py(match.group(3))
            else:
                match_old = OLD_PY_HEADER_RE.match(content)
                if match_old:
                    existing_fields = parse_header_fields_py(match_old.group(3))

        date_str, author = get_file_metadata(path, ext, style)
        
        # If the file is local (has no git history) but already has a valid author, preserve it
        if author in ["local", "unknown"] and existing_fields.get('author'):
            author = existing_fields.get('author')

        new_fields = {
            'date': date_str,
            'file': os.path.basename(path),
            'brief': existing_fields.get('brief') or "File description.",
            'project': "Ascension",
            'author': author,
            'copyright': copyright_str,
            'status': existing_fields.get('status') or "done"
        }

        expected_header = generate_header(new_fields, style)
        body = strip_header(content, style)

        if style == 'c':
            expected_content = expected_header + body
        else:
            prefix, _ = split_py_file(content)
            expected_content = prefix
            if prefix and not prefix.endswith('\n'):
                expected_content += '\n'
            expected_content += expected_header + body

        if content != expected_content:
            if args.check:
                print(f"Outdated or missing header in: {path}")
                failed = True
            else:
                try:
                    with open(path, 'w', encoding='utf-8', newline='') as f:
                        f.write(expected_content)
                    print(f"Updated header in: {path}")
                except Exception as e:
                    print(f"Error writing to {path}: {e}")
                    failed = True
                    
    if failed:
        sys.exit(1)
    print("All headers are correct.")

if __name__ == '__main__':
    main()
