# @date 2026-11-25
# @file test_pathfinding_wall.py
# @brief Tests of the wall geometry (pathfinding step C1) on synthetic planes seen by a known camera.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import cv2
import numpy as np
import pytest

from worker._4_pathfinding import _0_wall as wall

W, H, FOCAL = 640, 480, 800.0
CX, CY = W / 2, H / 2
DISTANCE_M = 3.0


def _rot_x(deg: float) -> np.ndarray:
    a = np.radians(deg)
    c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def make_scene(angle_deg: float, pitch_deg: float):
    """Plane seen by a camera tilted by `pitch_deg`; returns (normal, offset, gravity, depth).

    World frame: X right, Y up, Z towards the climber; the wall is vertical at Z = -3 m for
    `angle_deg` = 0 and leans over the climber for `angle_deg` > 0. The camera looks at -Z.
    """
    a = np.radians(angle_deg)
    to_cam = _rot_x(pitch_deg) @ np.diag([1.0, -1.0, -1.0])
    normal = to_cam @ np.array([0.0, -np.sin(a), np.cos(a)])
    gravity = to_cam @ np.array([0.0, -1.0, 0.0])
    point = to_cam @ np.array([0.0, 0.0, -DISTANCE_M])
    offset = -float(normal @ point)
    u, v = np.meshgrid(np.arange(W), np.arange(H))
    rays = np.stack([(u - CX) / FOCAL, (v - CY) / FOCAL, np.ones((H, W))], axis=-1)
    depth = -offset / (rays @ normal)
    assert (depth > 0).all()
    return normal, offset, gravity, depth


def angle_between_deg(a: np.ndarray, b: np.ndarray) -> float:
    cos = float(a @ b) / (np.linalg.norm(a) * np.linalg.norm(b))
    return float(np.degrees(np.arccos(np.clip(cos, -1.0, 1.0))))


def test_unproject_places_points_in_camera_frame():
    depth = np.full((4, 6), 2.0)
    points = wall.unproject(depth, focal_px=10.0)
    assert points.shape == (4, 6, 3)
    assert np.allclose(points[..., 2], 2.0)
    # Default optical centre is the image centre: pixel (3, 2) of a 6x4 image is on the axis.
    assert np.allclose(points[2, 3], [0.0, 0.0, 2.0])
    # One pixel to the right and below: x = 1 / 10 * 2, y likewise.
    assert np.allclose(points[3, 4], [0.2, 0.2, 2.0])


def test_unproject_explicit_centre():
    points = wall.unproject(np.full((4, 6), 1.0), focal_px=10.0, cx=0.0, cy=0.0)
    assert np.allclose(points[0, 0], [0.0, 0.0, 1.0])
    assert np.allclose(points[1, 2], [0.2, 0.1, 1.0])


def test_fit_plane_recovers_exact_plane():
    normal, offset, _, depth = make_scene(0.0, 0.0)
    points = wall.unproject(depth, FOCAL, CX, CY)
    n, d, ratio = wall.fit_plane(points, np.ones((H, W), dtype=bool))
    assert angle_between_deg(n, normal) < 0.01
    assert d == pytest.approx(offset, abs=1e-6)
    assert ratio == pytest.approx(1.0)
    assert np.linalg.norm(n) == pytest.approx(1.0)
    assert n[2] < 0  # oriented towards the camera


def test_fit_plane_orients_the_normal_towards_the_camera():
    _, _, _, depth = make_scene(30.0, 10.0)
    _, d, _ = wall.fit_plane(
        wall.unproject(depth, FOCAL, CX, CY), np.ones((H, W), dtype=bool)
    )
    assert d > 0  # n . X + d = 0 with the camera on the positive side


def test_fit_plane_is_deterministic():
    _, _, _, depth = make_scene(-15.0, 20.0)
    rng = np.random.default_rng(1)
    noisy = depth + rng.normal(0, 0.005, depth.shape)
    points = wall.unproject(noisy, FOCAL, CX, CY)
    mask = np.ones((H, W), dtype=bool)
    first = wall.fit_plane(points, mask)
    second = wall.fit_plane(points, mask)
    assert np.array_equal(first[0], second[0]) and first[1:] == second[1:]


def test_fit_plane_ignores_invalid_points():
    normal, _, _, depth = make_scene(0.0, 0.0)
    points = wall.unproject(depth, FOCAL, CX, CY)
    valid = np.ones((H, W), dtype=bool)
    valid[:, : W // 2] = False
    points[:, : W // 2] = 1e3  # garbage under the invalid mask
    n, _, ratio = wall.fit_plane(points, valid)
    assert angle_between_deg(n, normal) < 0.01
    assert ratio == pytest.approx(1.0)


@pytest.mark.parametrize("angle", [-15.0, 0.0, 30.0])
@pytest.mark.parametrize("pitch", [0.0, 20.0])
def test_wall_angle_deg_matches_the_scene(angle, pitch):
    normal, _, gravity, _ = make_scene(angle, pitch)
    assert wall.wall_angle_deg(normal, gravity) == pytest.approx(angle, abs=1e-6)


def test_wall_angle_deg_without_gravity_is_none():
    assert wall.wall_angle_deg(np.array([0.0, 0.0, -1.0]), None) is None


def test_wall_angle_deg_ignores_gravity_norm():
    normal, _, gravity, _ = make_scene(30.0, 0.0)
    assert wall.wall_angle_deg(normal, 9.81 * gravity) == pytest.approx(30.0, abs=1e-6)


@pytest.mark.parametrize("gravity_known", [True, False])
def test_wall_frame_is_orthonormal_in_the_plane(gravity_known):
    normal, offset, gravity, _ = make_scene(30.0, 20.0)
    origin, u, v = wall.wall_frame(
        normal, offset, gravity if gravity_known else None, FOCAL, CX, CY
    )
    assert normal @ origin + offset == pytest.approx(0.0, abs=1e-9)
    assert np.linalg.norm(u) == pytest.approx(1.0) and np.linalg.norm(
        v
    ) == pytest.approx(1.0)
    assert u @ v == pytest.approx(0.0, abs=1e-9)
    assert u @ normal == pytest.approx(0.0, abs=1e-9) and v @ normal == pytest.approx(
        0.0, abs=1e-9
    )
    # The origin lies on the optical axis.
    assert origin[0] == pytest.approx(0.0, abs=1e-9) and origin[1] == pytest.approx(
        0.0, abs=1e-9
    )
    assert u[0] > 0  # u goes to the right of the image


def test_wall_frame_up_is_opposite_to_gravity():
    normal, offset, gravity, _ = make_scene(30.0, 20.0)
    _, _, v = wall.wall_frame(normal, offset, gravity, FOCAL, CX, CY)
    assert v @ gravity < 0
    # With gravity, u is horizontal: no component along gravity.
    _, u, _ = wall.wall_frame(normal, offset, gravity, FOCAL, CX, CY)
    assert u @ gravity == pytest.approx(0.0, abs=1e-9)


def test_wall_frame_without_gravity_uses_the_image_up():
    normal, offset, _, _ = make_scene(0.0, 0.0)  # camera facing the wall
    _, u, v = wall.wall_frame(normal, offset, None, FOCAL, CX, CY)
    assert np.allclose(v, [0.0, -1.0, 0.0], atol=1e-9)
    assert np.allclose(u, [1.0, 0.0, 0.0], atol=1e-9)


def test_wall_frame_rejects_gravity_along_the_normal():
    normal, offset, _, _ = make_scene(0.0, 0.0)
    with pytest.raises(ValueError):
        wall.wall_frame(normal, offset, -normal, FOCAL, CX, CY)


def _true_cm(depth, p0, p1):
    """Distance in cm between two pixels, from the true 3D points."""
    pts = wall.unproject(depth, FOCAL, CX, CY)
    return 100 * np.linalg.norm(pts[p0[1], p0[0]] - pts[p1[1], p1[0]])


@pytest.mark.parametrize(
    "angle, pitch", [(-15.0, 20.0), (0.0, 0.0), (30.0, 20.0), (0.0, 20.0)]
)
def test_homography_preserves_distances_on_the_wall(angle, pitch):
    normal, offset, gravity, depth = make_scene(angle, pitch)
    homography = wall.image_to_wall_homography(normal, offset, gravity, FOCAL, CX, CY)
    assert homography.shape == (3, 3)
    pairs = [
        ((10, 20), (600, 30)),
        ((100, 400), (120, 40)),
        ((320, 240), (500, 300)),
        ((5, 5), (630, 470)),
    ]
    for p0, p1 in pairs:
        cm = wall.to_wall(homography, np.array([p0, p1], dtype=float))
        assert np.linalg.norm(cm[0] - cm[1]) == pytest.approx(
            _true_cm(depth, p0, p1), rel=1e-6
        )


def test_homography_centre_pixel_is_the_origin():
    normal, offset, gravity, _ = make_scene(30.0, 20.0)
    homography = wall.image_to_wall_homography(normal, offset, gravity, FOCAL, CX, CY)
    assert np.allclose(wall.to_wall(homography, np.array([[CX, CY]])), 0.0, atol=1e-9)


def test_homography_higher_pixel_is_higher_on_the_wall():
    normal, offset, gravity, _ = make_scene(30.0, 20.0)
    homography = wall.image_to_wall_homography(normal, offset, gravity, FOCAL, CX, CY)
    low, high = wall.to_wall(homography, np.array([[300.0, 400.0], [300.0, 100.0]]))
    assert high[1] > low[1]
    right = wall.to_wall(homography, np.array([[500.0, 240.0]]))[0]
    assert right[0] > 0


def test_to_image_inverts_to_wall():
    normal, offset, gravity, _ = make_scene(30.0, 20.0)
    homography = wall.image_to_wall_homography(normal, offset, gravity, FOCAL, CX, CY)
    pixels = np.array([[10.0, 20.0], [320.5, 240.25], [600.0, 470.0]])
    back = wall.to_image(homography, wall.to_wall(homography, pixels))
    assert np.allclose(back, pixels, atol=1e-6)


NOISE_M = 0.005


def make_holds(normal, offset, depth, seed=3, count=18):
    """Adds flat-topped holds (5 to 15 cm proud of the wall) to `depth`; returns (depth, polygons)."""
    rng = np.random.default_rng(seed)
    u, v = np.meshgrid(np.arange(W), np.arange(H))
    rays = np.stack([(u - CX) / FOCAL, (v - CY) / FOCAL, np.ones((H, W))], axis=-1)
    out = depth.copy()
    polygons = []
    for _ in range(count):
        centre = rng.uniform([60, 60], [W - 60, H - 60])
        radius = rng.uniform(25, 40)
        proud = rng.uniform(0.05, 0.15)
        inside = (u - centre[0]) ** 2 + (v - centre[1]) ** 2 < radius**2
        out[inside] = ((proud - offset) / (rays @ normal))[inside]
        angles = np.linspace(0, 2 * np.pi, 24, endpoint=False)
        polygons.append(
            centre + (radius + 3) * np.column_stack([np.cos(angles), np.sin(angles)])
        )
    return out, polygons


def outside(polygons):
    """Boolean mask of the pixels outside the polygons."""
    mask = np.ones((H, W), dtype=np.uint8)
    cv2.fillPoly(mask, [p.round().astype(np.int32) for p in polygons], 0)
    return mask.astype(bool)


def noisy_scene(angle, pitch, holds=True):
    normal, offset, gravity, depth = make_scene(angle, pitch)
    truth = depth
    polygons = []
    if holds:
        depth, polygons = make_holds(normal, offset, depth)
    depth = depth + np.random.default_rng(7).normal(0, NOISE_M, depth.shape)
    return normal, gravity, truth, depth, polygons


SCENES = [(-15.0, 20.0), (0.0, 0.0), (30.0, 20.0), (0.0, 20.0)]


@pytest.mark.parametrize("angle, pitch", SCENES)
def test_estimate_wall_recovers_angle_and_distances(angle, pitch):
    _, gravity, truth, depth, polygons = noisy_scene(angle, pitch)
    plane = wall.estimate_wall(
        depth, FOCAL, polygons, gravity=list(gravity), model="test"
    )
    assert plane.angle_deg == pytest.approx(angle, abs=1.0)
    assert plane.focal_px == FOCAL and plane.model == "test"
    assert 0.9 < plane.inlier_ratio <= 1.0
    homography = np.array(plane.homography)
    pairs = [
        ((10, 20), (600, 30)),
        ((100, 400), (120, 40)),
        ((320, 240), (500, 300)),
        ((5, 5), (630, 470)),
    ]
    for p0, p1 in pairs:
        cm = wall.to_wall(homography, np.array([p0, p1], dtype=float))
        assert np.linalg.norm(cm[0] - cm[1]) == pytest.approx(
            _true_cm(truth, p0, p1), rel=0.01
        )


def test_estimate_wall_normal_is_within_one_degree():
    normal, _, _, depth, polygons = noisy_scene(30.0, 20.0)
    points = wall.unproject(depth, FOCAL)
    n, _, _ = wall.fit_plane(points, outside(polygons))
    assert angle_between_deg(n, normal) < 1.0


def test_estimate_wall_without_gravity_has_no_angle():
    _, _, _, depth, polygons = noisy_scene(0.0, 0.0)
    plane = wall.estimate_wall(depth, FOCAL, polygons)
    assert plane.angle_deg is None
    assert plane.model == ""
    assert np.array(plane.homography).shape == (3, 3)


def _with_volume(normal, offset, depth):
    """Adds a large tilted volume face over the right 55 % of the image; returns (depth, polygon)."""
    tilt = np.radians(25)
    rot_y = np.array(
        [[np.cos(tilt), 0, np.sin(tilt)], [0, 1, 0], [-np.sin(tilt), 0, np.cos(tilt)]]
    )
    normal2 = rot_y @ normal
    u, v = np.meshgrid(np.arange(W), np.arange(H))
    rays = np.stack([(u - CX) / FOCAL, (v - CY) / FOCAL, np.ones((H, W))], axis=-1)
    edge = rays[H // 2, int(0.45 * W)] * (
        -offset / (rays[H // 2, int(0.45 * W)] @ normal)
    )
    offset2 = -float(normal2 @ edge)
    out = depth.copy()
    region = u >= int(0.45 * W)
    out[region] = (-offset2 / (rays @ normal2))[region]
    polygon = np.array([[0.45 * W - 2, 0], [W, 0], [W, H], [0.45 * W - 2, H]])
    return out, [polygon]


def test_estimate_wall_holds_do_not_move_the_plane():
    # The big tilted volume outweighs the wall: only the polygon keeps RANSAC on the wall.
    normal, _, gravity, depth = make_scene(30.0, 20.0)
    depth, polygons = _with_volume(normal, make_scene(30.0, 20.0)[1], depth)
    points = wall.unproject(depth, FOCAL)
    unmasked = angle_between_deg(
        wall.fit_plane(points, np.ones((H, W), dtype=bool))[0], normal
    )
    masked = angle_between_deg(wall.fit_plane(points, outside(polygons))[0], normal)
    assert masked < 1.0
    assert unmasked > 5.0
    plane = wall.estimate_wall(depth, FOCAL, polygons, gravity=list(gravity))
    assert plane.angle_deg == pytest.approx(30.0, abs=1.0)


def test_estimate_wall_is_deterministic():
    _, gravity, _, depth, polygons = noisy_scene(30.0, 20.0)
    first = wall.estimate_wall(depth, FOCAL, polygons, gravity=list(gravity))
    second = wall.estimate_wall(depth, FOCAL, polygons, gravity=list(gravity))
    assert first == second


def test_estimate_wall_higher_hold_has_larger_y():
    _, gravity, _, depth, polygons = noisy_scene(30.0, 20.0)
    plane = wall.estimate_wall(depth, FOCAL, polygons, gravity=list(gravity))
    low, high = wall.to_wall(
        np.array(plane.homography), np.array([[320.0, 420.0], [320.0, 60.0]])
    )
    assert high[1] > low[1]


def test_estimate_wall_rejects_too_few_valid_points():
    depth = np.zeros((H, W))
    depth[:5, :5] = 3.0
    with pytest.raises(ValueError, match="valid"):
        wall.estimate_wall(depth, FOCAL, [])


def test_estimate_wall_rejects_when_holds_cover_the_image():
    _, _, _, depth, _ = noisy_scene(0.0, 0.0, holds=False)
    everything = [np.array([[0, 0], [W, 0], [W, H], [0, H]], dtype=float)]
    with pytest.raises(ValueError, match="valid"):
        wall.estimate_wall(depth, FOCAL, everything)


def test_estimate_wall_rejects_a_non_planar_scene():
    rng = np.random.default_rng(0)
    depth = rng.uniform(1.0, 5.0, (H, W))
    with pytest.raises(ValueError, match="inlier"):
        wall.estimate_wall(depth, FOCAL, [])


@pytest.mark.parametrize(
    "gravity",
    [[0.0, 1.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, float("nan"), 1.0]],
)
def test_estimate_wall_rejects_a_bad_gravity(gravity):
    _, _, _, depth, polygons = noisy_scene(0.0, 0.0)
    with pytest.raises(ValueError, match="gravity"):
        wall.estimate_wall(depth, FOCAL, polygons, gravity=gravity)


def test_estimate_wall_homography_is_3x3_python_lists():
    _, gravity, _, depth, polygons = noisy_scene(0.0, 0.0)
    plane = wall.estimate_wall(depth, FOCAL, polygons, gravity=list(gravity))
    assert len(plane.homography) == 3 and all(len(row) == 3 for row in plane.homography)
    assert all(isinstance(x, float) for row in plane.homography for x in row)


# --- Calibration on a real photo: noise proportional to the depth, floor and ceiling in view ---


def make_gym_scene(distance_m: float, noise_rel: float = 0.01, seed: int = 11):
    """A wall facing the camera, with a ceiling and a floor filling ~44 % of the image.

    Returns (depth, gravity). The noise is Gaussian with a standard deviation of `noise_rel` times
    the depth, like a monocular metric model.
    """
    _, v = np.meshgrid(np.arange(W), np.arange(H))
    ray_y = (v - CY) / FOCAL
    ray_y = np.where(ray_y == 0, 1e-9, ray_y)
    plane_y = distance_m / 6  # floor and ceiling at +-plane_y from the camera
    depth = np.full((H, W), distance_m)
    to_plane = plane_y / np.abs(ray_y)
    depth = np.minimum(depth, to_plane)
    noise = np.random.default_rng(seed).normal(0, noise_rel, depth.shape) * depth
    return depth + noise, [0.0, 1.0, 0.0]


def test_make_gym_scene_has_about_forty_percent_of_floor_and_ceiling():
    depth, _ = make_gym_scene(4.5, noise_rel=0.0)
    assert 0.38 < (depth < 4.5 - 1e-6).mean() < 0.46


@pytest.mark.parametrize("distance_m", [3.0, 4.5, 9.0])
def test_estimate_wall_accepts_a_wall_with_proportional_noise_and_floor_and_ceiling(
    distance_m,
):
    depth, gravity = make_gym_scene(distance_m)
    plane = wall.estimate_wall(depth, FOCAL, [], gravity=gravity)
    assert plane.angle_deg == pytest.approx(0.0, abs=2.0)
    homography = np.array(plane.homography)
    # 640 px at the wall are 640 / FOCAL * distance metres wide, whatever the noise.
    left, right = wall.to_wall(homography, np.array([[0.0, CY], [W, CY]]))
    assert np.linalg.norm(right - left) == pytest.approx(
        100 * W / FOCAL * distance_m, rel=0.03
    )


def test_fit_plane_normal_is_within_two_degrees_with_proportional_noise():
    depth, _ = make_gym_scene(4.5)
    points = wall.unproject(depth, FOCAL, CX, CY)
    normal, offset, ratio = wall.fit_plane(points, np.ones((H, W), dtype=bool))
    assert angle_between_deg(normal, np.array([0.0, 0.0, -1.0])) < 2.0
    assert offset == pytest.approx(4.5, rel=0.02)
    assert 0.35 < ratio < 0.56  # ~56 % of the points are wall, ~77 % of them within 1.2 %


def test_ransac_threshold_scales_with_the_depth_and_has_a_floor():
    assert wall.ransac_threshold_m(4.5) == pytest.approx(4.5 * wall.RANSAC_REL_THRESHOLD)
    assert wall.ransac_threshold_m(9.0) == pytest.approx(2 * wall.ransac_threshold_m(4.5))
    assert wall.ransac_threshold_m(0.1) == wall.RANSAC_MIN_THRESHOLD_M


def test_estimate_wall_rejects_a_small_planar_patch_in_a_chaotic_scene():
    rng = np.random.default_rng(0)
    depth = rng.uniform(1.0, 5.0, (H, W))
    depth[: H // 3, : W // 3] = 3.0  # 11 % of the image is a clean plane
    with pytest.raises(ValueError, match="inlier"):
        wall.estimate_wall(depth, FOCAL, [])
