CREATE TYPE user_role AS ENUM ('user', 'admin', 'coach', 'gym');
CREATE TYPE user_status AS ENUM ('active', 'deactivated');
CREATE TYPE grading_system AS ENUM ('font', 'french', 'v_scale', 'yds');
CREATE TYPE dominant_hand AS ENUM ('left', 'right', 'ambidextrous');
CREATE TYPE body_zone AS ENUM (
    'head', 'neck', 'torso', 'lower_back',
    'left_shoulder', 'right_shoulder',
    'left_upper_arm', 'right_upper_arm',
    'left_elbow', 'right_elbow',
    'left_forearm', 'right_forearm',
    'left_wrist', 'right_wrist',
    'left_hand', 'right_hand',
    'left_fingers', 'right_fingers',
    'left_hip', 'right_hip',
    'left_thigh', 'right_thigh',
    'left_knee', 'right_knee',
    'left_shin', 'right_shin',
    'left_ankle', 'right_ankle',
    'left_foot', 'right_foot'
);
CREATE TYPE body_constraint_type AS ENUM ('missing', 'injured');
CREATE TYPE visibility AS ENUM ('private', 'friends', 'public');
CREATE TYPE video_status AS ENUM ('pending', 'completed');
CREATE TYPE job_status AS ENUM ('pending', 'processing', 'generating_hints', 'completed', 'failed');
CREATE TYPE hold_type AS ENUM ('jug', 'crimp', 'sloper', 'pinch', 'pocket', 'edge', 'volume', 'foothold');
CREATE TYPE hold_source AS ENUM ('ai', 'manual');
CREATE TYPE goal_status AS ENUM ('active', 'achieved', 'abandoned');
CREATE TYPE focus_area AS ENUM ('technique', 'strength', 'endurance', 'flexibility', 'mental');
CREATE TYPE training_session_type AS ENUM ('technique', 'strength', 'endurance', 'climbing', 'recovery', 'rest');
CREATE TYPE training_program_status AS ENUM ('draft', 'active', 'completed', 'archived');
CREATE TYPE friendship_status AS ENUM ('pending', 'accepted', 'blocked');
CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'expired');
CREATE TYPE subscription_event_type AS ENUM (
    'created', 'activated', 'renewed', 'upgraded', 'downgraded',
    'payment_failed', 'canceled', 'expired'
);
CREATE TYPE tutorial_status AS ENUM ('not_started', 'in_progress', 'completed');
