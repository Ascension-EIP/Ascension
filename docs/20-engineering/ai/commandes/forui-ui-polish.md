---
name: forui-ui-polish
description: "UI polish standards for Flutter + Forui: FLucideIcons, flutter_animate micro-interactions, and Skeletonizer loading states"
globs: ["apps/mobile/lib/**/*.dart"]
alwaysApply: true
---

# UI Polish Guidelines for Ascension Mobile (Forui)

Whenever creating, refactoring, or reviewing Flutter widgets in `apps/mobile/lib/`, you MUST apply these three polish standards:

1. **Iconography (`FLucideIcons`)**:
   - ❌ **NEVER** use `Icons.*` from Flutter Material (outdated aesthetic).
   - ✅ **ALWAYS** use `FLucideIcons.<name>` from `package:forui/forui.dart` (bundled natively with Forui).
   - Do NOT add `lucide_icons` or other icon libraries to `pubspec.yaml`; use `FLucideIcons`.

2. **Micro-Interactions & Transitions (`flutter_animate`)**:
   - ❌ Do not write static/rigid screens, and do not create manual `AnimationController` for simple entry animations.
   - ✅ Use declarative chains: `widget.animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, curve: Curves.easeOut)`.
   - On lists/grids, apply staggered delays: `delay: (40 * index).ms`.

3. **Loading States (`skeletonizer`)**:
   - ❌ **NEVER** display full-screen `CircularProgressIndicator` spinners for data retrieval.
   - ✅ Wrap content sections in `Skeletonizer(enabled: isLoading, child: ...)`.
   - Provide dummy placeholder data while loading so the shimmering skeleton accurately previews the final layout.
   - For custom charts (`fl_chart`), wrap with `Skeleton.ignore()` or `Skeleton.leaf()`.

Detailed guide & icon conversion table: `.agents/skills/forui/forui-best-practices/references/polish-guidelines.md`.
