---
name: forui
description: A comprehensive Flutter UI library inspired by shadcn/ui. Provides over 40+ minimal, highly customizable, and accessible widgets (FButton, FCard, FAvatar, FBadge, FTextField, FDialog, FSheet, FTile, etc.) following the Forui design system. Use this skill when building or styling Flutter UIs with Forui.
---

# Forui for Flutter

Forui is a minimalist, open-source Flutter UI library inspired by shadcn/ui, providing 40+ carefully crafted, highly customizable components with first-class desktop and mobile touch support.

## Package Import

```dart
import 'package:forui/forui.dart';
```

## Theming (`FTheme`)

Forui uses `FTheme` with explicit themes and density (touch vs desktop):

```dart
final isDark = Theme.of(context).brightness == Brightness.dark;
// Option A: Using FTheme presets
final theme = isDark ? FTheme.neutral.dark.touch() : FTheme.neutral.light.touch();

// Option B: Using custom FThemeData
final theme = FThemeData(
  colors: isDark ? FColors.neutralDark : FColors.neutralLight,
  touch: true,
);

FTheme(
  data: theme,
  child: MyWidget(),
)
```

Access theme tokens with `context.theme`:
```dart
final colors = context.theme.colors;
final typography = context.theme.typography;
final style = context.theme.style;
final icons = context.theme.icons;
```

Available color palettes: `FColors.neutralLight`, `FColors.neutralDark`, `FColors.zincLight`, `FColors.zincDark`, `FColors.slateLight`, `FColors.slateDark`.

## Core Components Reference

| Component | Description | Reference |
| :--- | :--- | :--- |
| **FButton** | Minimalist buttons with variants (`.primary`, `.secondary`, `.outline`, `.destructive`, `.ghost`) | [forui-controls](forui-controls/SKILL.md) |
| **FCard** | Elevated container for grouped information | [forui-content-components](forui-content-components/SKILL.md) |
| **FAvatar** | User profile image with initials fallback | [forui-content-components](forui-content-components/SKILL.md) |
| **FBadge** | Status and category badges with semantic variants | [forui-content-components](forui-content-components/SKILL.md) |
| **FTextField** | Text input with labels, descriptions, and error states | [forui-forms-inputs](forui-forms-inputs/SKILL.md) |
| **FDialog** | Modal dialogs via `showFDialog` with backdrop blur | [forui-overlays-feedback](forui-overlays-feedback/SKILL.md) |
| **FSheet** | Bottom or side modal sheets via `showFSheet` | [forui-overlays-feedback](forui-overlays-feedback/SKILL.md) |
| **FTile** | Grouped action and settings rows | [forui-content-components](forui-content-components/SKILL.md) |
| **FProgress** | Linear and circular progress indicators | [forui-content-components](forui-content-components/SKILL.md) |

## Polish & UI Standards (Ascension Standard)

Pour garantir une expérience visuelle moderne et fluide digne des meilleures applications :

1. **Iconographie exclusive `FLucideIcons`** :
   - ❌ **Ne jamais utiliser** `Icons.*` (Material Design standard).
   - ✅ Utiliser `FLucideIcons.<name>` directement exporté par `package:forui/forui.dart`.
2. **Transitions & Micro-animations (`flutter_animate`)** :
   - Éviter les interfaces statiques et rigides.
   - Appliquer des apparitions déclaratives subtiles (`child.animate().fadeIn(duration: 250.ms).slideY(begin: 0.05)`).
   - Préférer les cascades échelonnées (*staggered*) sur les listes et grilles de statistiques (`delay: (40 * index).ms`).
3. **États de chargement avec `Skeletonizer`** :
   - ❌ **Ne jamais bloquer l'écran** avec un simple `CircularProgressIndicator` au centre.
   - ✅ Encapsuler les cartes et listes dans `Skeletonizer(enabled: isLoading, child: ...)`.
   - Fournir des modèles fictifs (*dummy data*) pendant `loading == true` pour que le *shimmer* dessine la structure finale.

Consultez le guide détaillé : [Guide des Standards de Polish UI](forui-best-practices/references/polish-guidelines.md).

## Specialized Skills
- [Setup & App Root](forui-setup/SKILL.md)
- [Theming & Styles](forui-theming/SKILL.md)
- [Controls & State](forui-controls/SKILL.md)
- [Forms & Inputs](forui-forms-inputs/SKILL.md)
- [Content Components](forui-content-components/SKILL.md)
- [Overlays & Feedback](forui-overlays-feedback/SKILL.md)
- [Layout & Navigation](forui-layout-navigation/SKILL.md)
- [Best Practices](forui-best-practices/SKILL.md)
- [Polish Guidelines](forui-best-practices/references/polish-guidelines.md)
