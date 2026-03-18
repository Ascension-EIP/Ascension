> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-warning}

---

# Mobile Accessibility Implementation Guide

---

## Table of Contents

- [Mobile Accessibility Implementation Guide](#mobile-accessibility-implementation-guide)
  - [Table of Contents](#table-of-contents)
  - [Document Purpose](#document-purpose)
  - [Scope and Standards](#scope-and-standards)
  - [Accessibility by Disability Type](#accessibility-by-disability-type)
    - [Blindness and Low Vision](#blindness-and-low-vision)
      - [Required Features](#required-features)
      - [Acceptance Criteria](#acceptance-criteria)
    - [Color Vision Deficiency](#color-vision-deficiency)
      - [Required Features](#required-features-1)
      - [Acceptance Criteria](#acceptance-criteria-1)
    - [Deafness and Hard of Hearing](#deafness-and-hard-of-hearing)
      - [Required Features](#required-features-2)
      - [Acceptance Criteria](#acceptance-criteria-2)
    - [Motor and Dexterity Impairments](#motor-and-dexterity-impairments)
      - [Required Features](#required-features-3)
      - [Acceptance Criteria](#acceptance-criteria-3)
    - [Speech Impairments](#speech-impairments)
      - [Required Features](#required-features-4)
      - [Acceptance Criteria](#acceptance-criteria-4)
    - [Cognitive Disabilities](#cognitive-disabilities)
      - [Required Features](#required-features-5)
      - [Acceptance Criteria](#acceptance-criteria-5)
    - [Neurodivergence and Sensory Processing](#neurodivergence-and-sensory-processing)
      - [Required Features](#required-features-6)
      - [Acceptance Criteria](#acceptance-criteria-6)
    - [Vestibular Disorders and Photosensitivity](#vestibular-disorders-and-photosensitivity)
      - [Required Features](#required-features-7)
      - [Acceptance Criteria](#acceptance-criteria-7)
    - [Temporary and Situational Limitations](#temporary-and-situational-limitations)
      - [Required Features](#required-features-8)
      - [Acceptance Criteria](#acceptance-criteria-8)
  - [Cross-Cutting Accessibility Requirements](#cross-cutting-accessibility-requirements)
  - [Accessibility Settings to Expose In-App](#accessibility-settings-to-expose-in-app)
  - [Implementation Requirements for Flutter](#implementation-requirements-for-flutter)
    - [Semantic and Focus Management](#semantic-and-focus-management)
    - [Accessible Component Library](#accessible-component-library)
    - [Forms and Validation](#forms-and-validation)
    - [Media and Content](#media-and-content)
  - [Testing and Validation Strategy](#testing-and-validation-strategy)
    - [Manual Testing](#manual-testing)
    - [Automated Testing](#automated-testing)
    - [User Validation](#user-validation)
  - [Release Gate and Definition of Done](#release-gate-and-definition-of-done)
  - [Roadmap and Priorities](#roadmap-and-priorities)
    - [Immediate Priority](#immediate-priority)
    - [High Priority](#high-priority)
    - [Continuous Improvement](#continuous-improvement)
  - [Ownership and Governance](#ownership-and-governance)

---

## Document Purpose

This document defines a complete and practical accessibility target for the Ascension mobile application.

The objective is simple: every core user journey must remain usable by people with permanent, temporary, or situational disabilities, without requiring workarounds.

---

## Scope and Standards

- Primary target: **WCAG 2.2 Level AA** on mobile.
- Stretch target: apply **AAA** criteria when implementation cost is reasonable.
- Regulatory alignment: **EN 301 549** and **RGAA** for audit framing.
- Platform alignment: **iOS VoiceOver/HIG** and **Android TalkBack/Accessibility** guidance.

Accessibility must be designed at specification time, not added after implementation.

---

## Accessibility by Disability Type

### Blindness and Low Vision

#### Required Features

- Full compatibility with screen readers (`VoiceOver`, `TalkBack`).
- Semantic labels for every interactive element (name, role, value, state, hint).
- Logical focus order across all screens.
- Support for text scaling up to at least 200% without clipping or overlap.
- Reflow-safe layout on small screens and large font sizes.
- Alternative text for all meaningful images, icons, and charts.
- Non-visual status messages for loading, success, warning, and error states.

#### Acceptance Criteria

- Critical journeys are fully operable without sight.
- No unlabeled action exists in production screens.
- All dynamic updates are announced to assistive technologies.

### Color Vision Deficiency

#### Required Features

- Color is never the only channel for meaning.
- Use iconography, text, and shape in addition to color.
- Accessible contrast: 4.5:1 for normal text and 3:1 for large text.
- Error/success/warning states include explicit textual labels.
- Palette is validated against common color blindness simulations.

#### Acceptance Criteria

- Users can complete form and status-based tasks without relying on color interpretation.

### Deafness and Hard of Hearing

#### Required Features

- Captions for all instructional and functional videos.
- Transcript for long-form audio content.
- Visual equivalents for all sound-only alerts.
- Optional haptic feedback for critical notifications.
- Text-first alternatives for voice guidance.

#### Acceptance Criteria

- No critical flow depends on hearing.
- All guidance used in app experiences exists in text form.

### Motor and Dexterity Impairments

#### Required Features

- Minimum touch targets of 44x44 pt (iOS) and 48x48 dp (Android).
- Avoid mandatory complex gestures (multi-finger, long hold, fast swipes).
- Every gesture-based action has a visible button alternative.
- Generous tap tolerance and cancellation paths.
- Full operation with one hand where possible.
- Compatibility with switch access and external keyboards where supported.

#### Acceptance Criteria

- Core actions can be completed with limited precision and limited range of motion.

### Speech Impairments

#### Required Features

- No critical feature requires voice input.
- Every voice interaction has typed and touch alternatives.
- Voice transcription fields remain editable before submission.

#### Acceptance Criteria

- Speech is optional, never mandatory.

### Cognitive Disabilities

#### Required Features

- Plain language and short sentences.
- One clear objective per screen.
- Consistent navigation patterns and interaction placement.
- Step-by-step instructions for multi-stage tasks.
- Friendly and actionable error messages.
- Draft autosave and task resumption after interruption.
- Progress indicators for multi-step workflows.

#### Acceptance Criteria

- Users can recover from errors without external support.
- Users can pause and resume without losing context.

### Neurodivergence and Sensory Processing

#### Required Features

- Reduced distraction mode (fewer simultaneous elements).
- Optional focus mode for task-centered screens.
- Adjustable content density and pacing.
- Notification bundling and interruption reduction.
- Stable and predictable screen transitions.

#### Acceptance Criteria

- Users can tune visual and cognitive load to their comfort level.

### Vestibular Disorders and Photosensitivity

#### Required Features

- Respect OS-level reduced motion settings.
- Avoid flicker, flashing, and parallax-heavy transitions.
- Disable autoplay animations where possible.
- Keep motion effects subtle and optional.

#### Acceptance Criteria

- App remains fully usable when motion is reduced to near zero.

### Temporary and Situational Limitations

#### Required Features

- Usable in bright light and low light conditions.
- Usable in noisy environments without audio dependency.
- Usable in low-network conditions with clear retry states.
- Session recovery after network loss or interruption.
- Short, resumable interactions for on-the-go use.

#### Acceptance Criteria

- Critical journeys remain operable under poor connectivity and noisy surroundings.

---

## Cross-Cutting Accessibility Requirements

- Accessibility must be considered in every user story acceptance criteria.
- No release is allowed with known critical accessibility regressions.
- All major actions must provide multimodal feedback (visual, text, and optional haptics).
- Navigation must remain coherent and consistent across tabs and routes.
- Accessibility decisions must be documented in design and engineering specs.

---

## Accessibility Settings to Expose In-App

The application must provide a dedicated `Accessibility` settings section.

Required options:

- Text size override (in addition to OS scaling).
- High-contrast mode.
- Reduced motion toggle.
- Simplified interface mode.
- Captions default on/off.
- Application language selector (`French` / `English`).
- Haptic intensity preferences.
- Reading and playback speed controls.
- Dyslexia-friendly typography and spacing profile.
- Reduced interruptions profile.

Each setting must include:

- immediate preview,
- clear explanatory text,
- reset to defaults,
- persistence across sessions.

Language setting requirements:

- Must apply immediately across the interface.
- Must support at least `French` and `English` in production.
- Must remain compatible with screen readers (labels updated in selected language).

---

## Implementation Requirements for Flutter

### Semantic and Focus Management

- Use `Semantics` consistently for interactive and meaningful content.
- Use `ExcludeSemantics` only when intentionally preventing duplicate announcements.
- Configure focus traversal using `Focus` and `FocusTraversalGroup`.
- Ensure dialogs, sheets, and modals trap and restore focus correctly.

### Accessible Component Library

- Build and enforce reusable accessible components for buttons, form fields, dialogs, and banners.
- Centralize color and typography tokens with accessibility constraints.
- Include error, disabled, focus, and pressed states in every component contract.

### Forms and Validation

- Pair each field with a visible label and assistive hint.
- Announce validation errors clearly and close to the field.
- Provide correction instructions, not only error statements.

### Media and Content

- Enforce caption/transcript workflows for all media content.
- Require alt text metadata for all non-decorative media assets.

---

## Testing and Validation Strategy

### Manual Testing

Required per release on both iOS and Android:

- Screen reader pass on critical journeys.
- Large text pass at maximum supported scaling.
- Contrast and dark-mode readability pass.
- Reduced motion pass.
- One-hand and low-precision interaction pass.
- No-audio usage pass.

### Automated Testing

- Widget tests validating semantic labels and roles.
- Golden tests for large text and reflow behavior.
- Token-level contrast checks in design system pipelines.
- Lint rules for missing labels and inaccessible patterns.

### User Validation

- Regular usability sessions with people with disabilities.
- Quarterly review of findings and prioritized remediation.

---

## Release Gate and Definition of Done

A feature is considered done only when all conditions below are true:

- Screen reader usability is validated on core states.
- Contrast and text scaling checks pass.
- Touch target and gesture alternatives are compliant.
- Errors are understandable and recoverable.
- Audio and color dependencies have alternatives.
- Reduced motion behavior is functional.
- Accessibility tests are attached to the release evidence.

---

## Roadmap and Priorities

### Immediate Priority

- Fix screen reader blockers and missing semantics.
- Fix contrast violations and text overflow issues.
- Add alternatives for sound-only and gesture-only interactions.
- Standardize accessible form error handling.

### High Priority

- Ship full in-app accessibility settings.
- Add caption/transcript coverage for all relevant media.
- Roll out simplified interface and focus modes.

### Continuous Improvement

- Raise coverage toward AAA where feasible.
- Monitor accessibility KPIs and reduce regression rates.
- Expand testing panel diversity and usage contexts.

---

## Ownership and Governance

- Product: defines accessibility requirements in each feature scope.
- Design: delivers compliant patterns and validates visual accessibility.
- Mobile engineering: implements semantic, interaction, and fallback behavior.
- QA: executes accessibility test matrix and regression checks.
- Tech lead: blocks releases with unresolved critical accessibility defects.

Accessibility is a baseline quality requirement, not an optional enhancement.
