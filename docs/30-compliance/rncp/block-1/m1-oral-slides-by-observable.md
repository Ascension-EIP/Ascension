> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Darius (Docs), Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# Bloc 1 — M1 — Guide de slides par observable (O1 -> O11)

---

## Table des matières

- [Mode d’emploi](#mode-demploi)
- [O1 — Analyse des besoins](#o1--analyse-des-besoins)
- [O2 — Besoins PSH intégrés](#o2--besoins-psh-intégrés)
- [O3 — Audit technique/fonctionnel/sécurité](#o3--audit-techniquefonctionnelsécurité)
- [O4 — Méthodologie d’audit](#o4--méthodologie-daudit)
- [O5 — Corpus de spécifications](#o5--corpus-de-spécifications)
- [O6 — Accessibilité dans les spécifications](#o6--accessibilité-dans-les-spécifications)
- [O7 — Accessibilité des documents fournis](#o7--accessibilité-des-documents-fournis)
- [O8 — Analyse financière](#o8--analyse-financière)
- [O9 — Scénarios de chiffrage benchmarkés](#o9--scénarios-de-chiffrage-benchmarkés)
- [O10 — Étude prospective évolution/migration](#o10--étude-prospective-évolutionmigration)
- [O11 — Vulgarisation orale de la prospective](#o11--vulgarisation-orale-de-la-prospective)

---

## Mode d’emploi

Pour chaque observable : 1 slide dédiée, 1 message clé, 1 preuve forte, 1 limite assumée, 1 action de sécurisation.

---

## O1 — Analyse des besoins

- **Titre de slide** : “O1 — Besoin utilisateur consolidé et périmètre fonctionnel”
- **À montrer** : personas + user stories + backlog (`docs/10-product/prototype-pool/workshop/client-needs-and-functional-scope.md`)
- **À dire (notes orales)** : “On a cadré le besoin autour de la progression technique du grimpeur et de la contrainte coût/temps. Le scope MVP est volontairement réduit pour rester livrable.”
- **Question jury probable** : “Comment prouvez-vous que le besoin vient bien des utilisateurs ?”
- **Pattern de réponse solide** : “Méthode -> source -> décision : entretiens/documentation terrain mentionnés dans `context-audit-compliance.md`, puis traduction en user stories priorisées.”

---

## O2 — Besoins PSH intégrés

- **Titre de slide** : “O2 — Inclusion PSH dès la phase besoin”
- **À montrer** : contraintes WCAG + mention PSH dans specs/presentation (`tech-func-specs.md`, `oral_25-02_ppt_content.md`)
- **À dire (notes orales)** : “L’accessibilité est traitée comme un besoin de départ, pas comme une correction finale.”
- **Question jury probable** : “Quel impact concret sur le périmètre ?”
- **Pattern de réponse solide** : “Critère d’acceptation PSH par fonctionnalité critique (auth, upload, restitution) + budget et recette dédiés.”

---

## O3 — Audit technique/fonctionnel/sécurité

- **Titre de slide** : “O3 — État de l’existant : architecture et contrôles”
- **À montrer** : schéma flux Upload -> Queue -> Worker -> DB + extraits `docker-compose.yml`, `apps/server/src/inbound/http.rs`, `apps/ai/src/worker.py`
- **À dire (notes orales)** : “L’audit s’appuie sur du code exécutable et des configurations versionnées, pas uniquement sur des intentions.”
- **Question jury probable** : “Quelle est la preuve que l’async est vraiment implémenté ?”
- **Pattern de réponse solide** : “Endpoint de création d’analyse, publication RabbitMQ durable, consommation worker et mise à jour status/progress en DB.”

---

## O4 — Méthodologie d’audit

- **Titre de slide** : “O4 — Démarche d’investigation utilisée”
- **À montrer** : frise méthode en 4 étapes (doc -> config -> code -> synthèse)
- **À dire (notes orales)** : “On a croisé preuves documentaires et preuves techniques pour éviter un audit théorique.”
- **Question jury probable** : “Quelles limites de votre méthode ?”
- **Pattern de réponse solide** : “On explicite les zones avec preuves fortes et celles à renforcer (ex. verbatim utilisateurs, check-list PSH outillée).”

---

## O5 — Corpus de spécifications

- **Titre de slide** : “O5 — Spécifications fonctionnelles et techniques traçables”
- **À montrer** : lien entre `03-functional-specifications.md`, `04-technical-specifications.md`, API et schéma DB
- **À dire (notes orales)** : “Chaque fonction clé est reliée à un composant technique et à un test d’acceptation.”
- **Question jury probable** : “Comment évitez-vous les specs trop générales ?”
- **Pattern de réponse solide** : “Par exigences testables (endpoint attendu, statut attendu, donnée attendue).”

---

## O6 — Accessibilité dans les spécifications

- **Titre de slide** : “O6 — Exigences PSH intégrées aux critères d’acceptation”
- **À montrer** : tableau “fonctionnalité -> contrainte accessibilité -> preuve attendue”
- **À dire (notes orales)** : “On traduit WCAG en critères vérifiables sur les écrans critiques.”
- **Question jury probable** : “Avez-vous des éléments techniques déjà en place ?”
- **Pattern de réponse solide** : “Oui, base UI existante; mais on assume un renforcement nécessaire via tests lecteurs d’écran et audit contraste.”

---

## O7 — Accessibilité des documents fournis

- **Titre de slide** : “O7 — Dossier et support oral accessibles”
- **À montrer** : check-list document (structure titres, tableaux lisibles, légendes, texte alternatif des visuels)
- **À dire (notes orales)** : “Le fond et la forme du dossier doivent être accessibles, pas seulement l’application.”
- **Question jury probable** : “Que faites-vous sur les supports visuels de soutenance ?”
- **Pattern de réponse solide** : “Slides avec contraste lisible, police suffisante, pas d’information uniquement portée par la couleur, verbalisation systématique des visuels.”

---

## O8 — Analyse financière

- **Titre de slide** : “O8 — Chiffrage CAPEX/OPEX fondé sur l’architecture”
- **À montrer** : synthèse `costs.md` + rappel de l’architecture réellement déployée en dev
- **À dire (notes orales)** : “Le chiffrage suit les composants techniques réels (API, DB, worker, storage, broker).”
- **Question jury probable** : “Pourquoi considérer ces montants comme crédibles ?”
- **Pattern de réponse solide** : “Ce sont des hypothèses explicites issues d’un benchmark, revalidables, et reliées à des briques techniques identifiées.”

---

## O9 — Scénarios de chiffrage benchmarkés

- **Titre de slide** : “O9 — Trois scénarios budgétaires et leurs déclencheurs”
- **À montrer** : tableau MVP/Scale/Scale+ + conditions de passage d’un scénario à l’autre
- **À dire (notes orales)** : “Le budget n’est pas fixe : on pilote par scénarios selon la charge et la qualité de service attendue.”
- **Question jury probable** : “Quel scénario retenez-vous pour démarrer ?”
- **Pattern de réponse solide** : “MVP pour minimiser le risque, avec seuils de bascule définis sur volumétrie et performance.”

---

## O10 — Étude prospective évolution/migration

- **Titre de slide** : “O10 — Trajectoire d’évolution 24–36 mois”
- **À montrer** : roadmap en 3 horizons + registre risques/mitigations (`06-risk-evolution-migration.md`)
- **À dire (notes orales)** : “On anticipe les évolutions sans casser l’existant grâce à des migrations additives et une approche progressive.”
- **Question jury probable** : “Comment sécurisez-vous une migration de schéma ?”
- **Pattern de réponse solide** : “Additive-first, compatibilité API, feature flags, et plan de rollback documenté.”

---

## O11 — Vulgarisation orale de la prospective

- **Titre de slide** : “O11 — Explication simple de la stratégie d’évolution”
- **À montrer** : schéma chaîne opérationnelle + 3 risques majeurs + 3 réponses concrètes
- **À dire (notes orales)** : “On ne promet pas l’absence de risque ; on montre qu’ils sont identifiés, priorisés, et traités.”
- **Question jury probable** : “Si tout tombe, que se passe-t-il ?”
- **Pattern de réponse solide** : “Décrire le mode dégradé, la reprise, puis l’amélioration continue : continuité de service priorisée, perte de données minimisée, retour à la normale piloté.”
