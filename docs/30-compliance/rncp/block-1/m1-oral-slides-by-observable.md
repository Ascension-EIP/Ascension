> **Last updated:** 18th March 2026
> **Version:** 1.1
> **Authors:** Darius (Docs), Nicolas TORO
> **Status:** Done
> {.is-success}

---

# Bloc 1 — M1 — Guide de slides par observable (O1 -> O11)

---

## Table des matières

- [Positionnement (réponse rapide à la question)](#positionnement-réponse-rapide-à-la-question)
- [Mode opératoire PPT (captures documentaires)](#mode-opératoire-ppt-captures-documentaires)
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

## Positionnement (réponse rapide à la question)

Oui, la matrice `m1-observables-evidence-matrix.md` est bien sur des justifications par observable RNCP (O1 -> O11), avec rattachement aux compétences C1 -> C5.

Mais ce n'est pas encore un support oral "prêt slide" en l'état:

- la matrice décrit surtout **preuves existantes + manques + niveau de risque**,
- le guide ci-dessous transforme cela en **1 slide exploitable par observable**,
- chaque slide pointe vers **un écran documentaire concret** à montrer dans le PPT.

---

## Mode opératoire PPT (captures documentaires)

Pour chaque observable, faire 1 capture principale dans les docs RNCP Block 1:

- `01-needs-analysis.md` (O1, O2)
- `02-current-state-audit.md` (O3, O4, O7 partiel)
- `03-functional-specifications.md` (O5, O6)
- `04-technical-specifications.md` (O5, O6, O7 partiel)
- `05-benchmark-budget-scenarios.md` (O8, O9)
- `06-risk-evolution-migration.md` (O10, O11)

Capture recommandée:

1. Titre de section visible.
2. Tableau de preuve visible (traçabilité, critères, risques, scénarios, etc.).
3. Source de fichier visible dans l'éditeur.

---

## Mode d’emploi

Pour chaque observable:

- 1 slide dédiée,
- 1 message clé,
- 1 capture principale de doc,
- 1 limite assumée,
- 1 action de sécurisation,
- 1 réponse courte à une question jury probable.

Style recommandé à l'oral:

- phrases courtes,
- vocabulaire simple,
- une idée forte par slide,
- on assume ce qui manque au lieu de le cacher.

---

## O1 — Analyse des besoins

- **Compétence RNCP liée**: C1
- **Titre de slide**: "O1 — Besoin utilisateur consolidé"
- **Capture principale**: `docs/30-compliance/rncp/block-1/01-needs-analysis.md` (sections "Parties prenantes et besoins exprimés" + "Périmètre fonctionnel consolidé")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/client-needs-and-functional-scope.md` (personas + user stories + MoSCoW)
> Justification
> L'idée ici, c'est vraiment de prouver qu'on n'a pas foncé tête baissée dans la tech. On a pris le temps de confronter nos idées à de vrais profils. Cette slide montre au jury qu'on a fait des choix d'inclusion et de périmètre de manière très pragmatique, pour arriver à un MVP qui a du sens.

> Script oral (45-60 s)
> "Alors, sur cette slide, on voit comment tout a commencé. Avant même de coder quoi que ce soit, on s'est posé la question : de quoi ont vraiment besoin nos utilisateurs ? On a analysé leurs frustrations au quotidien et on a traduit tout ça en fonctionnalités concrètes. Surtout, on n'a pas essayé de tout faire d'un coup. On a priorisé nos idées pour s'assurer de sortir un produit viable et réaliste. Bref, on a toujours mis l'humain avant la technique."
- **Limite assumée**: verbatim d'entretiens non centralisés dans une annexe unique.
- **Action de sécurisation**: ajouter une annexe courte "source terrain -> décision backlog".
- **Question jury probable**: "Comment prouver que le besoin vient des utilisateurs?"
- **Réponse simple**: "On a d'abord cadré les profils et leurs besoins, puis on les a transformés en user stories priorisées."

---

## O2 — Besoins PSH intégrés

- **Compétence RNCP liée**: C1
- **Titre de slide**: "O2 — PSH intégré dès l'analyse du besoin"
- **Capture principale**: `docs/30-compliance/rncp/block-1/01-needs-analysis.md` (section "Exigences accessibilité (PSH)")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/tech-func-specs.md` (section "4.5 Accessibility (WCAG 2.1 AA)")
> Justification
> Le but de ce passage est de marquer des points sur notre vision de l'accessibilité. On veut montrer au jury qu'on ne l'a pas vue comme une corvée de fin de projet, mais bien comme un socle dès la conception. C'est une démarche par design, un choix de produit dès le premier jour.

> Script oral (45-60 s)
> "Ce que j'aimerais mettre en avant ici, c'est notre approche sur l'accessibilité. Pour nous, il était hors de question de développer notre outil pour ensuite 'rajouter' une couche d'accessibilité à la va-vite. On l'a intégrée dès l'analyse du besoin, au même titre qu'une fonctionnalité clé. Du coup, les contrastes, la navigation au lecteur d'écran... tout ça a d'emblée influencé la taille de notre périmètre. On assume de faire peut-être un peu moins, mais de le faire pour tout le monde."
- **Limite assumée**: matrice PSH testable écran par écran pas encore formalisée dans un document dédié.
- **Action de sécurisation**: créer une check-list O2/O6 par écran (auth, upload, résultats).
- **Question jury probable**: "Quel impact réel sur le scope?"
- **Réponse simple**: "Ça change le scope tout de suite: contrastes, libellés, alternatives textuelles et tests lecteur d'écran."

---

## O3 — Audit technique/fonctionnel/sécurité

- **Compétence RNCP liée**: C2
- **Titre de slide**: "O3 — Audit de l'existant prouvé par artefacts"
- **Capture principale**: `docs/30-compliance/rncp/block-1/02-current-state-audit.md` (sections "Audit technique", "Audit fonctionnel", "Audit sécurité")
- **Capture de renfort**: `docker-compose.yml` + `apps/server/src/inbound/http.rs` + `apps/ai/src/worker.py`
> Justification
> Pour l'audit, il faut sortir de la théorie. Le jury entend souvent des discours abstraits sur l'architecture. Ici, on leur met sous les yeux du concret : des vrais bouts de code et de configuration qui prouvent que ce qu'on raconte (comme l'asynchronisme de l'IA) tourne vraiment en machine.

> Script oral (45-60 s)
> "Pour cet audit de l'existant, on a voulu confronter nos schémas à la réalité du terrain. Ce que vous voyez là, ce sont des vrais extraits de notre projet : du docker-compose, un bout d'API, et notre worker IA. Pourquoi je vous montre ça ? Tout simplement pour prouver que notre fameuse boucle asynchrone – je lance une analyse, elle part en file d'attente, l'IA la traite et on met la base à jour – eh bien, elle n'est pas juste dessinée sur un PowerPoint, elle marche vraiment en prod."
- **Limite assumée**: la couverture sécurité est niveau socle, pas pentest complet.
- **Action de sécurisation**: planifier un audit sécurité approfondi (authz fine, secrets, tests de pénétration).
- **Question jury probable**: "Quelle preuve de l'async implémenté?"
- **Réponse simple**: "On voit bien le flux complet: création d'analyse, passage en queue, traitement worker, puis mise à jour en base."

---

## O4 — Méthodologie d’audit

- **Compétence RNCP liée**: C2
- **Titre de slide**: "O4 — Méthode d'audit explicite et reproductible"
- **Capture principale**: `docs/30-compliance/rncp/block-1/02-current-state-audit.md` (section "Méthodologie d'audit")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/context-audit-compliance.md` (section "1.3 Investigation Methodology")
> Justification
> L'idée est de montrer qu'on ne fait pas les choses au feeling. Une méthodologie robuste, ça rassure énormément un jury. Il faut qu'ils se disent : "OK, c'est carré, si quelqu'un d'autre reprend le bébé, il saura refaire la même chose". C'est de la maturité pro.

> Script oral (45-60 s)
> "Ce qui est important sur cette slide, c'est comment on a fait notre audit, et pas juste ce qu'on y a trouvé. On s'est imposé une vraie rigueur en quatre étapes : on épluche la doc, on vérifie la config, on contrôle le code, et enfin on synthétise. L'énorme avantage, c'est que c'est reproductible. Et surtout, ça nous permet d'être totalement transparents : on sait où le bât blesse et on assume nos zones d'ombre plutôt que de les cacher sous le tapis."
- **Limite assumée**: collecte utilisateur de terrain non industrialisée dans un protocole unique versionné.
- **Action de sécurisation**: formaliser un playbook d'audit avec protocole de collecte et limites.
- **Question jury probable**: "Quelles limites de méthode?"
- **Réponse simple**: "On dit clairement ce qui est solide, ce qui est partiel, et ce qu'il reste à compléter."

---

## O5 — Corpus de spécifications

- **Compétence RNCP liée**: C3
- **Titre de slide**: "O5 — Spécifications fonctionnelles et techniques traçables"
- **Capture principale**: `docs/30-compliance/rncp/block-1/03-functional-specifications.md` (table "Traçabilité besoins -> fonctions")
- **Capture de renfort**: `docs/30-compliance/rncp/block-1/04-technical-specifications.md` (sections "Contrat API réellement exposé" + "Données et persistance")
> Justification
> Ici on s'attaque à la traçabilité. On veut éviter le cliché du développeur qui code des trucs qui n'ont rien à voir avec le besoin initial. Le jury doit voir le fil rouge : besoin => spec fonctionnelle => spec technique.

> Script oral (45-60 s)
> "Si vous regardez bien ce tableau, vous verrez notre fil rouge. Pour éviter de se perdre dans des specs interminables et floues, on a tout tracé. Un besoin métier donne une fonctionnalité, qui elle-même se traduit par une brique technique très précise. Au moins avec ça, on sait exactement ce qu'on doit tester à la fin. S'il y a un décalage entre ce que le client veut et ce qu'on a implémenté, on le repère tout de suite très facilement."
- **Limite assumée**: certaines fonctionnalités élargies sont spécifiées mais pas encore démontrées en production.
- **Action de sécurisation**: expliciter en slide la séparation "implémenté" vs "planifié".
- **Question jury probable**: "Comment éviter des specs trop vagues?"
- **Réponse simple**: "On évite le flou avec des critères testables: endpoint attendu, statut attendu, résultat attendu."

---

## O6 — Accessibilité dans les spécifications

- **Compétence RNCP liée**: C3
- **Titre de slide**: "O6 — Accessibilité transformée en exigences"
- **Capture principale**: `docs/30-compliance/rncp/block-1/03-functional-specifications.md` (section "Exigences accessibilité (PSH)")
- **Capture de renfort**: `docs/30-compliance/rncp/block-1/04-technical-specifications.md` (section "Exigences accessibilité techniques (PSH)")
> Justification
> Suite logique de l'O2. On a dit que le PSH était important, maintenant on le prouve dans le dur. Ce ne sont pas juste de beaux principes, ce sont des tickets, des critères et de vraies contraintes dans la réalisation technique.

> Script oral (45-60 s)
> "On parlait d'accessibilité tout à l'heure, eh bien voilà comment ça se matérialise concrètement. Sur cette capture, vous voyez qu'on a transformé nos intentions en véritables critères d'acceptation. On parle de taille de police, de contraste de couleurs, de vocalisation pour les lecteurs d'écran... Ce qu'il faut en retenir, c'est que l'accessibilité a sa place dans nos spécifications. Alors oui, ça demande plus de rigueur en phase de test, mais au moins les règles du jeu sont posées noir sur blanc."
- **Limite assumée**: peu de preuves de tests outillés lecteur d'écran dans l'historique actuel.
- **Action de sécurisation**: plan de recette PSH iOS/Android avec cas de test versionnés.
- **Question jury probable**: "Avez-vous des preuves techniques déjà en place?"
- **Réponse simple**: "Oui, la base est là dans les specs; la prochaine étape c'est de renforcer les tests outillés."

---

## O7 — Accessibilité des documents fournis

- **Compétence RNCP liée**: C2 + C3
- **Titre de slide**: "O7 — Accessibilité du dossier et des supports"
- **Capture principale**: `docs/30-compliance/rncp/block-1/m1-observables-evidence-matrix.md` (ligne O7: manque identifié)
- **Capture de renfort**: `docs/30-compliance/rncp/block-1/02-current-state-audit.md` (section "Audit accessibilité (PSH)")
> Justification
> La carte de l'honnêteté et de la maturité. Un pro sait dire "on n'est pas parfaits là-dessus, mais on a un plan pour y remédier". On montre qu'on pilote nos livrables.

> Script oral (45-60 s)
> "Je vais être très transparent avec vous sur cette slide : pour l'accessibilité de nos propres documents, on n'est pas encore au niveau qu'on voudrait. On a bien les principes en tête, mais il nous manque une checklist unifiée pour standardiser tout ça de bout en bout. Mais le fait d'avoir identifié ce trou dans la raquette, c'est justement ce qui nous permet d'avancer. La prochaine étape est toute tracée : mettre en place cette grille unique pour que chaque nouveau doc réponde aux standards, que ce soit du texte, du contraste ou de l'audio."
- **Limite assumée**: pas de checklist O7 unique consolidée dans le repo à date.
- **Action de sécurisation**: créer une checklist accessibilité des livrables (titres, contraste, alt text, verbalisation visuels).
- **Question jury probable**: "Comment garantissez-vous l'accessibilité des slides?"
- **Réponse simple**: "Avec une grille claire: contraste, structure, alt text, et verbalisation des visuels."

---

## O8 — Analyse financière

- **Compétence RNCP liée**: C4
- **Titre de slide**: "O8 — Analyse financière reliée à l'architecture"
- **Capture principale**: `docs/30-compliance/rncp/block-1/05-benchmark-budget-scenarios.md` (section "Scénarios budgétaires")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/costs.md` (Executive Summary CAPEX/OPEX)
> Justification
> Fini de rigoler, on parle d'argent. Mais on le fait de manière connectée au terrain. FinOps n'est pas un concept en l'air, c'est l'addition des briques qu'on a choisi d'allumer dans le cloud.

> Script oral (45-60 s)
> "La question du budget, on n'a pas voulu la traiter à part. Sur la slide, vous remarquerez que nos coûts sont directement adossés à notre architecture métier : l'API, les instances workers, le stockage... chaque brique a son propre poids financier. Évidemment ce sont nos hypothèses actuelles, elles seront affinées avec les vrais chiffres de production. Mais notre conviction c'est qu'un bon budget, c'est un budget qui a les pieds dans la technique, pas un fichier Excel hors sol."
- **Limite assumée**: valeurs atelier à revalider selon prix cloud et volumétrie réelles.
- **Action de sécurisation**: revue trimestrielle des hypothèses FinOps.
- **Question jury probable**: "Pourquoi ces montants sont crédibles?"
- **Réponse simple**: "Les montants viennent d'un benchmark documenté, avec des hypothèses claires qu'on revalide régulièrement."

---

## O9 — Scénarios de chiffrage benchmarkés

- **Compétence RNCP liée**: C4
- **Titre de slide**: "O9 — Pilotage par scénarios budgétaires"
- **Capture principale**: `docs/30-compliance/rncp/block-1/05-benchmark-budget-scenarios.md` (tableau MVP / Scale / Scale+)
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/costs.md` + `docs/10-product/prototype-pool/workshop/impacts-risks.md`
> Justification
> Le maître-mot ici, c'est l'anticipation. On ne donne pas un gros chiffre fixe qui sera faux dans 6 mois. On montre une capacité à piloter le risque financier au rythme de la croissance du projet.

> Script oral (45-60 s)
> "Ce tableau que vous avez sous les yeux, c'est un peu notre boussole pour l'avenir. On ne s'est pas arrêtés à un budget unique parce que ça n'aurait pas de sens face à notre croissance. À la place, on a construit des scénarios : le lancement, la phase de croissance normale, et le gros pic de trafic. Et ce qui fait le lien entre ces paliers, ce sont nos vraies métriques de monitoring comme la latence ou la charge serveur. En bref : on ne sort pas le chéquier à l'aveugle, on attend que nos serveurs appellent à l'aide."
- **Limite assumée**: seuils de bascule à instrumenter plus finement côté monitoring.
- **Action de sécurisation**: définir des seuils chiffrés d'alerte et décisions de scale.
- **Question jury probable**: "Quel scénario de départ?"
- **Réponse simple**: "On démarre en MVP et on scale seulement quand les seuils de charge et de latence sont dépassés."

---

## O10 — Étude prospective évolution/migration

- **Compétence RNCP liée**: C5
- **Titre de slide**: "O10 — Feuille de route d'évolution et migration"
- **Capture principale**: `docs/30-compliance/rncp/block-1/06-risk-evolution-migration.md` (sections "Stratégie d'évolution (24-36 mois)" + "Stratégie de migration technique")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/impacts-risks.md` (migration, SPOF, résilience)
> Justification
> La preuve d'une vision long terme. C'est l'équivalent de l'échiquier : on ne se bat pas juste pour demain, on anticipe les 3 prochains coups pour la scalabilité et éviter l'effet "usine à gaz".

> Script oral (45-60 s)
> "Une fois notre première version posée, la question c'est 'et après ?'. C'est le sens de cette ligne du temps. Plutôt que d'avoir une roadmap un peu vague, on a tracé trois grands horizons pour maîtriser notre évolution et nos futures migrations. Et comme on n'aime pas le risque de l'effet domino — quand on touche à un truc et que tout s'écroule —, notre mantra pour nos choix d'architecture à moyen/long terme, ça reste la fameuse logique des petits pas : évoluer sans rien casser en production."
- **Limite assumée**: gouvernance de migration à industrialiser si montée en charge forte.
- **Action de sécurisation**: imposer feature flags + plan de rollback par lot de migration.
- **Question jury probable**: "Comment sécuriser une migration DB?"
- **Réponse simple**: "On ajoute d'abord, on bascule ensuite, et on garde toujours un plan de retour arrière."

---

## O11 — Vulgarisation orale de la prospective

- **Compétence RNCP liée**: C5
- **Titre de slide**: "O11 — Vulgariser la stratégie de risque et continuité"
- **Capture principale**: `docs/30-compliance/rncp/block-1/06-risk-evolution-migration.md` (section "Vulgarisation orale (O11) — trame 90 secondes")
- **Capture de renfort**: `docs/10-product/prototype-pool/workshop/impacts-risks.md` (mode dégradé, backup, SPOF)
> Justification
> La capacité ultime de l'architecte ou du tech lead : rendre le complexe évident. On doit prouver ici qu'on sait expliquer à n'importe qui (un comité de direction ou un décideur non-tech) pourquoi on s'est pété la figure, comment on relance la machine, et ce qu'on a préservé."

> Script oral (45-60 s)
> "J'en viens à notre stratégie pour gérer l'imprévu. Il ne s'agit pas de jeter du jargon à tout va, mais bien de montrer les choses simplement. Sur ce schéma, vous avez nos points de faiblesse possibles, les tuiles majeures qu'on peut rencontrer, et la parade qu'on a prévue pour chacune. On ne vendra jamais du zéro incident, par contre on est capables de basculer en mode dégradé proprement, de ramener le système en vie et surtout, de le faire sans perdre les données essentielles en route."
- **Limite assumée**: certains plans de continuité restent à tester en exercice réel.
- **Action de sécurisation**: planifier des exercices de reprise (table-top + restore test).
- **Question jury probable**: "Si tout tombe, que se passe-t-il?"
- **Réponse simple**: "On passe en mode dégradé, on relance proprement, puis on revient à la normale sans perdre l'essentiel."
