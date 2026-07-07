# Exercise 08 - Task 2: RTK Evaluation (INSTINCT)


RTK works in two quality levels, written in the **`Solution Type`** column of the file:

- **FIXED** (`Solution Type = 4`) → the best case, position good to a few **mm**.
- **FLOAT** (`Solution Type = 3`) → half-solved, position good to about **10 cm** (still far better than SPP).

We can trust this reading because the column `Number of Ambiguities fixed` is filled in **only** for the FIXED rows, and the file's own error estimate is about **6 mm** on FIXED rows versus **12 cm** on FLOAT rows.

### summary

| quantity | SPP | RTK |
|---|---|---|
| points recorded (same 316 s walk) | 3163 | **2921** (242 missing, 7.7 %) |
| FIXED points | - | **393 / 2921 = 13.5 %** |
| FLOAT points | - | 2528 (86.5 %) |
| accuracy when FIXED | - | **≈ 6 mm** |
| accuracy when FLOAT | - | ≈ 12 cm |
| SPP accuracy (Task 1) | ~0.2 m – several m | - |
| distance rover ↔ base | - | 28 m (max 40 m) |

---

## (a) RTK result - how many points are "fixed"?

Out of **2921** recorded points, only **393 are FIXED (13.5 %)**. The other **86.5 % stay FLOAT**. The very first fix does not happen until **209 s** into the walk, and after that, fixes come only in short bursts.

<img width="1173" height="877" alt="rtk_a_solution_type" src="https://github.com/user-attachments/assets/37c342bc-b6ad-4d2e-9ac1-fbda2921a4da" />

The next plot shows why a fix matters: when the point is **FIXED, the error drops to about 6 mm**;
When it is **FLOAT, the error is about 12 cm**. In short: green = millimetres, orange = centimetres.

<img width="1193" height="597" alt="rtk_b_stdev" src="https://github.com/user-attachments/assets/68991deb-fa62-431b-b3f2-bf441f5cee8c" />

*Why so few fixes?* The base is only 28 m away, so RTK should fix easily under open sky. It does not, and the reason is the same one found in Task 1: the walk runs **along a line of trees**. The trees block satellites and bounce their signals (multipath), so RTK cannot fully solve, and it stays on the safer FLOAT level. The small Emlid Reach antennas make this a bit worse, too.

---

## (b) Comparing SPP and RTK

**Accuracy.** RTK is far more accurate than SPP. SPP was a few metres off (Task 1); RTK is millimetres when fixed and about ten centimetres when float. When we line up the two solutions at the **same moments in time**, the SPP position is on average **3.1 m** away from the accurate RTK position, and up to **15 m** off at the worst moment. RTK basically proves that the metre-level SPP errors from Task 1 were real. The height is also off by a nearly constant **−6.3 m**, which matches the constant height offset already seen in Task 1 - so it is a fixed bias, not random noise.

<img width="1422" height="686" alt="rtk_c_spp_vs_rtk" src="https://github.com/user-attachments/assets/9ad81bdf-b00e-438a-aa32-410f3f2ef62e" />

In the left picture, the green RTK points form a clean, thin line, while the red SPP points are a wide, noisy cloud - especially at the corners near the trees.

**Data gaps.** RTK gives **242 fewer points than SPP (7.7 % missing)**. Every gap is just one missing point (a 0.2 s hole instead of 0.1 s), never a long gap. This happens because RTK needs good signals on **both** receivers at the same time; if either one loses a satellite for a moment, RTK skips that point, while SPP (which uses one receiver) still gives a position. So RTK is a little less continuous, but much more accurate.

<img width="1194" height="547" alt="rtk_d_gaps" src="https://github.com/user-attachments/assets/6390ee45-9691-438f-ad49-8ad8951b8cec" />

**Other odd things noticed.**
- **Only 13.5 % fixed, and the first fix comes late (209 s)** even though the base is close - the trees are the cause, the same spot where SPP jumped in Task 1.
- **No fixes at all during the first standstill (0–70 s)**, which is a bit surprising because standing still usually helps RTK lock faster.
- Even the **FLOAT** RTK (~10 cm) is much better and smoother than SPP (metres), so RTK is the better solution the whole time - it is just not *fixed* for most of the walk.

**Conclusion.** RTK is much more accurate than SPP (mm/cm vs metres), at the cost of a few missing points (~8 %). On this walk only **13.5 %** of points reached the best FIXED level because of the trees blocking and reflecting the signals; a clear open sky and a better antenna would give many more fixes.
