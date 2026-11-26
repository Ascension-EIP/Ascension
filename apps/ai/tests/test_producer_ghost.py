# @date 2026-11-25
# @file test_producer_ghost.py
# @brief The ghost part of the producer: seed a ghost on a route, publish ghosts.compute.requested.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
from unittest.mock import MagicMock

import pytest

import producer
from shared.models import (
    BetaPreference,
    GhostComputeRequest,
    GhostMorphology,
    RoutingKey,
)


@pytest.fixture
def sent(monkeypatch):
    broker = MagicMock()
    broker.setup_config.return_value.connect.return_value.setup_channel.return_value = broker
    monkeypatch.setattr(producer, "Broker", lambda: broker)
    return broker


def test_producer_ghost_publishes_a_typed_request(sent):
    producer.main(["ghost", "--job-id", "g"])
    sent.publish.assert_called_once_with(RoutingKey.GHOSTS_COMPUTE_REQUESTED, GhostComputeRequest(job_id="g"))
    sent.connection.close.assert_called_once()


def test_producer_ghost_carries_the_preference(sent):
    producer.main(["ghost", "--job-id", "g", "--preference", "power"])
    sent.publish.assert_called_once_with(
        RoutingKey.GHOSTS_COMPUTE_REQUESTED, GhostComputeRequest(job_id="g", preference=BetaPreference.POWER)
    )


def test_seed_ghost_inserts_a_pending_ghost_on_the_user_of_the_route():
    db = MagicMock()
    db.connection.execute.return_value.fetchone.side_effect = [("user-id",), ("ghost-id",)]
    seeded = producer.seed_ghost("route-id", GhostMorphology(height_cm=180, arm_span_cm=183), db)
    assert seeded == producer.SeededGhost("ghost-id", "user-id")
    select, insert = (c.args for c in db.connection.execute.call_args_list)
    assert "FROM routes" in select[0] and select[1] == ("route-id",)
    assert insert[0].startswith("INSERT INTO ghosts") and insert[1][:2] == ("route-id", "user-id")
    assert json.loads(insert[1][2]) == {"height_cm": 180.0, "arm_span_cm": 183.0}


def test_seed_ghost_on_an_unknown_route_fails():
    db = MagicMock()
    db.connection.execute.return_value.fetchone.return_value = None
    with pytest.raises(ValueError, match="route"):
        producer.seed_ghost("nope", db=db)


def test_producer_seed_ghost_prints_the_ghost_id(monkeypatch, capsys):
    monkeypatch.setattr(producer, "seed_ghost", lambda route_id, morphology=None, db=None: producer.SeededGhost("ghost-id", "user-id"))
    producer.main(["seed-ghost", "--route-id", "r", "--height", "170"])
    assert "ghost_id=ghost-id" in capsys.readouterr().out
