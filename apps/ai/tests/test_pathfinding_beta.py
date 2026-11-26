# @date 2026-11-25
# @file test_pathfinding_beta.py
# @brief Tests of the pathfinding beta search (A* over the four-limb states).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import functools
import itertools
import time

import pytest

from common.utils.errors import PermanentError
from shared.models import (
    BetaPreference,
    BodyConstraint,
    BodyZone,
    ClimberMorphology,
    ConstraintType,
    HoldType,
    Limb,
)
from worker._4_pathfinding._2_beta import (
    MAX_FOOT_FOOT_RATIO,
    MAX_HAND_FOOT_RATIO,
    MAX_HAND_HAND_RATIO,
    Body,
    Hold,
    NoBetaError,
    Step,
    _search,
    body_from_morphology,
    find_beta,
)

LH, RH, LF, RF = Limb.LEFT_HAND, Limb.RIGHT_HAND, Limb.LEFT_FOOT, Limb.RIGHT_FOOT
HANDS = (LH, RH)
FEET = (LF, RF)


def body(height=175.0, **kw) -> Body:
    return Body(
        height_cm=height,
        arm_span_cm=kw.pop("arm_span_cm", height),
        missing=frozenset(kw.pop("missing", ())),
        injured=frozenset(kw.pop("injured", ())),
    )


def ladder(n=11, step=40.0, x=0.0) -> list[Hold]:
    holds = [Hold(f"P{i}", x, i * step, 100.0, HoldType.UNKNOWN) for i in range(n)]
    return holds


def with_marks(holds, start=None, finish=None) -> list[Hold]:
    out = []
    for h in holds:
        out.append(
            Hold(
                h.id, h.x, h.y, h.area_cm2, h.type,
                start_limbs=(start or {}).get(h.id),
                finish_limbs=(finish or {}).get(h.id),
                hand=h.hand, foot=h.foot,
            )
        )  # fmt: skip
    return out


def hand_y(step: Step, by_id) -> float:
    return max(by_id[step.holds[h]].y for h in HANDS if step.holds[h])


def n_moves(steps) -> int:
    return len(steps) - 1


def n_hand_moves(steps) -> int:
    return sum(1 for s in steps[1:] if s.moved in HANDS)


# --- types and body -------------------------------------------------------


def test_no_beta_error_is_a_permanent_error():
    err = NoBetaError("nope", ("A", "B"))
    assert isinstance(err, PermanentError)
    assert err.hold_ids == ("A", "B")


def test_body_from_morphology_maps_zones_to_limbs():
    m = ClimberMorphology(
        height_cm=170,
        constraints=[
            BodyConstraint(type=ConstraintType.MISSING, zone=BodyZone.LEFT_FOREARM),
            BodyConstraint(type=ConstraintType.INJURED, zone=BodyZone.RIGHT_KNEE),
            BodyConstraint(type=ConstraintType.INJURED, zone=BodyZone.HEAD),
            BodyConstraint(type=ConstraintType.INJURED, zone=BodyZone.LOWER_BACK),
        ],
    )
    b = body_from_morphology(m)
    assert b.height_cm == 170
    assert b.arm_span_cm == 170  # defaults to the height
    assert b.missing == {LH}
    assert b.injured == {RF}


def test_body_from_morphology_keeps_arm_span_and_missing_wins_over_injured():
    m = ClimberMorphology(
        height_cm=170,
        arm_span_cm=178,
        constraints=[
            BodyConstraint(type=ConstraintType.INJURED, zone=BodyZone.RIGHT_HAND),
            BodyConstraint(type=ConstraintType.MISSING, zone=BodyZone.RIGHT_SHOULDER),
        ],
    )
    b = body_from_morphology(m)
    assert b.arm_span_cm == 178
    assert b.missing == {RH}
    assert b.injured == frozenset()


# --- basic search ---------------------------------------------------------


def test_ladder_beta_moves_one_limb_at_a_time():
    holds = ladder()
    by_id = {h.id: h for h in holds}
    steps = find_beta(holds, body(175))
    assert steps[0].moved is None
    best = hand_y(steps[0], by_id)
    for prev, cur in itertools.pairwise(steps):
        changed = [limb for limb in Limb if prev.holds[limb] != cur.holds[limb]]
        assert changed == [cur.moved]
        y = hand_y(cur, by_id)
        assert y >= best - 40.0 - 1e-6
        best = max(best, y)
    assert hand_y(steps[-1], by_id) == 400.0


def test_default_marks_start_and_finish_on_lowest_and_highest():
    steps = find_beta(ladder(), body(175))
    assert steps[0].holds[LH] == steps[0].holds[RH] == "P0"
    assert steps[-1].holds[LH] == steps[-1].holds[RH] == "P10"


def test_start_two_arrows_on_one_hold():
    holds = with_marks(ladder(), start={"P2": 2}, finish={"P10": 2})
    steps = find_beta(holds, body(175))
    assert steps[0].moved is None
    assert steps[0].holds[LH] == steps[0].holds[RH] == "P2"


def test_start_with_three_marks_is_two_hands_and_one_foot():
    holds = with_marks(ladder(), start={"P1": 2, "P0": 1}, finish={"P10": 2})
    s0 = find_beta(holds, body(175))[0]
    assert s0.holds[LH] in ("P0", "P1") and s0.holds[RH] in ("P0", "P1")
    feet = [s0.holds[LF], s0.holds[RF]]
    assert sorted(f is not None for f in feet) == [False, True]
    assert next(f for f in feet if f) in ("P0", "P1")
    placed = [s0.holds[limb] for limb in Limb if s0.holds[limb]]
    assert sorted(placed) == ["P0", "P1", "P1"] or sorted(placed) == ["P0", "P0", "P1"]


def test_finish_with_two_hands_on_the_finish_hold():
    holds = with_marks(ladder(), finish={"P9": 2})
    last = find_beta(holds, body(175))[-1]
    assert last.holds[LH] == last.holds[RH] == "P9"


def test_gap_raises_no_beta_error_naming_the_holds_around_the_gap():
    holds = [
        Hold("A", 0, 0, 100, HoldType.UNKNOWN),
        Hold("B", 0, 40, 100, HoldType.UNKNOWN),
        Hold("C", 0, 80, 100, HoldType.UNKNOWN),
        Hold("D", 0, 330, 100, HoldType.UNKNOWN),  # 2.5 m above C
        Hold("E", 0, 370, 100, HoldType.UNKNOWN),
    ]
    with pytest.raises(NoBetaError) as exc:
        find_beta(holds, body(175))
    assert "C" in str(exc.value) and "D" in str(exc.value)
    assert set(exc.value.hold_ids) >= {"C", "D"}
    assert isinstance(exc.value, PermanentError)


# --- body adaptation ------------------------------------------------------


def test_tall_climber_finds_a_route_that_blocks_a_short_one():
    holds = ladder(n=5, step=135.0)
    assert find_beta(holds, body(195))[-1].holds[LH] == "P4"
    with pytest.raises(NoBetaError):
        find_beta(holds, body(155))


def test_shorter_climber_needs_more_moves_on_the_same_route():
    holds = ladder(n=9, step=60.0)
    assert n_moves(find_beta(holds, body(155))) >= n_moves(find_beta(holds, body(195)))


def test_missing_left_hand_stays_empty_and_a_beta_is_found():
    holds = ladder()
    steps = find_beta(holds, body(175, missing={LH}))
    assert all(s.holds[LH] is None for s in steps)
    assert steps[-1].holds[RH] == "P10"
    assert steps[0].holds[RH] == "P0"


def test_missing_foot_is_never_used():
    steps = find_beta(ladder(), body(175, missing={RF}))
    assert all(s.holds[RF] is None for s in steps)
    assert any(s.holds[LF] for s in steps)


def test_injured_right_foot_moves_less_than_a_healthy_one():
    holds = ladder(n=9, step=60.0)

    def right_foot_moves(b):
        return sum(1 for s in find_beta(holds, b)[1:] if s.moved == RF)

    healthy = right_foot_moves(body(175))
    hurt = right_foot_moves(body(175, injured={RF}))
    assert healthy > 0
    assert hurt < healthy


def test_foot_only_holds_are_never_used_by_a_hand():
    holds = [
        Hold(f"P{i}", 0, i * 40, 100, HoldType.UNKNOWN, foot=False) for i in range(11)
    ]
    holds += [
        Hold(f"F{i}", 5, i * 40 - 20, 100, HoldType.UNKNOWN, hand=False)
        for i in range(11)
    ]
    for pref in BetaPreference:
        steps = find_beta(holds, body(175), pref)
        used = {s.holds[h] for s in steps for h in HANDS}
        assert not any(i and i.startswith("F") for i in used)
        feet = {s.holds[f] for s in steps for f in FEET} - {None}
        assert feet and all(f.startswith("F") for f in feet)


# --- preferences, determinism, performance --------------------------------


def test_power_never_needs_more_moves_than_technique():
    for holds in (ladder(), ladder(n=9, step=60.0), ladder(n=6, step=80.0)):
        power = find_beta(holds, body(175), BetaPreference.POWER)
        technique = find_beta(holds, body(175), BetaPreference.TECHNIQUE)
        assert n_moves(power) <= n_moves(technique)


def test_power_needs_strictly_fewer_moves_on_a_dense_ladder():
    holds = ladder(n=21, step=20.0)
    power = find_beta(holds, body(175), BetaPreference.POWER)
    technique = find_beta(holds, body(175), BetaPreference.TECHNIQUE)
    assert n_moves(power) < n_moves(technique)


def test_technique_places_the_feet_more_often_than_power():
    holds = ladder(n=21, step=20.0)

    def foot_moves(pref):
        return sum(1 for s in find_beta(holds, body(175), pref)[1:] if s.moved in FEET)

    assert foot_moves(BetaPreference.TECHNIQUE) > foot_moves(BetaPreference.POWER)


def test_find_beta_is_deterministic():
    holds = ladder(n=9, step=60.0)
    assert find_beta(holds, body(175)) == find_beta(holds, body(175))


def test_overhang_does_not_change_feasibility_and_costs_more_for_hands():
    holds = ladder(n=9, step=60.0)
    vertical = find_beta(holds, body(175), wall_angle_deg=None)
    steep = find_beta(holds, body(175), wall_angle_deg=40.0)
    assert vertical[-1].holds[LH] == steep[-1].holds[LH] == "P8"
    assert n_hand_moves(steep) <= n_hand_moves(vertical)


def test_thirty_hand_holds_and_thirty_foot_holds_resolve_under_two_seconds():
    holds = [
        Hold(f"H{i}", 20.0 * (i % 3), i * 25.0, 80.0, HoldType.UNKNOWN)
        for i in range(30)
    ]
    holds += [
        Hold(
            f"F{i}",
            20.0 * (i % 3) - 30.0,
            i * 25.0 + 12.0,
            30.0,
            HoldType.FOOTHOLD,
            hand=False,
        )
        for i in range(30)
    ]
    t0 = time.perf_counter()
    steps = find_beta(holds, body(175))
    elapsed = time.perf_counter() - t0
    print(f"perf: {elapsed:.3f}s, {n_moves(steps)} moves")
    assert steps[-1].holds[LH] == steps[-1].holds[RH] == "H29"
    assert elapsed < 2.0


def test_heuristic_is_admissible_same_cost_as_dijkstra():
    cases = [
        (ladder(n=9, step=60.0), body(175), BetaPreference.EASY, None),
        (ladder(n=9, step=60.0), body(175), BetaPreference.POWER, 30.0),
        (
            ladder(n=9, step=40.0),
            body(165, injured={RF}),
            BetaPreference.TECHNIQUE,
            None,
        ),
        (ladder(n=7, step=50.0), body(175, missing={LH}), BetaPreference.EASY, None),
    ]
    for holds, b, pref, angle in cases:
        _, a_star = _search(holds, b, pref, angle)
        _, dijkstra = _search(holds, b, pref, angle, use_heuristic=False)
        assert a_star == pytest.approx(dijkstra)


def _gap(placed, a, c) -> float:
    return ((placed[a].x - placed[c].x) ** 2 + (placed[a].y - placed[c].y) ** 2) ** 0.5


def test_every_step_respects_the_reach_constraints():
    b = body(175)
    holds = ladder(n=9, step=60.0)
    by_id = {h.id: h for h in holds}
    for step in find_beta(holds, b):
        placed = {limb: by_id[i] for limb, i in step.holds.items() if i}

        d = functools.partial(_gap, placed)

        assert d(LH, RH) <= MAX_HAND_HAND_RATIO * b.arm_span_cm
        for hand in HANDS:
            for foot in FEET:
                if foot in placed:
                    assert d(hand, foot) <= MAX_HAND_FOOT_RATIO * b.height_cm
        if len(placed) == 4:
            assert d(LF, RF) <= MAX_FOOT_FOOT_RATIO * b.height_cm
        top = max(placed[h].y for h in HANDS)
        assert all(placed[f].y <= top for f in FEET if f in placed)


def test_both_hands_missing_is_an_explicit_failure():
    with pytest.raises(NoBetaError, match="hand"):
        find_beta(ladder(), body(175, missing={LH, RH}))
