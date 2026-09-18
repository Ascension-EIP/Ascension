---
id: 29954769-86bc-4288-a96b-6d4939c6b4d6
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
| --- | --- | --- |
| **FButton** | Minimalist buttons with variants (`.primary`, `.secondary`, `.outline`, `.destructive`, `.ghost`) | [forui-controls](page:bdb640cd-9d2f-4cae-b64a-e6d907c2ad0d) |
| **FCard** | Elevated container for grouped information | [forui-content-components](page:a2647d68-218a-48dd-be3c-d246f0f77729) |
| **FAvatar** | User profile image with initials fallback | [forui-content-components](page:a2647d68-218a-48dd-be3c-d246f0f77729) |
| **FBadge** | Status and category badges with semantic variants | [forui-content-components](page:a2647d68-218a-48dd-be3c-d246f0f77729) |
| **FTextField** | Text input with labels, descriptions, and error states | [forui-forms-inputs](page:793709bd-580e-42a1-b6c9-5870a1e72953) |
| **FDialog** | Modal dialogs via `showFDialog` with backdrop blur | [forui-overlays-feedback](page:23270e83-870d-4623-9a13-ca5db3db5110) |
| **FSheet** | Bottom or side modal sheets via `showFSheet` | [forui-overlays-feedback](page:23270e83-870d-4623-9a13-ca5db3db5110) |
| **FTile** | Grouped action and settings rows | [forui-content-components](page:a2647d68-218a-48dd-be3c-d246f0f77729) |
| **FProgress** | Linear and circular progress indicators | [forui-content-components](page:a2647d68-218a-48dd-be3c-d246f0f77729) |

## Polish & UI Standards (Ascension Standard)

Pour garantir une expérience visuelle moderne et fluide digne des meilleures applications :

1. **Iconographie exclusive** `FLucideIcons` :
   - ❌ **Ne jamais utiliser** `Icons.*` (Material Design standard).
   - ✅ Utiliser `FLucideIcons.<name>` directement exporté par `package:forui/forui.dart`.
2. **Transitions & Micro-animations (**`flutter_animate`**)** :
   - Éviter les interfaces statiques et rigides.
   - Appliquer des apparitions déclaratives subtiles (`child.animate().fadeIn(duration: 250.ms).slideY(begin: 0.05)`).
   - Préférer les cascades échelonnées (*staggered*) sur les listes et grilles de statistiques (`delay: (40 * index).ms`).
3. **États de chargement avec** `Skeletonizer` :
   - ❌ **Ne jamais bloquer l'écran** avec un simple `CircularProgressIndicator` au centre.
   - ✅ Encapsuler les cartes et listes dans `Skeletonizer(enabled: isLoading, child: ...)`.
   - Fournir des modèles fictifs (*dummy data*) pendant `loading == true` pour que le *shimmer* dessine la structure finale.

Consultez le guide détaillé : [Guide des Standards de Polish UI](page:82c030f7-cd50-48e3-bc8a-abea8d9ff19a).

## Specialized Skills

- [Setup & App Root](page:cfc61d77-45de-400d-91f8-dd368e037400)
- [Theming & Styles](page:a0ca0da1-8688-410c-96b7-567e1e39cb20)
- [Controls & State](page:bdb640cd-9d2f-4cae-b64a-e6d907c2ad0d)
- [Forms & Inputs](page:793709bd-580e-42a1-b6c9-5870a1e72953)
- [Content Components](page:a2647d68-218a-48dd-be3c-d246f0f77729)
- [Overlays & Feedback](page:23270e83-870d-4623-9a13-ca5db3db5110)
- [Layout & Navigation](page:a42a5e89-c08e-43f6-a425-ae109603c61f)
- [Best Practices](page:d51a6082-f99f-4b53-9a8c-ba5130c12b8f)
- [Polish Guidelines](page:82c030f7-cd50-48e3-bc8a-abea8d9ff19a)