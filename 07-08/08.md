# Exercise 08 - Task 1: SPP Evaluation (INSTINCT)

### summary

| quantity | Kinematic | Static |
|---|---|---|
| epochs / duration | 3163 / 316 s | 1356 / 136 s |
| # satellites | 15 (8 GPS + 7 GAL) | 16 (9 GPS + 7 GAL) |
| PDOP (min–max) | 1.06 - 1.41 | 0.96 |
| horizontal scatter (RMS) | ~69×46 m route | **0.22 m** |
| epoch-to-epoch step mean / max | 0.15 m / **4.89 m** | 0.01 m / 0.07 m |
| SPP - NMEA horizontal (RMS) | **3.33 m** | 0.95 m |
| SPP - NMEA Up (mean) | **+6.8 m** | +3.6 m |

---

## (a) Recorded data - satellites, and DOP

The receiver tracked **15 satellites** (8 GPS + 7 Galileo) for most of the walk, dropping to 14 after ~705 s. As satellites drop, **PDOP rises from 1.06 to ~1.33** - geometry weakens slightly but stays good throughout.

<img width="1178" height="877" alt="kin_a_sats_dop" src="https://github.com/user-attachments/assets/2bbe61df-39df-469a-a210-9f7d2077ae48" />

<br><br>

**Static baseline: 16 satellites, PDOP a constant 0.96:**

<br>
<img width="1178" height="877" alt="sta_a_sats_dop" src="https://github.com/user-attachments/assets/3079dd21-4033-4c4e-84ce-6b8f779d1146" />

---

## (b) SPP positioning result

Two panels per session: horizontal position (East–North) and height over time.

**Kinematic** - the SPP solution traces the ~69 m × 46 m walked loop; the height varies by about ±10 m along the route.

<img width="1180" height="624" alt="kin_b_spp_position" src="https://github.com/user-attachments/assets/56659103-d978-4be9-b2ec-683d6294be5e" />


**Static** - the receiver did not move, so this shows the SPP accuracy directly: all epochs sit in a **0.22 m** cluster, and the height stays within ±0.5 m of the mean.

<img width="1185" height="624" alt="sta_b_spp_position" src="https://github.com/user-attachments/assets/e5d63708-1d97-4b94-8a5c-cb97167009fc" />


---

## (c) SPP vs. receiver-internal solution (NMEA $GNGGA)

Here we compare two positions computed for the **same moments in time**:

- the position **INSTINCT** computes with SPP, and
- the position the **receiver itself** computed live in the field, which it saved in the NMEA file (the `$GNGGA` sentences).

Both are single-point (SPP) solutions - the NMEA "fix quality" field is 1, which means autonomous/single-receiver. So we are comparing two SPP results of the same walk, not two different methods.

The top plot shows the difference (INSTINCT minus receiver), split into East, North, and Up, over time:

- For the first ~70 s, the antenna was standing still (the warm-up). Here, the two solutions agree well - within a few decimetres.
- Once the walk starts, the differences grow to a few metres horizontally, and the **Up (vertical) difference is the largest**, reaching about +15 m at the worst moments.

Why do they differ at all if both are SPP? Because they are **two different pieces of software**:
They may use a slightly different set of satellites, elevation cut-off, or atmosphere models. Small differences are therefore normal, and they grow while moving because that is when the errors (multipath, blocked satellites) are largest.

<img width="1180" height="877" alt="kin_c_spp_vs_nmea" src="https://github.com/user-attachments/assets/6e93c4c6-9f93-454b-b136-ff307bdee1ef" />


Two numbers summarise the agreement:

- horizontal difference (RMS): **3.33 m** kinematic, 0.95 m static;
- vertical (Up) difference (mean): **+6.8 m** kinematic, +3.6 m static.

Notice the Up difference is a roughly **constant offset in the same direction** in both sessions.
A constant offset (rather than random scatter) usually means a height reference or antenna height difference between the two solutions, not measurement noise - worth checking (see *To confirm*).

The bottom plot overlays the two horizontal tracks on the same origin: they follow the same loop, and INSTINCT is a little noisier at the corners near the trees.

<img width="1184" height="877" alt="sta_c_spp_vs_nmea" src="https://github.com/user-attachments/assets/461ec6bc-a633-4448-9f98-6fb54a2bef6d" />


---

## (d) Trajectory on a map

The route is a loop across an open grassy area bordered by trees (satellite basemap, `geoplot`).
Green = start, red = end. The clean, straight legs cross open sky; the **tangled, noisy patches sit exactly at the northern tree line** - the first visual hint of the error sources in (e).

<img width="1077" height="1005" alt="kin_d_trajectory_map" src="https://github.com/user-attachments/assets/d10dca1f-218d-4c36-9173-3a6d8f168b30" />

<br><br>

**Static: a tight cluster**

<br>

<img width="1077" height="1005" alt="sta_d_trajectory_map" src="https://github.com/user-attachments/assets/f877bdef-ff81-4a1c-b684-015a0dca5ff8" />


---

## (e) Typical GNSS error sources - the point of comparing the two

This is the main reason for recording both a static and a kinematic session.

The top plot shows the **horizontal step**: how far the computed position moves from one epoch to the next. Epochs are 0.1 s apart (the receiver logs at 10 Hz), and "Δ" just means "change" - so this is the change in horizontal position during every 0.1 s.

Think about what this value *should* be:

- Walking pace is about 1.4 m/s, so in 0.1 s you really move about 0.15 m. That matches the kinematic average (0.15 m) - this part is **real motion**.
- A step of 4.9 m in 0.1 s would mean the antenna travelled at ~49 m/s (about 175 km/h). That is impossible on foot, so such a step is **not real movement - it is a position error**: the SPP solution jumped away for a moment and then came back.

So the big spikes in the plot are error events, and *where* they happen tells us the cause:

- **Static** (the receiver never moves) → every step should be ~0, and indeed all steps are ≤ 0.07 m. This is the SPP **noise floor** - the best the method does under open sky.
- **Kinematic** → steps reach **4.9 m**. These spikes happen at the same times as the PDOP rising/ a satellite dropping out, which is at the tree line where the sky is blocked. The bottom histogram tells the same story: most epochs agree with the receiver to ~1.5 m, but a separate group at 5–7 m is exactly those blocked-sky moments.

<img width="1245" height="801" alt="kin_e_error_sources" src="https://github.com/user-attachments/assets/0e1a3810-3cc3-4b0c-8b15-cd3222b6b837" />

In short: under open sky, SPP is repeatable to about 0.2 m horizontally. On the walk, metre-level Errors appear wherever trees block the satellites - the classic GNSS error sources: **signal blockage** (fewer satellites, higher DOP) and **multipath** (signals reflected off nearby trees and surfaces). Height is always the noisiest direction because the vertical geometry is weakest.
