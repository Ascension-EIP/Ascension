# @date 2026-09-07
# @file advice.py
# @brief Gemini-based 3D climbing coaching advice generator.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""3D Pose Analysis advice generator via Gemini."""

import json
import logging
from typing import Any

import google.generativeai as genai

logger = logging.getLogger("ai-worker.advice.3d")


def summarize_3d_for_ai(full_data: dict[str, Any], sample_rate: int = 15) -> list[dict[str, Any]]:
    """Sample and reduce 3D biomechanical data for the Gemini prompt."""
    summary = []
    frames = full_data.get("frames", [])

    for i, frame in enumerate(frames):
        people = frame.get("people", [])
        if not people or (i % sample_rate != 0):
            continue

        person = people[0]
        # Landmarks in 3D (x, y, z)
        landmarks_3d = person.get("landmarks", {})
        # Joint angles in 3D space
        angles = person.get("angles", {})
        cam_t = person.get("pred_cam_t", [0, 0, 0])

        summary.append(
            {
                "time": frame.get("timestamp_ms", 0),
                "camera_translation_m": [round(x, 2) for x in cam_t],
                "landmarks_3d_m": {
                    k: {
                        "x": round(v.get("x", 0.0), 2),
                        "y": round(v.get("y", 0.0), 2),
                        "z_depth": round(v.get("z", 0.0), 3),
                    }
                    for k, v in landmarks_3d.items()
                },
                "angles_3d_deg": {k: round(v, 1) for k, v in angles.items()},
            }
        )
    return summary


class Advice3DGenerator:
    """Coaching advice generator tailored to 3D spatial body posture."""

    def __init__(self, api_key: str | None = None, model_name: str = "gemini-3.1-flash-lite"):
        self.api_key = api_key
        self.model_name = model_name

    def generate(self, result_dict: dict[str, Any]) -> str | None:
        """Generate coaching advice taking advantage of 3D depth and spatial angles."""
        if not self.api_key:
            logger.info("No GEMINI_API_KEY provided; skipping 3D advice generation.")
            return None

        try:
            genai.configure(api_key=self.api_key)
        except Exception as e:
            logger.warning("Failed to configure Google Generative AI: %s", e)
            return None

        ai_data = summarize_3d_for_ai(result_dict)
        if not ai_data:
            logger.warning("No valid 3D pose frames available to generate advice.")
            return None

        model = genai.GenerativeModel(self.model_name)
        prompt = (
            "Tu es un coach expert en escalade de haut niveau. Voici les données biomécaniques 3D d'un grimpeur "
            "(positions 3D dans le repère caméra en mètres, angles 3D articulaires, profondeur z_depth).\n"
            f"Données 3D : {json.dumps(ai_data, ensure_ascii=False)}\n\n"
            "Analyse en particulier la proximité du bassin par rapport à la paroi (axe de profondeur Z), "
            "l'engagement du centre de gravité et l'ouverture des hanches.\n"
            "Génère exactement 3 conseils techniques en respectant SCRUPULEUSEMENT le format ci-dessous.\n\n"
            "FORMAT OBLIGATOIRE :\n\n"
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
            "1. Commence DIRECTEMENT par le premier '##'. Zéro phrase d'introduction, zéro résumé.\n"
            "2. Uniquement des listes à puces sous chaque titre.\n"
            "3. Timecodes au format [Xms] (ex: [3200ms]) sans guillemets ni backticks.\n"
            "4. Utilise uniquement les termes anatomiques français.\n"
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
            logger.warning("Gemini 3D advice generation failed: %s", e)
            return None
