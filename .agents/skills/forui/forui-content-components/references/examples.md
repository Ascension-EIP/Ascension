# Forui Content Components Examples

## Display Component Matrix

| Content | Preferred component |
| --- | --- |
| Standalone object summary | `FCard` |
| Settings/action rows | `FTile` or `FTileGroup` |
| Rich item list rows | `FItem` or `FItemGroup` |
| Expandable optional details | `FAccordion` |
| Inline important message | `FAlert` |
| Compact status/category | `FBadge` |
| Person/entity image fallback | `FAvatar` |
| Ongoing work | `FProgress` or `FCircularProgress` |

## Row Review

- Primary text is short and scannable.
- Secondary text explains, not repeats.
- Prefix/suffix content is predictable across rows.
- Destructive rows are visibly distinct.
- Disabled rows still explain why they cannot be used when needed.

## Card Review

- One card represents one object or decision.
- Actions belong to the card content.
- Cards are not nested inside other cards.
- Loading and empty states preserve the card's expected footprint.
