#!/usr/bin/env python3
# @date 2026-11-13
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
from concurrent.futures import ThreadPoolExecutor

# Supported file extensions
SUPPORTED_EXTENSIONS = ['.go', '.dart', '.py']

# Patterns for Go and Dart (C-style line comments)
# Matches a contiguous block of comment lines containing at least one header tag
C_LINE_HEADER_RE = re.compile(
    r'^(\s*//\s*@(?:date|file|brief|project|author|copyright|status)\b.*?(?:\n|$)'
    r'(?:\s*//.*?(?:\n|$))*)',
    re.DOTALL
)

# Old C block style for cleanup
C_HEADER_RE = re.compile(r'^\s*/\*\*(.*?)\*/', re.DOTALL)

# Python header style (allowing shebang and coding declaration before header)
PY_HEADER_RE = re.compile(
    r'^(\s*#!.*?\n)?'
    r'(\s*#.*?(?:coding[:=]|encoding[:=]).*?\n)?'
    r'(\s*#\s*@(?:date|file|brief|project|author|copyright|status)\b.*?(?:\n|$)'
    r'(?:\s*#.*?(?:\n|$))*)',
    re.DOTALL
)

# Old pseudo-C style Python header for cleanup
OLD_PY_HEADER_RE = re.compile(
    r'^(\s*#!.*?\n)?'
    r'(\s*#.*?(?:coding[:=]|encoding[:=]).*?\n)?'
    r'(\s*#\s*/\*\*.*?\n'
    r'(?:\s*#\s*\*.*?\n)*'
    r'\s*#\s*\*/\s*\n)',
    re.DOTALL
)

PY_PREFIX_RE = re.compile(
    r'^(\s*#!.*?\n)?(\s*#.*?(?:coding[:=]|encoding[:=]).*?\n)?',
    re.MULTILINE
)

# Lines in git diff hunks that belong to a file header
HEADER_DIFF_LINE_RE = re.compile(
    r'^[+-]\s*(?://|#|\*|/\*|\*/)\s*(?:@(?:date|file|brief|project|author|copyright|status)|\(c\)|\*|/|$)',
    re.IGNORECASE
)

def run_cmd(args, strip=True):
    try:
        res = subprocess.run(args, capture_output=True, text=True, check=True)
        return res.stdout.strip() if strip else res.stdout
    except subprocess.CalledProcessError:
        return None

def get_local_git_user():
    name = run_cmd(['git', 'config', 'user.name'])
    email = run_cmd(['git', 'config', 'user.email'])
    if name and email:
        return f"{name} <{email}>"
    elif name:
        return name
    elif email:
        return email
    return None

def strip_header_c(content):
    match = C_LINE_HEADER_RE.match(content)
    if match:
        return content[match.end():].lstrip('\r\n')
    match_old = C_HEADER_RE.match(content)
    if match_old:
        return content[match_old.end():].lstrip('\r\n')
    return content.lstrip('\r\n')

def strip_header_py(content):
    match = PY_HEADER_RE.match(content)
    if match:
        return content[match.end():].lstrip('\r\n')
    match_old = OLD_PY_HEADER_RE.match(content)
    if match_old:
        return content[match_old.end():].lstrip('\r\n')
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

def parse_header_fields(header_text):
    fields = {}
    current_key = None
    for line in header_text.splitlines():
        line_clean = re.sub(r'^\s*(?://|#|\*)\s*', '', line)
        m = re.match(r'^@(\w+)\s+(.*)$', line_clean)
        if m:
            current_key = m.group(1)
            val = m.group(2).strip()
            if current_key == 'author' and 'author' in fields:
                fields['author'] += ', ' + val
            else:
                fields[current_key] = val
        elif current_key and line_clean.strip():
            fields[current_key] += ' ' + line_clean.strip()
    return fields

def extract_author_key_and_display(author_str):
    author_str = author_str.strip()
    m = re.search(r'<(.*?)>', author_str)
    if m:
        email = m.group(1).strip().lower()
        name = author_str[:m.start()].strip()
        key = email
        display = f"{name} <{email}>" if name else f"<{email}>"
        return key, display
    else:
        key = author_str.lower()
        return key, author_str

def choose_better_display(existing, new_candidate):
    e_name = existing.split('<')[0].strip() if '<' in existing else existing.strip()
    n_name = new_candidate.split('<')[0].strip() if '<' in new_candidate else new_candidate.strip()
    e_words = len(e_name.split())
    n_words = len(n_name.split())
    if n_words > e_words:
        return new_candidate
    if e_words > n_words:
        return existing
    e_has_upper = any(c.isupper() for c in e_name)
    n_has_upper = any(c.isupper() for c in n_name)
    if n_has_upper and not e_has_upper:
        return new_candidate
    if e_has_upper and not n_has_upper:
        return existing
    if len(n_name) > len(e_name):
        return new_candidate
    return existing

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
    else:
        return '\n'.join(f"# {line}" for line in lines) + '\n'

def get_file_metadata(path, ext, style, local_content, existing_fields, local_user):
    is_tracked = run_cmd(['git', 'ls-files', '--error-unmatch', path]) is not None
    if not is_tracked:
        today = datetime.date.today().strftime('%Y-%m-%d')
        ex_author = existing_fields.get('author')
        if ex_author and ex_author.strip() not in ['local', 'unknown', 'modified']:
            authors_dict = {}
            for a in ex_author.split(','):
                a_clean = a.strip()
                if a_clean:
                    k, d = extract_author_key_and_display(a_clean)
                    authors_dict[k] = d
            sorted_authors = sorted(authors_dict.values(), key=lambda a: a.lower())
            return today, ', '.join(sorted_authors)
        return today, local_user or 'local'

    head_content = run_cmd(['git', 'show', f'HEAD:{path}'], strip=False)
    if head_content is None:
        today = datetime.date.today().strftime('%Y-%m-%d')
        ex_author = existing_fields.get('author')
        if ex_author and ex_author.strip() not in ['local', 'unknown', 'modified']:
            authors_dict = {}
            for a in ex_author.split(','):
                a_clean = a.strip()
                if a_clean:
                    k, d = extract_author_key_and_display(a_clean)
                    authors_dict[k] = d
            sorted_authors = sorted(authors_dict.values(), key=lambda a: a.lower())
            return today, ', '.join(sorted_authors)
        return today, local_user or 'local'

    head_content = head_content.replace('\r\n', '\n')
    local_stripped = strip_header(local_content, style).strip()
    head_stripped = strip_header(head_content, style).strip()
    has_local_code_mod = (local_stripped != head_stripped)

    cmd = ['git', 'log', '--no-merges', '--follow', '-p', '-U0', '--format=COMMIT %H %as %an <%ae>', '--', path]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if not proc.stdout:
        today = datetime.date.today().strftime('%Y-%m-%d')
        ex_author = existing_fields.get('author')
        if ex_author and ex_author.strip() not in ['local', 'unknown', 'modified']:
            authors_dict = {}
            for a in ex_author.split(','):
                a_clean = a.strip()
                if a_clean:
                    k, d = extract_author_key_and_display(a_clean)
                    authors_dict[k] = d
            sorted_authors = sorted(authors_dict.values(), key=lambda a: a.lower())
            return today, ', '.join(sorted_authors)
        return today, local_user or 'unknown'

    commits_data = []
    cur_c = None
    cur_h = []
    for line in proc.stdout.splitlines():
        if line.startswith('COMMIT '):
            if cur_c:
                commits_data.append((cur_c, cur_h))
            cur_c = line[7:].strip()
            cur_h = []
        elif cur_c and line.startswith(('+', '-')) and not line.startswith(('+++', '---')):
            cur_h.append(line)
    if cur_c:
        commits_data.append((cur_c, cur_h))

    authors_dict = {}
    latest_code_date = None

    for c_info, hunks in commits_data:
        parts = c_info.split(' ', 2)
        if len(parts) < 3:
            continue
        c_hash, c_date, a_info = parts[0], parts[1], parts[2]
        has_change = any(not HEADER_DIFF_LINE_RE.match(h) for h in hunks)
        if has_change:
            if latest_code_date is None:
                latest_code_date = c_date
            key, display = extract_author_key_and_display(a_info)
            if key not in authors_dict:
                authors_dict[key] = display
            else:
                authors_dict[key] = choose_better_display(authors_dict[key], display)

    if not authors_dict and commits_data:
        for c_info, hunks in commits_data:
            parts = c_info.split(' ', 2)
            if len(parts) >= 3:
                a_info = parts[2]
                key, display = extract_author_key_and_display(a_info)
                if key not in authors_dict:
                    authors_dict[key] = display
                else:
                    authors_dict[key] = choose_better_display(authors_dict[key], display)

    if has_local_code_mod and local_user:
        key, display = extract_author_key_and_display(local_user)
        if key not in authors_dict:
            authors_dict[key] = display
        else:
            authors_dict[key] = choose_better_display(authors_dict[key], display)

    if has_local_code_mod:
        resolved_date = datetime.date.today().strftime('%Y-%m-%d')
    elif latest_code_date:
        resolved_date = latest_code_date
    elif commits_data:
        resolved_date = commits_data[0][0].split(' ')[1]
    else:
        resolved_date = datetime.date.today().strftime('%Y-%m-%d')

    if not authors_dict:
        ex_author = existing_fields.get('author')
        if ex_author and ex_author.strip() not in ['local', 'unknown', 'modified']:
            authors_dict = {}
            for a in ex_author.split(','):
                a_clean = a.strip()
                if a_clean:
                    k, d = extract_author_key_and_display(a_clean)
                    authors_dict[k] = d
            sorted_authors = sorted(authors_dict.values(), key=lambda a: a.lower())
            authors_str = ', '.join(sorted_authors)
        else:
            authors_str = local_user or 'unknown'
    else:
        sorted_authors = sorted(authors_dict.values(), key=lambda a: a.lower())
        authors_str = ', '.join(sorted_authors)

    return resolved_date, authors_str

def get_files_to_process(file_args=None):
    if file_args:
        filtered = []
        for f in file_args:
            if os.path.isfile(f):
                _, ext = os.path.splitext(f)
                if ext in SUPPORTED_EXTENSIONS:
                    filtered.append(f)
        return filtered

    files = set()
    tracked = run_cmd(['git', 'ls-files'])
    if tracked:
        for line in tracked.splitlines():
            f = line.strip()
            if os.path.isfile(f):
                files.add(f)
            
    status = run_cmd(['git', 'status', '--porcelain', '-uall'])
    if status:
        for line in status.splitlines():
            if line.startswith('?? '):
                raw_path = line[3:].strip()
                if raw_path.startswith('"') and raw_path.endswith('"'):
                    raw_path = raw_path[1:-1].encode('utf-8').decode('unicode_escape')
                if os.path.isfile(raw_path):
                    files.add(raw_path)
                
    filtered_files = []
    for f in sorted(files):
        _, ext = os.path.splitext(f)
        if ext in SUPPORTED_EXTENSIONS:
            filtered_files.append(f)
            
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

def prepare_file(path, local_user, copyright_str):
    _, ext = os.path.splitext(path)
    style = 'c' if ext in ['.go', '.dart'] else 'hash'

    try:
        with open(path, 'r', encoding='utf-8', newline='') as f:
            raw_content = f.read()
    except Exception as e:
        return path, False, "", f"Error reading {path}: {e}"

    # Normalize CRLF to LF to prevent false positives across platforms
    content = raw_content.replace('\r\n', '\n')

    existing_fields = {}
    if style == 'c':
        match = C_LINE_HEADER_RE.match(content)
        if match:
            existing_fields = parse_header_fields(match.group(1))
        else:
            match_old = C_HEADER_RE.match(content)
            if match_old:
                existing_fields = parse_header_fields(match_old.group(1))
    else:
        match = PY_HEADER_RE.match(content)
        if match:
            existing_fields = parse_header_fields(match.group(3))
        else:
            match_old = OLD_PY_HEADER_RE.match(content)
            if match_old:
                existing_fields = parse_header_fields(match_old.group(3))

    date_str, author = get_file_metadata(path, ext, style, content, existing_fields, local_user)

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

    needs_update = (content != expected_content)
    return path, needs_update, expected_content, None

def main():
    parser = argparse.ArgumentParser(description="Manage Ascension file headers.")
    parser.add_argument('files', nargs='*', help="Optional specific file(s) to process. Defaults to all repository files.")
    parser.add_argument('--check', action='store_true', help="Check headers without modifying files. Returns non-zero on failure.")
    args = parser.parse_args()

    files = get_files_to_process(args.files)
    if not files:
        if args.files:
            print("No supported files found in specified arguments.")
        else:
            print("No files to process.")
        sys.exit(0)

    current_year = datetime.date.today().year
    copyright_str = f"(c) 2026-{current_year} Ascension" if current_year > 2026 else "(c) 2026 Ascension"
    local_user = get_local_git_user()

    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(prepare_file, path, local_user, copyright_str) for path in files]
        results = [f.result() for f in futures]

    failed = False
    updated_count = 0

    for path, needs_update, expected_content, err_msg in sorted(results, key=lambda x: x[0]):
        if err_msg:
            print(err_msg)
            failed = True
        elif needs_update:
            if args.check:
                print(f"Outdated or missing header in: {path}")
                failed = True
            else:
                try:
                    with open(path, 'w', encoding='utf-8', newline='\n') as f:
                        f.write(expected_content)
                    print(f"Updated header in: {path}")
                    updated_count += 1
                except Exception as e:
                    print(f"Error writing to {path}: {e}")
                    failed = True

    if failed:
        sys.exit(1)

    if not args.check and updated_count > 0:
        print(f"Successfully updated headers in {updated_count} file(s).")
    print("All headers are correct.")

if __name__ == '__main__':
    main()
