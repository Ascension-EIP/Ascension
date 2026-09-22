---
id: 58c87ea5-d7f8-48f2-b7fc-85501b4444b5
---

:::success
**Version:** 1.1
:::

---

# Déclaration de conformité à l'accessibilité

Ce document explique comment la documentation d'Ascension est structurée pour répondre aux exigences d'accessibilité et rester exploitable lors de sa publication automatique sur **GitHub Wiki** et **Densho**.

---

## Périmètre

Cette déclaration s'applique à la documentation Markdown située sous `docs/` et publiée via le flux de travail de documentation du projet.

Elle couvre :

- les règles de rédaction des sources Markdown,
- la compatibilité des moteurs de rendu pour GitHub Wiki et Densho,
- les contrôles d'accessibilité attendus lors de la rédaction et de la revue.

---

## Contexte de publication

La documentation est rédigée une seule fois puis distribuée vers deux cibles :

- **GitHub Wiki** (pages générées à partir de `docs/`),
- **Densho** (rendu Markdown natif).

Comme ces deux cibles peuvent interpréter le Markdown différemment sur certains cas particuliers, les exigences d'accessibilité sont définies à l'aide de motifs compatibles avec les deux moteurs (niveaux de titres, listes, liens, textes alternatifs et structure en langage clair) qui restent accessibles dans les deux environnements.

---

## Normes de référence

Le processus de documentation s'aligne sur les références suivantes :

- les principes **WCAG 2.1 Niveau AA** (Perceptible, Utilisable, Compréhensible, Robuste),
- les contraintes syntaxiques **CommonMark / GFM** pour un parsing cohérent,
- les conventions Markdown du projet définies dans `docs/developer/guidelines/markdown-guidelines.md`.

Il s'agit d'une déclaration de conformité de la qualité du contenu Markdown ; elle ne remplace pas un audit d'accessibilité juridique externe complet de chaque page rendue en aval.

---

## Règles d'accessibilité appliquées

Le guide du projet impose des règles de rédaction orientées accessibilité, notamment :

- une hiérarchie stricte des titres sans saut de niveau,
- des liens descriptifs (pas de formulation ambiguë du type « cliquer ici »),
- un texte alternatif significatif pour les images informatives,
- aucune utilisation de la couleur seule pour transmettre du sens sans équivalent textuel,
- des lignes d'en-tête explicites dans les tableaux,
- des blocs de code clôturés avec indication du langage,
- une rédaction concise et claire,
- des résumés textuels accompagnant les diagrammes Mermaid.

Ces règles ont été spécifiquement choisies car elles résistent au flux de publication automatisé et restent compréhensibles avec les technologies d'assistance.

---

## Modalités de démonstration de la conformité

La conformité est démontrée à travers un modèle combinant **règles et processus** :

1. Les auteurs suivent le guide Markdown avant de commiter des modifications de documentation.
2. Les revues vérifient les critères d'accessibilité au même titre que la qualité de la documentation.
3. Le rendu est validé à la fois sur GitHub Wiki et sur Densho afin de s'assurer de la lisibilité et de la préservation de la structure.

En pratique, cela prouve que l'accessibilité est intégrée dès le cycle de rédaction plutôt qu'ajoutée a posteriori.

---

## Preuves et gouvernance

Artefacts de preuve principaux :

- `docs/developer/guidelines/markdown-guidelines.md` (règles de rédaction normatives),
- `docs/readme.md` (processus de publication et synchronisation du wiki),
- cette déclaration de conformité en tant que justification explicite de la démarche d'accessibilité.

Principes de gouvernance :

- l'accessibilité est un critère de qualité pour la validation des mises à jour de documentation,
- toute régression d'accessibilité constatée dans la documentation doit être corrigée avant validation finale,
- les nouveaux modèles de documentation doivent obligatoirement respecter ces contraintes d'accessibilité.

---

## Conclusion

La documentation d'Ascension est maintenue avec des règles d'accessibilité explicites, un processus de revue partagé et des conventions Markdown adaptées à la publication multi-cible.

Par conséquent, le corpus documentaire est structuré pour respecter les meilleures pratiques d'accessibilité sur les deux cibles de publication, GitHub Wiki et Densho.
