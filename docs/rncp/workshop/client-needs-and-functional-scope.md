> **Last updated:** 13th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}  

---

# Client Needs & Functional Scope - Workshop Deliverable

---

## 1. User Personas

To define our users, we have created two distinct archetypes representing our target audience.

|               Attribute                |        Name        |                                Biography                                |                           Pain Points                           |                              Needs                              |                            Goal                             |
| :------------------------------------: | :----------------: | :---------------------------------------------------------------------: | :-------------------------------------------------------------: | :-------------------------------------------------------------: | :---------------------------------------------------------: |
| Persona 1: The Stagnating Intermediate | Progressive Pierre | Climbing for 2 years, stuck at 6a+ grade. Can't afford a private coach. |   Struggles to see micro-errors in posture or mass transfer.    | Instant, affordable technical feedback at the foot of the wall. | Break through the "glass ceiling" and reach the next grade. |
|   Persona 2: The Data-Driven Expert    |  Technical Tanya   |  High-level climber looking for marginal gains and energy efficiency.   | Hard to visualize the optimal "beta" (path) for complex routes. |   Deep biomechanical analysis and energy-saving pathfinding.    |      Optimize movement patterns using objective data.       |

---

## 2. User Stories

Following the template: _As a <persona>, I want <feature> so that <benefit>_.

### For Pierre (Intermediate)

- **As a** Stagnating Intermediate, **I want** to record my climb and see a "Ghost Mode" overlay, **so that** I can immediately see where my hips were out of position compared to the ideal line.
- **As a** budget-conscious climber, **I want** to access high-level coaching for free , **so that** I can progress without the 50€/hour cost of a human coach.

### For Tanya (Expert)

- **As a** Data-Driven Expert, **I want** the system to automatically recognize all holds on a new wall , **so that** I can use the app anywhere, regardless of the gym's database.
- **As a** Technical Climber, **I want** an algorithm to calculate the path that minimizes energy expenditure, **so that** I can send my project with maximum efficiency.

---

## 3. Prioritized Backlog (MoSCoW Method)

We have prioritized our functional scope to define our **Minimum Viable Product (MVP)**.

### M - Must Have (The MVP)

- **2D to 3D Skeleton Extraction:** Core Pose Estimation to track climber movement.
- **Ghost Mode:** Basic overlay of a "perfect" trajectory on top of the user video.
- **Video Upload & Basic Analysis:** The ability to process 10 videos/month for free users.

### S - Should Have

- **Hold Recognition:** Automatic identification of climbing holds using Machine Learning.
- **Personalized Training Routines:** Generating exercises based on detected technical weaknesses.
- **Social Sharing:** Direct export of "Ghost Mode" clips to Instagram/TikTok for community growth.

### C - Could Have

- **Server Priority:** Faster processing times for "Infinity" tier subscribers.
- **Advanced Biomechanics:** Real-time center of gravity and force distribution metrics.
- **Gym Partnerships:** Integration with QR codes at specific gyms like Arkose or Climb Up.

### W - Won't Have (This Scope)

- **Live AR Glasses Support:** Future hardware integration (currently focusing on smartphones).
- **Human Coaching Marketplace:** We are focusing on AI-automated coaching first.

---

## 4. Next Steps: Continuous Improvement Loop

To ensure project success, we will follow the iterative methodology:

1. **Contact Early Adopters:** Reach out to local climbers in gyms (Arkose/Climb Up) to get feedback.
2. **Gather Testimonials:** Transform enthusiastic users into project ambassadors.
3. **Refine Personas:** Use real-world feedback to update our user archetypes and iterate on the functional scope.
