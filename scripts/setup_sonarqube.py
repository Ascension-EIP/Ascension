#!/usr/bin/env python3
# @date 2026-07-16
# @file setup_sonarqube.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import urllib.request
import urllib.parse
import urllib.error
import json
import base64
import time
import os
import sys
import subprocess

def load_env():
    # Try current directory first, then parent of script
    env_paths = ['.env', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')]
    for path in env_paths:
        if os.path.exists(path):
            print(f"Loading environment from {path}")
            with open(path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith('#'):
                        continue
                    parts = line.split('=', 1)
                    if len(parts) == 2:
                        key = parts[0].strip()
                        val = parts[1].strip()
                        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                            val = val[1:-1]
                        if key not in os.environ:
                            os.environ[key] = val
            return path
    return None

def update_env(key, value):
    env_path = '.env'
    if not os.path.exists(env_path):
        env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
    
    if os.path.exists(env_path):
        with open(env_path, 'r') as f:
            lines = f.readlines()
        
        updated = False
        for i, line in enumerate(lines):
            # Split by '=' to match the exact key
            parts = line.split('=', 1)
            if parts[0].strip() == key:
                lines[i] = f"{key}={value}\n"
                updated = True
                break
        
        if not updated:
            lines.append(f"{key}={value}\n")
            
        with open(env_path, 'w') as f:
            f.writelines(lines)
        print(f"Successfully updated {key} in {env_path}")
    else:
        print(f"Warning: Could not find {env_path} to update {key}")

def make_request(url, data=None, auth=None, method='GET'):
    req = urllib.request.Request(url, method=method)
    if data:
        encoded_data = urllib.parse.urlencode(data).encode('utf-8')
        req.data = encoded_data
        req.add_header('Content-Type', 'application/x-www-form-urlencoded')
    if auth:
        raw_auth = f"{auth[0]}:{auth[1]}"
        encoded_auth = base64.b64encode(raw_auth.encode('utf-8')).decode('utf-8')
        req.add_header('Authorization', f"Basic {encoded_auth}")
    try:
        with urllib.request.urlopen(req, timeout=15) as response:
            status = response.status
            body = response.read().decode('utf-8')
            return status, body
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8') if e.fp else ""
        return e.code, body
    except Exception as e:
        return None, str(e)


def make_request_json(url, data=None, auth=None, method='GET'):
    status, body = make_request(url, data, auth, method)
    if status is not None and 200 <= status < 300:
        try:
            return status, json.loads(body)
        except json.JSONDecodeError:
            return status, body
    return status, body

def check_max_map_count():
    if sys.platform.startswith('linux'):
        try:
            with open('/proc/sys/vm/max_map_count', 'r') as f:
                val = int(f.read().strip())
                if val < 262144:
                    print("\n" + "="*80)
                    print(f"WARNING: vm.max_map_count is too low ({val})! Elasticsearch might crash or fail.")
                    print("\nHow to fix:")
                    print("1. For standard Linux (Ubuntu, Debian, Arch):")
                    print("   Run: sudo sysctl -w vm.max_map_count=262144")
                    print("   To persist: add 'vm.max_map_count=262144' to /etc/sysctl.conf")
                    print("\n2. For NixOS (Lou's environment):")
                    print("   Add this setting to your configuration.nix:")
                    print("   boot.kernel.sysctl = { \"vm.max_map_count\" = 262144; };")
                    print("="*80 + "\n")
        except Exception as e:
            pass

def setup_flutter_plugin():
    plugin_name = "sonar-flutter-plugin-0.5.2.jar"
    plugin_url = f"https://github.com/insideapp-oss/sonar-flutter/releases/download/0.5.2/{plugin_name}"
    
    print("Checking if Sonar Flutter plugin is installed in the container...")
    check_cmd = ['docker', 'exec', 'ascension-sonarqube', 'test', '-f', f'/opt/sonarqube/extensions/plugins/{plugin_name}']
    res = subprocess.run(check_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    if res.returncode == 0:
        print("Sonar Flutter plugin is already installed.")
        return False
        
    print("Sonar Flutter plugin is missing. Installing...")
    local_dir = os.path.join('.sonar', 'plugins')
    os.makedirs(local_dir, exist_ok=True)
    local_path = os.path.join(local_dir, plugin_name)
    
    if not os.path.exists(local_path):
        print(f"Downloading {plugin_name}...")
        try:
            urllib.request.urlretrieve(plugin_url, local_path)
            print("Download completed successfully.")
        except Exception as e:
            print(f"Error downloading plugin: {e}")
            return False
            
    try:
        print("Copying plugin to container...")
        subprocess.run(['docker', 'cp', local_path, f'ascension-sonarqube:/opt/sonarqube/extensions/plugins/{plugin_name}'], check=True)
        print("Plugin copied successfully.")
        return True
    except Exception as e:
        print(f"Error copying plugin to container: {e}")
        return False

def main():
    check_max_map_count()
    load_env()
    
    # Create symlink for pubspec.yaml if it doesn't exist (required by sonar-flutter plugin)
    pubspec_root = 'pubspec.yaml'
    pubspec_target = os.path.join('apps', 'mobile', 'pubspec.yaml')
    if not os.path.exists(pubspec_root) and os.path.exists(pubspec_target):
        print(f"Creating symlink {pubspec_root} -> {pubspec_target} for Sonar Flutter plugin...")
        try:
            os.symlink(pubspec_target, pubspec_root)
            print("Symlink created successfully.")
        except Exception as e:
            print(f"Warning: Failed to create symlink: {e}")

    sonar_host = os.environ.get('SONAR_HOST_URL', 'http://localhost:9000').rstrip('/')
    admin_password = os.environ.get('SONAR_ADMIN_PASSWORD', 'AscensionSonarSecret2026!')
    project_key = 'ascension'
    project_name = 'Ascension'
    
    print("--- Starting SonarQube Service via Docker Compose ---")
    try:
        subprocess.run(['docker', 'compose', '--profile', 'sonar', 'up', '-d', 'sonar-db', 'sonarqube'], check=True)
        print("Docker Compose services started.")
    except Exception as e:
        print(f"Error launching docker compose: {e}")
        sys.exit(1)

    plugin_installed = setup_flutter_plugin()
    if plugin_installed:
        print("Restarting SonarQube container to apply the Flutter plugin...")
        try:
            subprocess.run(['docker', 'compose', '--profile', 'sonar', 'restart', 'sonarqube'], check=True)
            print("SonarQube container restarted.")
        except Exception as e:
            print(f"Error restarting sonarqube container: {e}")

    print("\nWaiting for SonarQube to start up...")
    print("Note: This can take 30-60 seconds as SonarQube initializes Elasticsearch and PostgreSQL.")
    
    status_url = f"{sonar_host}/api/system/status"
    is_up = False
    retries = 30
    for i in range(retries):
        # We try both admin/admin and admin/new_password in case it's already configured
        status, body = make_request(status_url, auth=('admin', 'admin'))
        if status is None or status >= 400:
            status, body = make_request(status_url, auth=('admin', admin_password))
            
        if status == 200:
            try:
                data = json.loads(body)
                if data.get('status') == 'UP':
                    print("\nSonarQube is UP and running!")
                    is_up = True
                    break
            except:
                pass
        
        sys.stdout.write(".")
        sys.stdout.flush()
        time.sleep(5)
        
    if not is_up:
        print("\nTimeout: SonarQube did not start or is not accessible.")
        print("Please check container logs: 'docker logs ascension-sonarqube'")
        sys.exit(1)

    # Configure Elasticsearch to disable disk watermarks and unlock read-only indices
    print("\nConfiguring Elasticsearch to disable disk thresholds...")
    try:
        # Disable thresholds
        subprocess.run([
            'docker', 'exec', 'ascension-sonarqube',
            'wget', '-qO-', '--method=PUT',
            '--body-data={"persistent": {"cluster.routing.allocation.disk.threshold_enabled": false}}',
            '--header=Content-Type: application/json',
            'http://localhost:9001/_cluster/settings'
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Lift read-only blocks
        subprocess.run([
            'docker', 'exec', 'ascension-sonarqube',
            'wget', '-qO-', '--method=PUT',
            '--body-data={"index.blocks.read_only_allow_delete": null}',
            '--header=Content-Type: application/json',
            'http://localhost:9001/_all/_settings'
        ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print("Elasticsearch configured successfully and indices unlocked.")
    except Exception as e:
        print(f"Warning: Failed to configure Elasticsearch settings inside container: {e}")

    # 1. Change password if default password is still active
    print("\nChecking admin password configuration...")
    test_url = f"{sonar_host}/api/users/search?q=admin"
    status, _ = make_request(test_url, auth=('admin', admin_password))
    
    if status == 200:
        print("Admin password already configured correctly.")
    else:
        # Try to change it using the default admin:admin
        print("Attempting to change default admin password...")
        change_pw_url = f"{sonar_host}/api/users/change_password"
        params = {
            'login': 'admin',
            'previousPassword': 'admin',
            'password': admin_password
        }
        status, body = make_request(change_pw_url, data=params, auth=('admin', 'admin'), method='POST')
        if status == 204 or status == 200:
            print("Successfully updated admin password to secure configuration.")
        else:
            print(f"Failed to change password (status={status}): {body}")
            print("Proceeding assuming password is already modified or handled.")

    # 2. Check and Create Project
    print(f"\nChecking if project '{project_key}' exists...")
    search_url = f"{sonar_host}/api/projects/search?projects={project_key}"
    status, res = make_request_json(search_url, auth=('admin', admin_password))
    
    project_exists = False
    if status == 200 and isinstance(res, dict):
        components = res.get('components', [])
        if any(c.get('key') == project_key for c in components):
            print(f"Project '{project_key}' already exists.")
            project_exists = True
            
    if not project_exists:
        print(f"Creating project '{project_name}' ({project_key})...")
        create_url = f"{sonar_host}/api/projects/create"
        params = {
            'project': project_key,
            'name': project_name
        }
        status, body = make_request(create_url, data=params, auth=('admin', admin_password), method='POST')
        if status == 200:
            print("Project created successfully.")
        else:
            print(f"Error creating project (status={status}): {body}")

    # 3. Create or Retrieve Scan Token
    print("\nManaging analysis token...")
    token_name = "ascension-scanner-token"
    tokens_url = f"{sonar_host}/api/user_tokens/search"
    status, res = make_request_json(tokens_url, auth=('admin', admin_password))
    
    token_exists = False
    if status == 200 and isinstance(res, dict):
        user_tokens = res.get('userTokens', [])
        if any(t.get('name') == token_name for t in user_tokens):
            print(f"Token '{token_name}' already exists in SonarQube.")
            token_exists = True

    # If the token does not exist, or if SONAR_TOKEN is not in the local .env, generate a new one
    current_token = os.environ.get('SONAR_TOKEN')
    if not token_exists or not current_token:
        print("Generating a new analysis token...")
        
        # If token existed in SQ but we don't have it locally, revoke the old one first to avoid bloat
        if token_exists:
            revoke_url = f"{sonar_host}/api/user_tokens/revoke"
            make_request(revoke_url, data={'name': token_name}, auth=('admin', admin_password), method='POST')
            
        gen_url = f"{sonar_host}/api/user_tokens/generate"
        # Generate user token (global scan token)
        status, res = make_request_json(gen_url, data={'name': token_name}, auth=('admin', admin_password), method='POST')
        
        if status == 200 and isinstance(res, dict) and 'token' in res:
            new_token = res['token']
            print(f"Token generated successfully: {new_token[:4]}...{new_token[-4:]}")
            update_env('SONAR_TOKEN', new_token)
            update_env('SONAR_HOST_URL', sonar_host)
        else:
            print(f"Error generating token (status={status}): {res}")
    else:
        print("Token already exists locally and on the server. Skipping token generation.")

    print("\n--- SonarQube is fully configured and ready! ---")
    print(f"Dashboard: {sonar_host}")
    print("You can run analysis with: moon run :sonar-scan")

if __name__ == '__main__':
    main()
