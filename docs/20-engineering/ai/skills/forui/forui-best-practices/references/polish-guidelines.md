# Guide des Standards de Polish UI (Forui + Ascension)

Ce document définit les standards obligatoires d'excellence visuelle et d'expérience utilisateur pour toutes les interfaces Flutter développées avec **Forui** dans le projet Ascension.

Tout développeur ou agent IA autonome intervenant sur l'application mobile doit respecter ces trois piliers.

---

## 1. Iconographie : Utilisation stricte de `FLucideIcons`

> [!CAUTION]
> **Interdiction formelle d'utiliser `Icons.*` de Flutter Material.** Les icônes Material 2/3 jurent avec le design system minimaliste Forui (inspiré de shadcn/ui).
> **Inutile d'ajouter `lucide_icons` :** Forui intègre et réexporte déjà l'intégralité du catalogue Lucide v1.33+ via `import 'package:forui/forui.dart';`.

### Règle d'or
Utilisez systématiquement `FLucideIcons.<nom>` avec un widget standard `Icon` :

```dart
import 'package:forui/forui.dart';

// ✅ CORRECT
Icon(FLucideIcons.pencil, size: 18)
Icon(FLucideIcons.settings, size: 20)
Icon(FLucideIcons.circleCheck, size: 18)
Icon(FLucideIcons.logOut, size: 18)

// ❌ INTERDIT
Icon(Icons.edit_outlined)
Icon(Icons.settings)
Icon(Icons.check_circle_outline)
Icon(Icons.logout)
```

### Table de correspondance rapide

| Usage courant | ❌ Ancien Material | ✅ Standard Ascension (`FLucideIcons`) |
| :--- | :--- | :--- |
| Éditer / Modifier | `Icons.edit` / `edit_outlined` | `FLucideIcons.pencil` |
| Paramètres | `Icons.settings` / `settings_outlined` | `FLucideIcons.settings` |
| Statistiques / Analyse | `Icons.analytics` / `bar_chart` | `FLucideIcons.chartColumn` ou `chartSpline` |
| Validation / Succès | `Icons.check_circle` | `FLucideIcons.checkCircle` ou `check` |
| Erreur / Échec | `Icons.cancel` / `error` | `FLucideIcons.circleX` ou `circleAlert` |
| Profil / Utilisateur | `Icons.person` | `FLucideIcons.user` |
| Vidéo / Caméra | `Icons.videocam` | `FLucideIcons.video` ou `camera` |
| Lecture / Play | `Icons.play_circle` | `FLucideIcons.circlePlay` |
| Déconnexion | `Icons.logout` | `FLucideIcons.logOut` |
| Suppression | `Icons.delete` | `FLucideIcons.trash2` |
| Recherche | `Icons.search` | `FLucideIcons.search` |
| Filtres | `Icons.filter_list` | `FLucideIcons.filter` |
| Retour arrière | `Icons.arrow_back` | `FLucideIcons.arrowLeft` |

---

## 2. Micro-Interactions & Transitions Déclaratives (`flutter_animate`)

> [!IMPORTANT]
> Les écrans et composants Forui ne doivent jamais apparaître de façon abrupte ou rigide.
> N'utilisez pas de `SingleTickerProviderStateMixin` ou d'`AnimationController` manuel pour des animations d'entrée : utilisez **`flutter_animate`**.

### Standard d'entrée de page / sections
Appliquez un fondu subtil (`fadeIn`) couplé à un léger déplacement vertical (`slideY`) :

```dart
import 'package:flutter_animate/flutter_animate.dart';

// Entrée d'un bloc ou d'une carte
_MySection()
    .animate()
    .fadeIn(duration: 300.ms, curve: Curves.easeOut)
    .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
```

### Entrée décalée en cascade (Staggered list / cards)
Lorsque vous affichez une liste d'éléments (sessions d'escalade, cartes de métriques) :

```dart
Column(
  children: [
    for (int i = 0; i < items.length; i++) ...[
      _ItemCard(item: items[i])
          .animate()
          .fadeIn(duration: 250.ms, delay: (40 * i).ms, curve: Curves.easeOut)
          .slideX(begin: 0.03, end: 0, curve: Curves.easeOut),
      if (i < items.length - 1) const SizedBox(height: 10),
    ],
  ],
)
```

### Règles de timing
- **Durée d'apparition :** Entre `200.ms` et `350.ms` maximum (l'interface doit rester nerveuse et réactive).
- **Décalage (stagger) :** Entre `30.ms` et `50.ms` par élément.
- **Courbe par défaut :** `Curves.easeOut` ou `Curves.easeOutCubic`.
- **Amplitude de glissement :** Subtile (`begin: 0.04` à `0.08`), jamais de grands déplacements qui fatiguent l'œil.

---

## 3. États de Chargement Modernes (`Skeletonizer`)

> [!WARNING]
> **Bannir les indicateurs circulaires de chargement plein écran (`CircularProgressIndicator`)** lors de la récupération des données de profil, statistiques ou historiques.
> Utilisez **`Skeletonizer`** pour projeter la géométrie finale de l'écran avec un effet *shimmer*.

### Patron d'implémentation standard

Encapsulez le composant ou la colonne avec `Skeletonizer(enabled: isLoading, child: ...)` :

```dart
import 'package:skeletonizer/skeletonizer.dart';

// Grille de statistiques avec Skeletonizer
Skeletonizer(
  enabled: history == null, // En chargement
  child: Row(
    children: [
      Expanded(
        child: _StatCard(
          icon: FLucideIcons.chartColumn,
          value: history == null ? '00' : '$total',
          label: 'Analyses',
        ),
      ),
      Expanded(
        child: _StatCard(
          icon: FLucideIcons.checkCircle,
          value: history == null ? '00' : '$successCount',
          label: 'Réussites',
        ),
      ),
    ],
  ),
)
```

### Patron pour les listes de cartes (`history == null`)
Pour les listes de données dynamiques, affichez 3 ou 4 cartes factices (*dummy entries*) dans le `Skeletonizer` pendant le chargement :

```dart
if (history == null)
  Skeletonizer(
    enabled: true,
    child: Column(
      children: [
        for (int i = 0; i < 3; i++) ...[
          _MiniAnalysisCard(
            entry: AnalysisHistoryEntry(
              analysisId: 'placeholder-$i',
              createdAt: DateTime.now(),
              status: 'completed',
              processingTimeMs: 1200,
              resultJson: '{"frames":[{"pose_detected":true}]}',
            ),
          ),
          if (i < 2) const SizedBox(height: 10),
        ],
      ],
    ),
  )
else if (history.isEmpty)
  const _EmptyState()
else
  Column(
    children: [
      for (final entry in history) ...[
        _MiniAnalysisCard(entry: entry),
        const SizedBox(height: 10),
      ],
    ],
  )
```

### Cas particulier : Graphiques complexes (`fl_chart`)
`Skeletonizer` tente de squelettiser tous les éléments personnalisés. Sur les graphiques de progression de cotation ou d'angles biomécaniques :
```dart
Skeleton.ignore(
  child: LineChart(...), // Ne sera pas déformé par l'effet squelette
)
// OU
Skeleton.leaf(
  child: Container(
    height: 180,
    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
  ),
)
```

---

## 4. Exemple d'Écran Référentiel

Consultez `forui_profile_view.dart` comme référence absolue combinant :
- Thème et composants Forui (`FCard`, `FButton`, `FAvatar`, `FBadge`, `FSheet`, `FDialog`).
- `FLucideIcons` pour tous les symboles d'actions et d'états.
- `flutter_animate` pour l'entrée étagée et dynamique des sections.
- `Skeletonizer` pour la grille de statistiques et la liste des analyses récentes.
