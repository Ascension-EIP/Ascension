# @date 2026-11-01
# @file __init__.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
def main() -> None:
    from dotenv import load_dotenv

    load_dotenv()

    from worker.cli import main as cli_main

    cli_main()
