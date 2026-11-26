# @date 2026-11-25
# @file _2_beta.py
# @brief C2 of the pathfinding: A* search of a feasible beta over four-limb states.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Beta search: which hold under each limb, from the start marks to the finish.

A state is the hold under each of the four limbs (or none). A move changes one
limb. Reach limits are hard constraints; the cost depends on the move, the hold
type, the injured limbs, the wall angle and the preference. Pure Python, no I/O.
"""

import heapq
import itertools
import math
from dataclasses import dataclass

from common.utils.errors import PermanentError
from shared.models import (
    BetaPreference,
    ClimberMorphology,
    ConstraintType,
    HoldType,
    Limb,
)

LEFT_HAND, RIGHT_HAND = Limb.LEFT_HAND, Limb.RIGHT_HAND
LEFT_FOOT, RIGHT_FOOT = Limb.LEFT_FOOT, Limb.RIGHT_FOOT
LIMBS = (LEFT_HAND, RIGHT_HAND, LEFT_FOOT, RIGHT_FOOT)
HAND_IDX, FOOT_IDX = (0, 1), (2, 3)

# Reach limits as fractions of the body size. Segment ratios from Drillis and
# Contini (1966), Winter, "Biomechanics and Motor Control of Human Movement":
# arm span ~ height, shoulder-to-fingertip ~ 0.44 H, leg ~ 0.53 H. The ratios
# below leave a margin for the bent elbow/knee and the body kept on the wall.
MAX_HAND_HAND_RATIO = 0.8  # of the arm span
MAX_HAND_FOOT_RATIO = 0.9  # of the height
MAX_FOOT_FOOT_RATIO = 0.6  # of the height

# Cost model. Every move costs at least ``base`` of the preference (lower bound
# of the heuristic); the terms below only add to it.
FOOT_ADHESION_COST = 3.0  # a foot leaves its hold and stays on the wall
DANGLING_FOOT_COST = 1.0  # per foot left without a hold, on every move made so
INJURED_PENALTY = 6.0  # per move of an injured limb
OVERHANG_COST_PER_45DEG = 0.5  # extra hand-move cost factor per 45 degrees
SMALL_HOLD_CM2 = 10.0  # below this a hold is a poor hand hold
SMALL_HOLD_HAND_COST = 0.5
MAX_EXPANSIONS = 100_000


@dataclass(frozen=True)
class Weights:
    """Cost weights of a preference."""

    base: float  # fixed cost of any move
    dist: float  # weight of the squared fraction of the max reach covered
    foot: float  # multiplier of foot moves


# One table for the three preferences.
WEIGHTS = {
    BetaPreference.EASY: Weights(base=1.0, dist=6.0, foot=1.0),
    # Few long hand moves, feet replaced as little as possible.
    BetaPreference.POWER: Weights(base=3.0, dist=1.0, foot=2.0),
    # Short hand moves, cheap and frequent foot placements.
    BetaPreference.TECHNIQUE: Weights(base=0.5, dist=12.0, foot=0.6),
}

# Cost of a hold type as (hand, foot); ``unknown`` is the generic hold.
HOLD_COST = {
    HoldType.UNKNOWN: (0.0, 0.0),
    HoldType.JUG: (0.0, 0.0),
    HoldType.EDGE: (0.2, 0.0),
    HoldType.PINCH: (0.3, 0.2),
    HoldType.POCKET: (0.3, 0.2),
    HoldType.CRIMP: (0.4, 0.1),
    HoldType.SLOPER: (0.6, 0.3),
    HoldType.FOOTHOLD: (1.0, 0.0),
    HoldType.VOLUME: (1.0, 0.0),
}


class NoBetaError(PermanentError):
    """No beta exists. ``hold_ids`` names the holds around the missing passage."""

    def __init__(self, message: str, hold_ids: tuple[str, ...] = ()):
        super().__init__(message)
        self.hold_ids = hold_ids


@dataclass(frozen=True)
class Hold:
    """A hold: centre in cm in the wall plane (y up), marks and allowed limbs."""

    id: str
    x: float
    y: float
    area_cm2: float
    type: HoldType
    start_limbs: int | None = None
    finish_limbs: int | None = None
    hand: bool = True
    foot: bool = True


@dataclass(frozen=True)
class Body:
    """Climber measures and limbs that cannot be used or are hurt."""

    height_cm: float
    arm_span_cm: float
    missing: frozenset[Limb] = frozenset()
    injured: frozenset[Limb] = frozenset()


@dataclass(frozen=True)
class Step:
    """One state of the beta: hold id under each limb and the limb just moved."""

    holds: dict[Limb, str | None]
    moved: Limb | None


_ARM_ZONES = ("shoulder", "upper_arm", "elbow", "forearm", "wrist", "hand", "fingers")
_LEG_ZONES = ("hip", "thigh", "knee", "shin", "ankle", "foot")


def _limb_of_zone(zone: str) -> Limb | None:
    side, _, part = zone.partition("_")
    if side not in ("left", "right"):
        return None  # head, neck, torso, lower back: ignored in v1
    if part in _ARM_ZONES:
        return Limb(f"{side}_hand")
    if part in _LEG_ZONES:
        return Limb(f"{side}_foot")
    return None


def body_from_morphology(morphology: ClimberMorphology) -> Body:
    """Build the `Body` of a climber morphology (zones mapped to limbs)."""
    limbs = {c.type: set() for c in morphology.constraints or []}
    for c in morphology.constraints or []:
        limb = _limb_of_zone(c.zone.value)
        if limb:
            limbs[c.type].add(limb)
    missing = frozenset(limbs.get(ConstraintType.MISSING, ()))
    injured = frozenset(limbs.get(ConstraintType.INJURED, ())) - missing
    return Body(
        height_cm=morphology.height_cm,
        arm_span_cm=morphology.arm_span_cm or morphology.height_cm,
        missing=missing,
        injured=injured,
    )


def _default_marks(holds: list[Hold]) -> tuple[dict[str, int], dict[str, int]]:
    """Start and finish marks of the holds, with the defaults when a side has none."""
    start = {h.id: h.start_limbs for h in holds if h.start_limbs}
    finish = {h.id: h.finish_limbs for h in holds if h.finish_limbs}
    hand_holds = [h for h in holds if h.hand]
    if not hand_holds:
        raise NoBetaError("no hold can be used by a hand")
    if not start:
        start[min(hand_holds, key=lambda h: (h.y, h.id)).id] = 2
    if not finish:
        finish[min(hand_holds, key=lambda h: (-h.y, h.id)).id] = 2
    return start, finish


def _start_states(
    holds: list[Hold],
    start_marks: dict[str, int],
    avail_hands: list[int],
    avail_feet: list[int],
    valid,
) -> set[tuple[int, ...]]:
    """Every valid way to spread the start marks over the limbs.

    The hands take the marks first (all available hands, at most one per mark),
    the remaining marks go to the feet.
    """
    index = {h.id: i for i, h in enumerate(holds)}
    slots = [index[i] for i, c in sorted(start_marks.items()) for _ in range(c)]
    n_hands = min(len(avail_hands), len(slots))
    n_feet = len(slots) - n_hands
    starts: set[tuple[int, ...]] = set()
    for perm in set(itertools.permutations(slots)):
        for hs in itertools.combinations(avail_hands, n_hands):
            for fs in itertools.combinations(avail_feet, n_feet):
                state = [-1] * 4
                for k, s in zip(hs + fs, perm):
                    state[k] = s
                usable = all(holds[s].hand for k, s in zip(hs, perm)) and all(
                    holds[s].foot for k, s in zip(fs, perm[n_hands:])
                )
                if usable and valid(tuple(state)):
                    starts.add(tuple(state))
    return starts


def _search(
    holds: list[Hold],
    body: Body,
    preference: BetaPreference,
    wall_angle_deg: float | None,
    use_heuristic: bool = True,
    stats: dict[str, int] | None = None,
) -> tuple[list[Step], float]:
    """Run the search and return the beta with its cost.

    ``use_heuristic=False`` makes it a plain Dijkstra (used to check the heuristic).
    ``stats``, when given, receives ``expansions``: the number of expanded states,
    a machine-independent measure of the search cost.
    """
    start_marks, finish_marks = _default_marks(holds)
    n = len(holds)
    ids = [h.id for h in holds]
    ys = [h.y for h in holds]
    index = {h.id: i for i, h in enumerate(holds)}
    dist = [[math.hypot(a.x - b.x, a.y - b.y) for b in holds] for a in holds]
    w = WEIGHTS[preference]
    max_hh = MAX_HAND_HAND_RATIO * body.arm_span_cm
    max_hf = MAX_HAND_FOOT_RATIO * body.height_cm
    max_ff = MAX_FOOT_FOOT_RATIO * body.height_cm
    angle_factor = (
        1.0 + OVERHANG_COST_PER_45DEG * max(wall_angle_deg or 0.0, 0.0) / 45.0
    )

    def near(limit: float) -> list[frozenset[int]]:
        return [frozenset(j for j in range(n) if dist[i][j] <= limit) for i in range(n)]

    near_hh, near_hf, near_ff = near(max_hh), near(max_hf), near(max_ff)
    can_hand = frozenset(i for i, h in enumerate(holds) if h.hand)
    can_foot = frozenset(i for i, h in enumerate(holds) if h.foot)
    avail = [k for k in range(4) if LIMBS[k] not in body.missing]
    avail_hands = [k for k in HAND_IDX if k in avail]
    avail_feet = [k for k in FOOT_IDX if k in avail]

    def reach_ok(ka: int, sa: int, kb: int, sb: int) -> bool:
        if ka in HAND_IDX and kb in HAND_IDX:
            return sb in near_hh[sa]
        if ka in FOOT_IDX and kb in FOOT_IDX:
            return sb in near_ff[sa]
        return sb in near_hf[sa]

    def valid(state: tuple[int, ...]) -> bool:
        placed = [(k, s) for k, s in enumerate(state) if s >= 0]
        if any(
            not reach_ok(ka, sa, kb, sb)
            for (ka, sa), (kb, sb) in itertools.combinations(placed, 2)
        ):
            return False
        hands = [ys[s] for k, s in placed if k in HAND_IDX]
        return not hands or all(ys[s] <= max(hands) for k, s in placed if k in FOOT_IDX)

    if not avail_hands:
        raise NoBetaError("no beta: the climber has no hand to climb with")

    starts = _start_states(holds, start_marks, avail_hands, avail_feet, valid)
    if not starts:
        raise NoBetaError(
            f"no valid start from the start marks {sorted(start_marks)}",
            tuple(sorted(start_marks)),
        )

    finish = {index[i]: min(c, len(avail_hands)) for i, c in finish_marks.items()}
    finish_top = max(ys[i] for i in finish)

    def is_goal(state: tuple[int, ...]) -> bool:
        return all(sum(1 for s in state[:2] if s == f) >= c for f, c in finish.items())

    # Equivalent limbs (same side status) give mirrored states of equal cost:
    # the search keys on the sorted pair, the path keeps the real state.
    sym = [
        pair
        for pair in (HAND_IDX, FOOT_IDX)
        if (LIMBS[pair[0]] in body.missing, LIMBS[pair[0]] in body.injured)
        == (LIMBS[pair[1]] in body.missing, LIMBS[pair[1]] in body.injured)
    ]

    def canon(state: tuple[int, ...]) -> tuple[int, ...]:
        out = list(state)
        for a, b in sym:
            if out[a] > out[b]:
                out[a], out[b] = out[b], out[a]
        return tuple(out)

    # Lower bound of the moves still needed, hands and feet counted apart (a
    # move changes one limb). A move raises the top limb of its kind by at most
    # its own displacement d (a free limb counts from the other limb of its
    # pair) and costs at least mult * (base + dist * (d / max_hh)^2). To climb
    # g * max_hh in moves of at most x_max * max_hh, m equal moves are the
    # cheapest: mult * (m * base + dist * g^2 / m). Hands must reach the finish;
    # as one foot is always on a hold, the top foot must reach finish - max_hf.
    def climb_bound(gap: float, x_max: float, mult: float) -> float:
        g = gap / max_hh
        m_min = max(1, math.ceil(g / x_max))
        m_opt = g * math.sqrt(w.dist / w.base)
        ms = {m_min, max(m_min, math.floor(m_opt)), max(m_min, math.ceil(m_opt))}
        return mult * min(m * w.base + w.dist * g * g / m for m in ms)

    hand_x_max = 2.0
    foot_x_max = 2.0 * max(max_hf, max_ff) / max_hh

    def heuristic(state: tuple[int, ...]) -> float:
        if not use_heuristic:
            return 0.0
        hands = [ys[s] for s in state[:2] if s >= 0]
        if not hands:
            return 0.0
        h = 0.0
        if finish_top > max(hands):
            h = climb_bound(finish_top - max(hands), hand_x_max, angle_factor)
        if avail_feet:
            feet = [ys[state[f]] for f in avail_feet if state[f] >= 0]
            if not feet:  # only the start has no foot on a hold: one move at least
                h += w.base * w.foot
            elif finish_top - max_hf > max(feet):
                h += climb_bound(finish_top - max_hf - max(feet), foot_x_max, w.foot)
        return h

    # Move cost parts that depend on the holds only, computed once.
    dist_cost = [[w.base + w.dist * (d / max_hh) ** 2 for d in row] for row in dist]
    hold_hand = [
        HOLD_COST[h.type][0]
        + (SMALL_HOLD_HAND_COST if h.area_cm2 < SMALL_HOLD_CM2 else 0.0)
        for h in holds
    ]
    hold_foot = [HOLD_COST[h.type][1] for h in holds]
    n_hurt = {k: INJURED_PENALTY if LIMBS[k] in body.injured else 0.0 for k in avail}

    def move_cost(k: int, old: int, new: int, state: tuple[int, ...]) -> float:
        is_hand = k in HAND_IDX
        extra = n_hurt[k]
        extra += DANGLING_FOOT_COST * sum(1 for f in avail_feet if state[f] < 0)
        if new < 0:
            return w.base + FOOT_ADHESION_COST + extra
        if old < 0:  # a free limb is taken as hanging at the other limb of its pair
            old = state[(1 - k) if is_hand else (5 - k)]
            if old < 0:
                old = new
        if is_hand:
            return (dist_cost[old][new] + hold_hand[new]) * angle_factor + extra
        return (dist_cost[old][new] + hold_foot[new]) * w.foot + extra

    def successors(state: tuple[int, ...]):
        for k in avail:
            is_hand = k in HAND_IDX
            if is_hand and avail_feet and all(state[f] < 0 for f in avail_feet):
                continue  # from the start, the feet go first: no climbing with both in the air
            cands = can_hand if is_hand else can_foot
            for j in avail:
                if j != k and state[j] >= 0:
                    cands = (
                        cands
                        & (
                            near_hh
                            if is_hand and j in HAND_IDX
                            else near_ff
                            if not is_hand and j in FOOT_IDX
                            else near_hf
                        )[state[j]]
                    )
            feet_ys = [ys[state[f]] for f in avail_feet if f != k and state[f] >= 0]
            hand_ys = [ys[state[h]] for h in avail_hands if h != k and state[h] >= 0]
            for t in sorted(cands):
                if t == state[k]:
                    continue
                if is_hand:  # feet may not end up above both hands
                    if feet_ys and max(feet_ys) > max([ys[t], *hand_ys]):
                        continue
                elif t in state[2:] or (hand_ys and ys[t] > max(hand_ys)):
                    continue  # two feet never share a hold
                new = state[:k] + (t,) + state[k + 1 :]
                yield k, new, move_cost(k, state[k], t, new)
            # A foot may leave its hold (adhesion) only if the other one stays on a hold.
            if (
                not is_hand
                and state[k] >= 0
                and any(state[f] >= 0 for f in avail_feet if f != k)
            ):
                new = state[:k] + (-1,) + state[k + 1 :]
                yield k, new, move_cost(k, state[k], -1, new)

    counter = itertools.count()
    heap: list = []
    best_g: dict[tuple[int, ...], float] = {}
    actual: dict[tuple[int, ...], tuple[int, ...]] = {}
    parent: dict[tuple[int, ...], tuple[tuple[int, ...] | None, int | None]] = {}
    for st in sorted(starts):
        key = canon(st)
        if key in best_g:
            continue
        best_g[key], actual[key], parent[key] = 0.0, st, (None, None)
        h = heuristic(st)
        heapq.heappush(heap, (h, h, next(counter), 0.0, key))
    closed: set[tuple[int, ...]] = set()
    reached: set[int] = set()  # hand holds reached by an expanded state
    expansions = 0
    goal = None
    while heap:
        _, _, _, g, key = heapq.heappop(heap)
        if key in closed:
            continue
        state = actual[key]
        if is_goal(state):
            goal = key
            break
        closed.add(key)
        expansions += 1
        reached.update(s for s in state[:2] if s >= 0)
        if expansions > MAX_EXPANSIONS:
            break
        for k, new, c in successors(state):
            nkey = canon(new)
            ng = g + c
            if nkey in closed or ng >= best_g.get(nkey, math.inf):
                continue
            best_g[nkey], actual[nkey], parent[nkey] = ng, new, (key, k)
            h = heuristic(new)
            heapq.heappush(heap, (ng + h, h, next(counter), ng, nkey))

    if stats is not None:
        stats["expansions"] = expansions
    if goal is None:
        top = max(reached, key=lambda i: (ys[i], ids[i]))
        beyond = [i for i in range(n) if holds[i].hand and i not in reached]
        gap = min(beyond, key=lambda i: (dist[top][i], ids[i]), default=top)
        why = "search limit reached" if expansions > MAX_EXPANSIONS else "no passage"
        raise NoBetaError(
            f"no beta ({why}): cannot get from {ids[top]} to {ids[gap]} "
            f"({dist[top][gap]:.0f} cm); finish holds {sorted(finish_marks)}",
            (ids[top], ids[gap]),
        )

    path: list[Step] = []
    cur: tuple[int, ...] | None = goal
    while cur is not None:
        prev, k = parent[cur]
        holds_by_limb = {
            LIMBS[j]: (ids[s] if s >= 0 else None) for j, s in enumerate(actual[cur])
        }
        path.append(Step(holds_by_limb, None if k is None else LIMBS[k]))
        cur = prev
    return path[::-1], best_g[goal]


def find_beta(
    holds: list[Hold],
    body: Body,
    preference: BetaPreference = BetaPreference.EASY,
    wall_angle_deg: float | None = None,
) -> list[Step]:
    """Find the cheapest beta from the start marks to the finish marks.

    Args:
        holds: Usable holds, centres in cm in the wall plane (y up).
        body: Climber measures and limb constraints.
        preference: Cost weights to use.
        wall_angle_deg: 0 vertical, > 0 overhang, < 0 slab; ``None`` is vertical.

    Returns:
        The states from the start (``moved=None``) to the finish; each state
        differs from the previous one by the limb in ``moved``.

    Raises:
        NoBetaError: No beta exists or the search limit was reached.
    """
    return _search(holds, body, preference, wall_angle_deg)[0]
