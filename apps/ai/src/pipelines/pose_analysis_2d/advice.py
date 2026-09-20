# @date 2026-09-05
# @file advice.py
# @brief Gemini-based climbing coaching advice generator for 2D pose analysis.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""2D Pose Analysis advice generator via Gemini."""

import json
import logging
from typing import Any

import google.generativeai as genai

from src.pipelines.pose_analysis_2d.constants import ANGLE_HUMAN_NAMES, LM_HUMAN_NAMES

logger = logging.getLogger("ai-worker.advice.2d")


def summarize_for_ai(full_data: dict[str, Any], sample_rate: int = 15) -> list[dict[str, Any]]:
    """Sample and reduce 2D biomechanical data for the Gemini prompt."""
    summary = []
    valid_frames = [f for f in full_data.get("frames", []) if f.get("pose_detected")]

    for i, frame in enumerate(valid_frames):
        if i % sample_rate == 0:
            reduced_lms = {
                LM_HUMAN_NAMES.get(k, k): {
                    "x": round(v["x"], 3),
                    "y": round(v["y"], 3),
                }
                for k, v in frame.get("landmarks", {}).items()
                if k in LM_HUMAN_NAMES
            }
            named_angles = {
                ANGLE_HUMAN_NAMES.get(k, k): round(v, 1)
                for k, v in frame.get("angles", {}).items()
                if k in ANGLE_HUMAN_NAMES
            }
            summary.append(
                {
                    "time": frame.get("timestamp_ms", 0),
                    "points": reduced_lms,
                    "angles": named_angles,
                }
            )
    return summary


class Advice2DGenerator:
    """Coaching advice generator tailored to 2D skeleton movements."""

    def __init__(self, api_key: str | None = None, model_name: str = "gemini-3.1-flash-lite"):
        self.api_key = api_key
        self.model_name = model_name

    def generate(self, result_dict: dict[str, Any]) -> str | None:
        """Generate coaching advice from 2D pose analysis result."""
        if not self.api_key:
            logger.info("No GEMINI_API_KEY provided; skipping 2D advice generation.")
            return None

        try:
            genai.configure(api_key=self.api_key)
        except Exception as e:
            logger.warning("Failed to configure Google Generative AI: %s", e)
            return None

        ai_data = summarize_for_ai(result_dict)
        if not ai_data:
            logger.warning("No valid pose frames available to generate advice.")
            return None

        model = genai.GenerativeModel(self.model_name)
        prompt = (
            "Tu es un coach expert en escalade. Voici les données de mouvement 2D (timestamps en ms) d'un grimpeur.\n"
            f"Données : {json.dumps(ai_data, ensure_ascii=False)}\n\n"
            "Génère exactement 3 conseils en respectant SCRUPULEUSEMENT le format ci-dessous.\n\n"
            "FORMAT OBLIGATOIRE (reproduis exactement cette structure, remplace uniquement les parties entre < >) :\n\n"
            "## <Titre court du conseil 1>\n"
            "- <Point actionnable 1>\n"
            "- <Point actionnable 2>\n"
            "- <Point actionnable 3 avec timecode : À [Xms], tu peux constater...>\n\n"
            "## <Titre court du conseil 2>\n"
            "- <Point actionnable 1>\n"
            "- <Point actionnable 2>\n"
            "- <Point actionnable 3 avec timecode : À [Xms], tu peux constater...>\n\n"
            "## <Titre court du conseil 3>\n"
            "- <Point actionnable 1>\n"
            "- <Point actionnable 2>\n"
            "- <Point actionnable 3 avec timecode : À [Xms], tu peux constater...>\n\n"
            "RÈGLES ABSOLUES :\n"
            "1. Commence DIRECTEMENT par le premier '##'. Zéro phrase d'introduction, zéro résumé, zéro observation générale.\n"
            "2. Uniquement des listes à puces sous chaque titre. Pas de paragraphes, pas de texte libre.\n"
            "3. Les timecodes s'écrivent [Xms] (ex: [3200ms]) ou [XmYs] (ex: [1m23s]). "
            "JAMAIS entre backticks, JAMAIS entre guillemets. Ils doivent apparaître directement dans le texte d'une puce.\n"
            "4. Utilise uniquement les noms anatomiques français (épaule, coude, poignet, hanche, genou, cheville). "
            "N'utilise jamais de numéros d'indices.\n"
            "5. Réponds uniquement en français.\n"
        )

        try:
            response = model.generate_content(prompt)
            raw_text = response.text.strip() if response.text else ""
            if (
                raw_text
                and raw_text.lower() != "no hints available"
                and not raw_text.startswith("Clé API absente")
                and not raw_text.startswith("Erreur Gemini")
            ):
                return raw_text
            return None
        except Exception as e:
            logger.warning("Gemini advice generation failed: %s", e)
            return None
