#!/usr/bin/env python3
# @date 2026-11-13
# @file stand_up.py
# @brief Script to generate Discord stand-up messages using Git history and Gemini API.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional, Tuple

FRENCH_MONTHS = [
    "janvier", "février", "mars", "avril", "mai", "juin",
    "juillet", "août", "septembre", "octobre", "novembre", "décembre"
]

TEAM_MEMBERS: Dict[str, Dict[str, Any]] = {
    "gianni": {
        "display_name": "Gianni TUERO",
        "first_name": "Gianni",
        "aliases": ["gianni", "gianni tuero", "tuero", "xjundo", "jundo"],
        "git_patterns": [
            "Gianni TUERO",
            "Gianni Tuero",
            "xJundo",
            "gianni.tuero@epitech.eu",
            "146185507+xJundo@users.noreply.github.com",
        ],
    },
    "lou": {
        "display_name": "Lou PELLEGRINO",
        "first_name": "Lou",
        "aliases": ["lou", "lou pellegrino", "pellegrino", "dimitrilapoudre", "dimitri"],
        "git_patterns": [
            "Lou PELLEGRINO",
            "Lou Pellegrino",
            "DimitriLaPoudre",
            "lou.pellegrino@epitech.eu",
            "146720520+DimitriLaPoudre@users.noreply.github.com",
        ],
    },
    "christophe": {
        "display_name": "Christophe VANDEVOIR",
        "first_name": "Christophe",
        "aliases": ["christophe", "christophe vandevoir", "vandevoir", "itskarmaoff", "karma"],
        "git_patterns": [
            "Christophe VANDEVOIR",
            "Christophe Vandevoir",
            "christophe",
            "ItsKarmaOff",
            "christophe.vandevoir@epitech.eu",
            "115950432+ItsKarmaOff@users.noreply.github.com",
        ],
    },
    "olivier": {
        "display_name": "Olivier POUECH",
        "first_name": "Olivier",
        "aliases": ["olivier", "olivier pouech", "pouech", "livoooo", "livoo"],
        "git_patterns": [
            "Olivier POUECH",
            "Olivier Pouech",
            "Livoooo",
            "olivier.pouech@epitech.eu",
            "zarigu92@gmail.com",
        ],
    },
    "nicolas": {
        "display_name": "Nicolas TORO",
        "first_name": "Nicolas",
        "aliases": ["nicolas", "nicolas toro", "toro", "toro-nicolas"],
        "git_patterns": [
            "Nicolas TORO",
            "Nicolas Toro",
            "toro-nicolas",
            "nicolas.toro@epitech.eu",
            "146118419+toro-nicolas@users.noreply.github.com",
        ],
    },
}

def find_team_member(query: Optional[str]) -> Optional[Dict[str, Any]]:
    """Find a team member by nickname, name, alias, email, or git pattern."""
    if not query:
        return None
    query_norm = query.strip().lower()
    for key, member in TEAM_MEMBERS.items():
        if query_norm == key:
            return member
        if any(query_norm == alias.lower() for alias in member["aliases"]):
            return member
        if any(query_norm in pattern.lower() for pattern in member["git_patterns"]):
            return member
    return None


def run_cmd(args: List[str], cwd: Optional[str] = None) -> str:
    """Run a shell command and return its stripped stdout, or empty string on error."""
    try:
        return subprocess.check_output(args, stderr=subprocess.DEVNULL, cwd=cwd).decode("utf-8").strip()
    except Exception:
        return ""

def load_env() -> Optional[str]:
    """Find and load .env file into os.environ if variables are not already present."""
    possible_paths = [
        os.path.join(os.getcwd(), ".env"),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".env"),
    ]
    repo_root = run_cmd(["git", "rev-parse", "--show-toplevel"])
    if repo_root:
        possible_paths.insert(0, os.path.join(repo_root, ".env"))

    for path in possible_paths:
        if os.path.exists(path):
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for line in f:
                        line = line.strip()
                        if not line or line.startswith("#"):
                            continue
                        parts = line.split("=", 1)
                        if len(parts) == 2:
                            key = parts[0].strip()
                            val = parts[1].strip()
                            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                                val = val[1:-1]
                            if key not in os.environ:
                                os.environ[key] = val
                return path
            except Exception as e:
                print(f"Avertissement : Erreur lors de la lecture de {path} : {e}", file=sys.stderr)
    return None

def get_gemini_config() -> Tuple[Optional[str], str]:
    """Retrieve Gemini API key and model from environment or git config."""
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        api_key = run_cmd(["git", "config", "--get", "gemini.api-key"])
        if not api_key:
            api_key = None

    model = os.environ.get("GEMINI_MODEL", "gemini-3.1-flash-lite")
    return api_key, model

def get_git_user() -> Tuple[str, str]:
    """Retrieve the current user's git name and email."""
    name = run_cmd(["git", "config", "user.name"])
    email = run_cmd(["git", "config", "user.email"])
    return name, email

def get_wednesday_date_range(today: Optional[datetime.date] = None) -> Tuple[datetime.date, datetime.date]:
    """
    Calculate date range from the last Wednesday to today.
    If today is Wednesday, it looks from last week's Wednesday (7 days ago) to today.
    """
    if today is None:
        today = datetime.date.today()

    # Monday=0, Tuesday=1, Wednesday=2, Thursday=3, Friday=4, Saturday=5, Sunday=6
    days_back = (today.weekday() - 2) % 7
    if days_back == 0:
        days_back = 7

    start_date = today - datetime.timedelta(days=days_back)
    end_date = today
    return start_date, end_date

def format_french_date(d: datetime.date) -> str:
    """Format a date nicely in French (e.g. '9 septembre 2026')."""
    return f"{d.day} {FRENCH_MONTHS[d.month - 1]} {d.year}"

def get_commits(
    author_patterns: List[str],
    since_date: datetime.date,
    until_date: datetime.date,
    all_branches: bool = True
) -> List[Dict[str, str]]:
    """Retrieve commits matching any of the author patterns and date range."""
    cmd = [
        "git", "log",
        "--no-merges",
        f"--since={since_date.strftime('%Y-%m-%d')} 00:00:00",
        f"--until={until_date.strftime('%Y-%m-%d')} 23:59:59",
    ]
    if all_branches:
        cmd.append("--all")

    unique_patterns = list(dict.fromkeys(p.strip() for p in author_patterns if p and p.strip()))
    for pattern in unique_patterns:
        cmd.extend(["--author", pattern])


    delimiter = "---COMMIT_DELIMITER---"
    cmd.append(f"--pretty=format:{delimiter}%n%h%n%ad%n%an <%ae>%n%s%n%b")

    output = run_cmd(cmd)
    if not output:
        return []

    raw_commits = output.split(delimiter)
    commits = []
    seen_hashes = set()

    for raw in raw_commits:
        raw = raw.strip()
        if not raw:
            continue
        lines = raw.split("\n")
        if len(lines) < 4:
            continue
        commit_hash = lines[0].strip()
        if commit_hash in seen_hashes:
            continue
        seen_hashes.add(commit_hash)

        commit_date = lines[1].strip()
        author = lines[2].strip()
        subject = lines[3].strip()
        body = "\n".join(lines[4:]).strip() if len(lines) > 4 else ""

        commits.append({
            "hash": commit_hash,
            "date": commit_date,
            "author": author,
            "subject": subject,
            "body": body
        })

    return commits

def clean_output(text: str, start_marker: Optional[str] = None) -> str:
    """Clean markdown code block wrappers, preambles, asterisks to dashes, and empty lines after headings."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        text = "\n".join(lines).strip()

    if start_marker:
        idx = text.lower().find(start_marker.lower())
        if idx != -1:
            text = text[idx:].strip()

    # 1. Convert all asterisks bullet points (* ) to dashes (- )
    # 2. Remove any blank line(s) immediately following a heading (**Voici ce que...)
    raw_lines = text.split("\n")
    cleaned_lines = []
    i = 0
    while i < len(raw_lines):
        line = raw_lines[i]

        is_heading = line.strip().startswith("**Voici ce que")

        # Replace asterisks list items with dashes, preserving indent
        m_bullet = re.match(r"^(\s*)\*(\s+.*)$", line)
        if m_bullet:
            indent, rest = m_bullet.groups()
            line = f"{indent}-{rest}"

        cleaned_lines.append(line)

        # Skip any empty line(s) directly below a stand-up section heading
        if is_heading:
            while i + 1 < len(raw_lines) and not raw_lines[i + 1].strip():
                i += 1
        i += 1

    return "\n".join(cleaned_lines).strip()

def call_gemini(
    api_key: str,
    model: str,
    contents: List[Dict[str, Any]],
    system_instruction: Optional[str] = None,
    start_marker: Optional[str] = None
) -> str:
    """Send a request to the Gemini API and clean the response."""
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"

    payload: Dict[str, Any] = {
        "contents": contents,
        "generationConfig": {
            "temperature": 0.3
        }
    }
    if system_instruction:
        payload["systemInstruction"] = {
            "parts": [{"text": system_instruction}]
        }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode("utf-8"))
            candidates = res_data.get("candidates", [])
            if not candidates:
                raise RuntimeError("Aucun candidat retourné par l'API Gemini.")
            content = candidates[0].get("content", {})
            parts = content.get("parts", [])
            if not parts:
                raise RuntimeError("Réponse vide de l'API Gemini.")
            text = parts[0].get("text", "").strip()

            return clean_output(text, start_marker=start_marker)
    except urllib.error.HTTPError as e:
        error_body = ""
        try:
            error_body = e.read().decode("utf-8")
        except Exception:
            pass
        raise RuntimeError(f"Erreur HTTP Gemini {e.code} ({e.reason}) : {error_body}")
    except Exception as e:
        raise RuntimeError(f"Erreur lors de l'appel Gemini : {e}")

def copy_to_clipboard(text: str) -> bool:
    """Try to copy text to system clipboard using available tools."""
    tools = [
        ["xclip", "-selection", "clipboard"],
        ["wl-copy"],
        ["pbcopy"]
    ]
    for tool in tools:
        if shutil.which(tool[0]):
            try:
                proc = subprocess.Popen(tool, stdin=subprocess.PIPE)
                proc.communicate(input=text.encode("utf-8"))
                if proc.returncode == 0:
                    return True
            except Exception:
                continue
    return False

def prompt_multiline(prompt_message: str) -> str:
    """Prompt user for multiline input. User presses Enter on an empty line or enters 'fin' to stop."""
    print(prompt_message)
    print("(Tapez vos lignes. Appuyez sur Entrée sur une ligne vide ou tapez 'fin' pour valider) :")
    lines = []
    while True:
        try:
            line = input("> ")
        except (KeyboardInterrupt, EOFError):
            print("\nSaisie terminée.")
            break
        if line.strip().lower() == "fin" or (not line.strip() and lines):
            break
        if not line.strip() and not lines:
            break
        lines.append(line)
    return "\n".join(lines).strip()

def main():
    parser = argparse.ArgumentParser(
        description="Génère un message de stand-up Discord à partir des commits Git et de Gemini."
    )
    parser.add_argument(
        "-m", "--member", "--user",
        dest="member",
        help="Membre de l'équipe pour lequel générer le stand-up (ex: gianni, xjundo, lou, christophe, olivier, nicolas)"
    )
    parser.add_argument(
        "-c", "--choose",
        action="store_true",
        help="Choisir interactivement le membre de l'équipe dans une liste"
    )
    parser.add_argument(
        "--list-members",
        action="store_true",
        help="Afficher la liste des membres configurés et quitter"
    )
    parser.add_argument(
        "-3", "--third-person",
        action="store_true",
        help="Rédiger le stand-up à la 3ème personne (ex: 'Voici ce que Gianni a fait...') plutôt qu'à la 1ère personne"
    )
    parser.add_argument("--author", help="Nom ou email brut de l'auteur Git (par défaut: profil git local ou membre)")
    parser.add_argument("--since", help="Date de début au format YYYY-MM-DD (par défaut: dernier mercredi)")
    parser.add_argument("--until", help="Date de fin au format YYYY-MM-DD (par défaut: aujourd'hui)")
    parser.add_argument("--days", type=int, help="Nombre de jours en arrière (outrepasse la règle du mercredi)")
    parser.add_argument("--no-all", action="store_true", help="Ne chercher que dans la branche courante plutôt que toutes les branches")
    parser.add_argument("--print-only", action="store_true", help="Ne pas faire d'interaction, générer et afficher directement")
    args = parser.parse_args()

    if args.list_members:
        print("👥 Membres de l'équipe Ascension configurés :")
        for key, m in TEAM_MEMBERS.items():
            aliases_str = ", ".join(m["aliases"])
            print(f"  • {m['display_name']} (clé: {key}) -> alias: {aliases_str}")
        sys.exit(0)

    print("🚀 Initialisation du script stand_up Ascension...")

    # 1. Load environment and verify Gemini API key
    env_file = load_env()
    if env_file:
        print(f"📁 Fichier d'environnement chargé : {env_file}")
    else:
        print("ℹ️ Aucun fichier .env trouvé, recherche dans les variables d'environnement système.")

    api_key, model = get_gemini_config()
    if not api_key:
        print("\n❌ Erreur : Clé GEMINI_API_KEY introuvable !", file=sys.stderr)
        print("Veuillez renseigner GEMINI_API_KEY dans votre fichier .env ou via :", file=sys.stderr)
        print("  export GEMINI_API_KEY='votre_clé_api'", file=sys.stderr)
        print("  git config --global gemini.api-key 'votre_clé_api'", file=sys.stderr)
        sys.exit(1)

    print(f"🤖 Modèle IA utilisé : {model}")

    # 2. Get target member / Git profile
    git_name, git_email = get_git_user()
    current_user_member = find_team_member(git_name) or find_team_member(git_email)

    target_member: Optional[Dict[str, Any]] = None
    target_name: str = ""
    first_name: str = ""
    author_patterns: List[str] = []
    is_for_self = False

    if args.choose:
        print("\n👥 Choisissez un membre de l'équipe :")
        members_list = list(TEAM_MEMBERS.values())
        for idx, m in enumerate(members_list, start=1):
            is_cur = " (vous)" if current_user_member and m["display_name"] == current_user_member["display_name"] else ""
            print(f"  {idx}. {m['display_name']} ({m['aliases'][0]}){is_cur}")
        try:
            choice_str = input(f"Votre choix [1-{len(members_list)}] : ").strip()
            idx = int(choice_str) - 1
            if 0 <= idx < len(members_list):
                target_member = members_list[idx]
            else:
                print("❌ Choix invalide.", file=sys.stderr)
                sys.exit(1)
        except (KeyboardInterrupt, EOFError):
            print("\nAnnulé.")
            sys.exit(0)
        except ValueError:
            print("❌ Valeur numérique attendue.", file=sys.stderr)
            sys.exit(1)

    elif args.member:
        target_member = find_team_member(args.member)
        if not target_member:
            available = ", ".join(TEAM_MEMBERS.keys())
            print(f"❌ Membre inconnu : '{args.member}'", file=sys.stderr)
            print(f"Membres disponibles : {available}", file=sys.stderr)
            print("💡 Utilisez --list-members pour voir les détails ou --author pour un filtre git brut.", file=sys.stderr)
            sys.exit(1)

    elif args.author:
        target_member = find_team_member(args.author)
        if not target_member:
            target_name = args.author
            first_name = args.author.strip().split()[0]
            author_patterns = [args.author]
            print(f"👤 Auteur personnalisé forcé via --author : {args.author}")

    if target_member:
        target_name = target_member["display_name"]
        first_name = target_member["first_name"]
        author_patterns = target_member["git_patterns"]
        is_for_self = bool(current_user_member and target_member["display_name"] == current_user_member["display_name"])
        print(f"👤 Membre de l'équipe sélectionné : {target_name} ({target_member['aliases'][0]})")
    elif not author_patterns:
        # No --member, --choose, or --author specified: default to current local git user
        if current_user_member:
            target_member = current_user_member
            target_name = target_member["display_name"]
            first_name = target_member["first_name"]
            author_patterns = target_member["git_patterns"]
            is_for_self = True
            print(f"👤 Membre de l'équipe détecté (local) : {target_name} <{git_email}>")
        else:
            target_name = git_name
            first_name = git_name.strip().split()[0] if git_name else "Moi"
            author_patterns = [p for p in [git_name, git_email] if p]
            is_for_self = True
            if not author_patterns:
                print("⚠️ Aucun profil Git (user.name / user.email) configuré localement.")
                try:
                    manual_author = input("Veuillez saisir votre nom ou email d'auteur Git : ").strip()
                    if not manual_author:
                        sys.exit(1)
                    target_name = manual_author
                    first_name = manual_author.split()[0]
                    author_patterns = [manual_author]
                except (KeyboardInterrupt, EOFError):
                    print("\nAnnulé.")
                    sys.exit(1)
            else:
                print(f"👤 Profil Git détecté : {git_name} <{git_email}>")

    # Determine grammatical person (1st vs 3rd person)
    if args.third_person:
        is_third_person = True
    elif is_for_self or args.print_only:
        is_third_person = False
    else:
        print(f"\n📝 Vous générez le stand-up pour {target_name}.")
        print("Sous quelle forme souhaitez-vous rédiger le message ?")
        print(f"  1. À la 1ère personne (\"Voici ce que j'ai fait...\", prêt à copier-coller par {first_name})")
        print(f"  2. À la 3ème personne (\"Voici ce que {first_name} a fait...\", idéal pour suivi/synthèse)")
        try:
            style_choice = input("Votre choix [1/2] (défaut: 1) : ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nAnnulé.")
            sys.exit(0)
        is_third_person = (style_choice == "2")

    # 3. Date range determination
    today = datetime.date.today()
    if args.days is not None:
        start_date = today - datetime.timedelta(days=args.days)
        end_date = today
    elif args.since:
        try:
            start_date = datetime.datetime.strptime(args.since, "%Y-%m-%d").date()
        except ValueError:
            print(f"❌ Format de date invalide pour --since ({args.since}), attendu YYYY-MM-DD", file=sys.stderr)
            sys.exit(1)
        end_date = datetime.datetime.strptime(args.until, "%Y-%m-%d").date() if args.until else today
    else:
        start_date, end_date = get_wednesday_date_range(today)

    str_start_fr = format_french_date(start_date)
    str_end_fr = format_french_date(end_date)
    print(f"📅 Période sélectionnée : du {str_start_fr} au {str_end_fr}")

    # Set headers based on grammatical person
    if is_third_person:
        header_past = f"**Voici ce que {first_name} a fait entre le {str_start_fr} et le {str_end_fr} :**"
        header_next = f"**Voici ce que {first_name} va maintenant faire :**"
    else:
        header_past = f"**Voici ce que j'ai fait entre le {str_start_fr} et le {str_end_fr} :**"
        header_next = "**Voici ce que je vais maintenant faire :**"

    # 4. Fetch commits
    print("🔍 Récupération des commits correspondants...")
    commits = get_commits(
        author_patterns=author_patterns,
        since_date=start_date,
        until_date=end_date,
        all_branches=not args.no_all
    )

    commits_text = ""
    if not commits:
        print(f"\n⚠️ Aucun commit trouvé pour {target_name} entre le {str_start_fr} et le {str_end_fr}.")
        print("Que souhaitez-vous faire ?")
        print("  1. Élargir la recherche aux 7 derniers jours")
        print("  2. Saisir manuellement les réalisations" if is_for_self else f"  2. Saisir manuellement les réalisations de {first_name}")
        print("  3. Quitter")
        try:
            choice = input("Votre choix [1/2/3] (défaut: 1) : ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nAnnulé.")
            sys.exit(0)

        if choice == "2":
            prompt_msg = "Saisissez vos réalisations pour la période :" if is_for_self else f"Saisissez les réalisations de {first_name} pour la période :"
            manual_work = prompt_multiline(prompt_msg)
            if not manual_work:
                print("Aucune réalisation saisie. Fin du script.")
                sys.exit(0)
            commits_text = f"Notes manuelles :\n{manual_work}"
        elif choice == "3":
            sys.exit(0)
        else:
            start_date = today - datetime.timedelta(days=7)
            str_start_fr = format_french_date(start_date)
            print(f"🔄 Nouvelle recherche du {str_start_fr} au {str_end_fr}...")
            if is_third_person:
                header_past = f"**Voici ce que {first_name} a fait entre le {str_start_fr} et le {str_end_fr} :**"
            else:
                header_past = f"**Voici ce que j'ai fait entre le {str_start_fr} et le {str_end_fr} :**"

            commits = get_commits(
                author_patterns=author_patterns,
                since_date=start_date,
                until_date=end_date,
                all_branches=not args.no_all
            )
            if not commits:
                print("⚠️ Toujours aucun commit trouvé. Passage en saisie manuelle.")
                prompt_msg = "Saisissez vos réalisations pour la période :" if is_for_self else f"Saisissez les réalisations de {first_name} pour la période :"
                manual_work = prompt_multiline(prompt_msg)
                if not manual_work:
                    print("Aucune réalisation fournie. Fin du script.")
                    sys.exit(0)
                commits_text = f"Notes manuelles :\n{manual_work}"
            else:
                print(f"✅ {len(commits)} commit(s) trouvé(s).")
    else:
        print(f"✅ {len(commits)} commit(s) trouvé(s).")

    if not commits_text and commits:
        formatted_list = []
        for c in commits:
            commit_entry = f"- [{c['hash']}] {c['subject']}"
            if c['body']:
                commit_entry += f"\n  Détails: {c['body']}"
            formatted_list.append(commit_entry)
        commits_text = "\n".join(formatted_list)

    # 5. Generate past section with Gemini
    if is_third_person:
        system_prompt_past = f"""Tu es un assistant chargé de rédiger des messages de stand-up pour une équipe de développeurs sur Discord.
L'ambiance est conviviale, amicale et familière tout en restant professionnelle, claire et axée sur le travail accompli par {first_name}.

Consignes impératives :
1. Titre obligatoire exact dès la première ligne :
{header_past}
2. Ne mets AUCUNE ligne vide entre le titre et le premier élément de la liste à puces.
3. Utilise EXCLUSIVEMENT des tirets '-' pour toutes les listes à puces (JAMAIS d'astérisques '*').
4. Liste à puces concise en français avec des phrases bien rédigées et naturelles à la 3ème personne (ex: "A implémenté...", "A corrigé...", "A mis à jour...").
5. Regroupe intelligemment les commits liés ou techniques pour ne pas faire une simple répétition ligne à ligne des hash git.
6. Mets en avant les composants clés (backend, mobile, base de données, CI, doc...) quand c'est pertinent.
7. Reste factuel basé sur les commits/notes fournis.
8. Ne commence JAMAIS par une salutation, ne mets pas de texte d'introduction ("Voici le résumé...") ni de conclusion. Retourne UNIQUEMENT le texte au format Markdown attendu.
"""
    else:
        system_prompt_past = f"""Tu es un assistant chargé de rédiger des messages de stand-up pour une équipe de développeurs sur Discord.
L'ambiance est conviviale, amicale et familière tout en restant professionnelle, claire et axée sur le travail accompli.

Consignes impératives :
1. Titre obligatoire exact dès la première ligne :
{header_past}
2. Ne mets AUCUNE ligne vide entre le titre et le premier élément de la liste à puces.
3. Utilise EXCLUSIVEMENT des tirets '-' pour toutes les listes à puces (JAMAIS d'astérisques '*').
4. Liste à puces concise en français avec des phrases bien rédigées et naturelles (ex: "J'ai implémenté...", "J'ai corrigé...", "J'ai mis à jour...").
5. Regroupe intelligemment les commits liés ou techniques pour ne pas faire une simple répétition ligne à ligne des hash git.
6. Mets en avant les composants clés (backend, mobile, base de données, CI, doc...) quand c'est pertinent.
7. Reste factuel basé sur les commits/notes fournis.
8. Ne commence JAMAIS par une salutation, ne mets pas de texte d'introduction ("Voici le résumé...") ni de conclusion. Retourne UNIQUEMENT le texte au format Markdown attendu.
"""

    past_conversation: List[Dict[str, Any]] = [
        {
            "role": "user",
            "parts": [
                {
                    "text": f"Voici les commits récents pour la période :\n\n{commits_text}\n\nGénère la section stand-up correspondante."
                }
            ]
        }
    ]

    print("\n🧠 Génération de la première section avec Gemini...")
    try:
        past_section = call_gemini(
            api_key, model, past_conversation, system_prompt_past,
            start_marker="**Voici ce que"
        )
    except Exception as e:
        print(f"❌ {e}", file=sys.stderr)
        sys.exit(1)

    # 6. Interactive review loop for past section
    while True:
        print("\n" + "=" * 60)
        print(past_section)
        print("=" * 60 + "\n")

        if args.print_only:
            break

        try:
            user_feedback = input("Cette description vous convient-elle ? [O/n] (ou écrivez directement vos modifications) : ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nOpération interrompue.")
            sys.exit(0)

        if not user_feedback or user_feedback.lower() in ["o", "oui", "y", "yes"]:
            print("✅ Section validée !")
            break
        elif user_feedback.lower() in ["n", "non"]:
            try:
                modifs = input("Quels changements apporter ? (ex: 'Supprimer la phrase sur...', 'Ajouter...') :\n> ").strip()
            except (KeyboardInterrupt, EOFError):
                print("\nOpération interrompue.")
                sys.exit(0)
            if not modifs:
                print("Aucune consigne donnée, validation de la version actuelle.")
                break
            instruction = modifs
        else:
            instruction = user_feedback

        print("\n🔄 Mise à jour avec Gemini selon vos remarques...")
        past_conversation.append({
            "role": "model",
            "parts": [{"text": past_section}]
        })
        past_conversation.append({
            "role": "user",
            "parts": [{"text": f"Apporte les modifications suivantes au texte précédent en conservant le format exact et sans préambule :\n{instruction}"}]
        })

        try:
            past_section = call_gemini(
                api_key, model, past_conversation, system_prompt_past,
                start_marker="**Voici ce que"
            )
        except Exception as e:
            print(f"❌ {e}", file=sys.stderr)
            print("Conservation de la version précédente.")
            break

    # 7. Next tasks
    next_section = ""
    if not args.print_only:
        if is_for_self:
            print("\n🔮 Que prévoyez-vous de faire maintenant ?")
            next_raw = prompt_multiline("Listez vos prochaines tâches :")
        else:
            print(f"\n🔮 Que prévoit de faire {first_name} maintenant ? (Optionnel)")
            next_raw = prompt_multiline(f"Listez les prochaines tâches de {first_name} (ou Entrée pour ignorer) :")
    else:
        next_raw = ""

    if next_raw:
        if is_third_person:
            system_prompt_next = f"""Tu es un assistant pour un stand-up de dev sur Discord.
À partir des notes brutes fournies concernant les prochaines tâches de {first_name}, génère une section propre au format exact :

{header_next}
- <tâche 1 rédigée clairement à l'infinitif ou phrase active à la 3e personne>
- <tâche 2>

Consignes impératives :
1. Ton professionnel mais détendu/familier, naturel pour un développeur.
2. Ne mets AUCUNE ligne vide entre le titre et la liste de tâches.
3. Utilise EXCLUSIVEMENT des tirets '-' pour toutes les listes à puces (JAMAIS d'astérisques '*').
4. Formule clairement chaque point (ex: "Rajouter...", "Corriger...", "Avancer sur...").
5. Ne mets AUCUN texte d'introduction ni de conclusion, retourne UNIQUEMENT le bloc Markdown débutant par le titre en gras.
"""
        else:
            system_prompt_next = f"""Tu es un assistant pour un stand-up de dev sur Discord.
À partir des notes brutes fournies par l'utilisateur concernant ses prochaines tâches, génère une section propre au format exact :

{header_next}
- <tâche 1 rédigée clairement à l'infinitif ou phrase active>
- <tâche 2>

Consignes impératives :
1. Ton professionnel mais détendu/familier, naturel pour un développeur.
2. Ne mets AUCUNE ligne vide entre le titre et la liste de tâches.
3. Utilise EXCLUSIVEMENT des tirets '-' pour toutes les listes à puces (JAMAIS d'astérisques '*').
4. Formule clairement chaque point (ex: "Rajouter...", "Corriger...", "Avancer sur...").
5. Ne mets AUCUN texte d'introduction ni de conclusion, retourne UNIQUEMENT le bloc Markdown débutant par le titre en gras.
"""
        next_conversation = [
            {
                "role": "user",
                "parts": [{"text": f"Voici les prochaines tâches prévues :\n\n{next_raw}"}]
            }
        ]
        print("\n🧠 Reformulation des prochaines tâches avec Gemini...")
        try:
            next_section = call_gemini(
                api_key, model, next_conversation, system_prompt_next,
                start_marker="**Voici ce que"
            )
        except Exception as e:
            print(f"⚠️ Erreur lors de la mise en forme des prochaines tâches : {e}", file=sys.stderr)
            lines = [line.strip() for line in next_raw.split("\n") if line.strip()]
            next_bullets = "\n".join(f"- {line.lstrip('-* ')}" for line in lines)
            next_section = f"{header_next}\n{next_bullets}"
    else:
        next_section = f"{header_next}\n- Poursuivre les développements en cours"

    # 8. Assemble full message and verify 2000 character limit
    full_message = clean_output(f"{past_section}\n\n{next_section}")

    max_discord_len = 2000
    if len(full_message) > max_discord_len:
        print(f"\n⚠️ Le message dépasse la limite de {max_discord_len} caractères de Discord ({len(full_message)} caractères).")
        print("🧠 Compression intelligente avec Gemini pour préserver toutes les informations essentielles...")

        compress_prompt = f"""Le message de stand-up suivant doit être envoyé sur Discord.
Il dépasse la limite absolue de {max_discord_len} caractères (il fait actuellement {len(full_message)} caractères).

Condense, raccourcis et synthétise le texte pour qu'il fasse STRICTEMENT moins de 1900 caractères tout en évitant toute perte d'information technique importante.
Conserve obligatoirement les deux titres en gras :
{header_past}
et
{header_next}

Consignes impératives :
- Ne saute AUCUNE ligne vide entre un titre et la liste à puces associée.
- Utilise EXCLUSIVEMENT des tirets '-' pour toutes les listes à puces (JAMAIS d'astérisques '*').
- NE METS AUCUN TEXTE D'INTRODUCTION (ne dis pas "Voici la version condensée..."). Commence DIRECTEMENT par le premier titre.

Texte à condenser :
{full_message}
"""
        compress_convo = [{"role": "user", "parts": [{"text": compress_prompt}]}]
        try:
            compressed = call_gemini(
                api_key, model, compress_convo,
                start_marker="**Voici ce que"
            )
            compressed = clean_output(compressed)
            if len(compressed) <= max_discord_len:
                full_message = compressed
                print(f"✅ Message condensé avec succès ({len(full_message)} caractères).")
            else:
                print("⚠️ Le message reste trop long après compression, ajustement strict appliqué.")
                full_message = compressed[:max_discord_len - 3] + "..."
        except Exception as e:
            print(f"⚠️ Échec de la compression automatique : {e}. Tronquage appliqué.")
            full_message = full_message[:max_discord_len - 3] + "..."

    # 9. Output final result & Clipboard
    print("\n" + "╔" + "═" * 68 + "╗")
    print("║" + " " * 22 + "MESSAGE DE STAND-UP FINAL" + " " * 21 + "║")
    print("╚" + "═" * 68 + "╝\n")
    print(full_message)
    print("\n" + "-" * 70)
    print(f"📊 Longueur totale : {len(full_message)} / {max_discord_len} caractères")

    copied = copy_to_clipboard(full_message)
    if copied:
        print("📋 Le message a été copié directement dans votre presse-papier !")
    else:
        print("💡 Vous pouvez copier le message ci-dessus pour le coller dans Discord.")
    print("-" * 70 + "\n")

if __name__ == "__main__":
    main()
