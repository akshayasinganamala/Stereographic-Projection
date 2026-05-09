# Stereographic Projection & Inverse Stereographic Mapping
### A MATLAB-Based Computational Geometry and Visualization Framework

> Mapping the infinite plane onto the finite sphere — and back.

---

![MATLAB](https://img.shields.io/badge/MATLAB-R2023b-orange?style=flat-square&logo=mathworks)
![Domain](https://img.shields.io/badge/Domain-Computational%20Geometry-blue?style=flat-square)
![Type](https://img.shields.io/badge/Type-Research%20%2F%20Visualization-green?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)

---

## Table of Contents

- [Overview](#overview)
- [Objectives](#objectives)
- [Mathematical Background](#mathematical-background)
  - [The Unit Sphere](#the-unit-sphere)
  - [Stereographic Projection](#stereographic-projection)
  - [Inverse Stereographic Mapping](#inverse-stereographic-mapping)
  - [Circle Preservation](#circle-preservation-under-projection)
  - [Conformality](#angle-preserving-conformal-property)
- [Methodology](#methodology)
- [MATLAB Implementation](#matlab-implementation)
- [Repository Structure](#repository-structure)
- [Output Visualizations](#output-visualizations)
- [Applications](#applications)
- [Research Inspiration](#research-inspiration)
- [Future Scope](#future-scope)
- [Technologies Used](#technologies-used)
- [Conclusion](#conclusion)
- [Author](#author)

---

## Overview

This repository presents a MATLAB-based computational framework for studying **stereographic projection** — a classical construction from differential geometry that establishes a one-to-one, angle-preserving (conformal) correspondence between the punctured unit sphere $S^2 \setminus \{Q\}$ and the Euclidean plane $\mathbb{R}^2$.

The project implements both the **forward projection** (sphere → plane) and the **inverse stereographic mapping** (plane → sphere), alongside geometric transformations of curves, circles, and coordinate grids. The visualizations are designed to make abstract mathematical structure concretely perceptible.

This work sits at the intersection of **conformal geometry**, **computational mathematics**, and **scientific visualization**, and is informed directly by the formal treatment of stereographic projection as developed in the context of Euclidean and Non-Euclidean geometry (Wilkins, 2017).

---

## Objectives

- Implement the bijective stereographic projection map $\psi: S^2 \setminus \{(0,0,-1)\} \to \mathbb{R}^2$ and its inverse $\psi^{-1}: \mathbb{R}^2 \to S^2 \setminus \{(0,0,-1)\}$ in MATLAB with full numerical precision.
- Visualize the geometric behaviour of circles and lines under both mappings.
- Demonstrate the conformal (angle-preserving) property of stereographic projection numerically and visually.
- Provide a modular, extensible codebase for computational experiments in spherical geometry.

---

## Mathematical Background

### The Unit Sphere

The domain of projection is the unit sphere in $\mathbb{R}^3$:

$$S^2 = \{(u, v, w) \in \mathbb{R}^3 : u^2 + v^2 + w^2 = 1\}$$

The projection pole is fixed at the **south pole** $N = (0, 0, -1)$. Every point on $S^2$ distinct from $N$ is mapped to a unique point on the equatorial plane $\{z = 0\}$.

---

### Stereographic Projection

The stereographic projection $\psi: S^2 \setminus \{(0,0,-1)\} \to \mathbb{R}^2$ maps each point $(u, v, w)$ on the sphere to the intersection of the line through $(u, v, w)$ and $(0, 0, -1)$ with the plane $z = 0$.

**Forward map:**

$$\psi(u, v, w) = \left(\frac{u}{w+1},\; \frac{v}{w+1}\right)$$

This map is well-defined for all $(u, v, w) \in S^2$ with $w \neq -1$, i.e., everywhere except the projection pole itself.

---

### Inverse Stereographic Mapping

The inverse map $\psi^{-1}: \mathbb{R}^2 \to S^2 \setminus \{(0,0,-1)\}$ reconstructs the spherical coordinates $(u, v, w)$ from any planar point $(x, y)$.

**Inverse map (Proposition 6.1):**

$$u = \frac{2x}{1 + x^2 + y^2}, \qquad v = \frac{2y}{1 + x^2 + y^2}, \qquad w = \frac{1 - x^2 - y^2}{1 + x^2 + y^2}$$

**Verification:** Substituting into $u^2 + v^2 + w^2$ confirms that every $(x, y) \in \mathbb{R}^2$ maps to a point on $S^2$:

$$\frac{4x^2 + 4y^2 + (1 - x^2 - y^2)^2}{(1 + x^2 + y^2)^2} = 1$$

This establishes that $\psi^{-1}$ maps $\mathbb{R}^2$ into $S^2 \setminus \{(0,0,-1)\}$, and that $\psi$ is a **bijection**.

---

### Circle Preservation Under Projection

One of the defining geometric properties of stereographic projection is that it maps **circles to circles or lines**, and vice versa. Two cases arise:

**Case 1 — Circles through the pole $N = (0,0,-1)$:**

A circle on $S^2$ defined by $\ell u + m v + n w = -n$ (i.e., passing through the south pole) maps under $\psi$ to the straight line in $\mathbb{R}^2$:

$$px + qy = k, \qquad \text{where } p = \frac{\ell}{\sqrt{\ell^2 + m^2}},\; q = \frac{m}{\sqrt{\ell^2 + m^2}},\; k = \sqrt{\frac{1}{\ell^2 + m^2} - 1}$$

**Case 2 — Circles not through the pole:**

A circle on $S^2$ defined by $\ell u + mv + nw = c$ (with $c \neq -n$) maps to a Euclidean circle $(x - a)^2 + (y - b)^2 = r^2$ in $\mathbb{R}^2$, where:

$$a = \frac{\ell}{c + n}, \qquad b = \frac{m}{c + n}, \qquad r = \frac{\sqrt{1 - c^2}}{|c + n|}$$

**Conversely**, given any circle of radius $r$ centred at $(a, b)$ in $\mathbb{R}^2$, its pre-image under $\psi$ is the circle on $S^2$ where the sphere intersects the plane:

$$2au + 2bv + (1 + r^2 - a^2 - b^2)\,w = 1 - r^2 + a^2 + b^2$$

---

### Angle-Preserving (Conformal) Property

Stereographic projection is **conformal**: it preserves the angle between any two curves at their point of intersection.

**Proof outline (Proposition 6.4):** Let $P \in S^2 \setminus \{Q\}$ and let $L_1, L_2$ be two lines in the tangent plane $T_P$ intersecting at $P$. The planes $\Pi_1 = \text{span}(L_1, Q)$ and $\Pi_2 = \text{span}(L_2, Q)$ are each stable under the reflection $\tau$ across the perpendicular bisector plane $\Lambda$ of the segment $PQ$. Since $\tau$ maps $T_P \to T_Q$ and preserves angles, the angle between $L_1$ and $L_2$ at $P$ equals the angle between $M_1 = \Pi_1 \cap T_Q$ and $M_2 = \Pi_2 \cap T_Q$ at $Q$.

The equatorial plane $\Pi_Q$ is parallel to $T_Q$, so lines $N_i = \Pi_Q \cap \Pi_i$ are parallel to $M_i$, and intersect at $\psi(P)$. The angle at $\psi(P)$ between $N_1$ and $N_2$ is therefore equal to the original angle between $L_1$ and $L_2$ at $P$. $\blacksquare$

---

## Methodology

The project follows a structured computational pipeline:

1. **Parameterisation** — The unit sphere is parameterised in spherical coordinates $(\theta, \phi)$ and sampled on a fine mesh.
2. **Forward projection** — Each spherical point $(u, v, w)$ is projected to the plane via $\psi$.
3. **Inverse mapping** — Planar grids, circles, and curves are lifted back to $S^2$ via $\psi^{-1}$.
4. **Geometric verification** — Circle images under projection are computed analytically and confirmed numerically against the MATLAB-generated loci.
5. **Conformality testing** — Angle intersections of projected curves are measured and compared against their spherical counterparts.
6. **Visualization** — 3D surface plots of the sphere, overlaid with projected grids and curves, are rendered with matched planar views for side-by-side comparison.

---

## MATLAB Implementation

The codebase is written in MATLAB and is structured into modular scripts and functions. Key implementation decisions:

- **Parameterisation mesh:** Spherical coordinates $(\theta \in [0, \pi],\; \phi \in [0, 2\pi])$ sampled at uniform angular resolution.
- **Numerical stability:** The formula $w + 1 = \frac{2}{1 + x^2 + y^2}$ is used in the inverse map to avoid division-by-zero at the origin.
- **Circle rendering:** Circles on $S^2$ are generated from the planar equation $\ell u + mv + nw = c$ and lifted to 3D; their projections are computed both analytically and numerically for cross-validation.
- **Grid overlay:** Cartesian grid lines on $\mathbb{R}^2$ are mapped onto $S^2$ via $\psi^{-1}$, producing the characteristic curved coordinate grid visible on the sphere.
- **Conformality visualization:** Two families of orthogonal circles on the plane are mapped to $S^2$ and their intersection angles verified.

### Core Functions

| Function | Description |
|---|---|
| `stereo_project.m` | Forward map $\psi(u,v,w) \to (x,y)$ |
| `inverse_stereo.m` | Inverse map $\psi^{-1}(x,y) \to (u,v,w)$ |
| `sphere_circle.m` | Generates a great-circle/small-circle on $S^2$ given $(\ell, m, n, c)$ |
| `project_circle.m` | Computes the planar image of a spherical circle |
| `lift_curve.m` | Lifts any planar curve to $S^2$ via inverse mapping |
| `plot_sphere_grid.m` | Renders the sphere with projected Cartesian grid overlay |
| `conformality_check.m` | Numerically verifies angle preservation at sample points |
| `visualize_all.m` | Master script: runs full pipeline and generates all figures |

---

## Repository Structure

```
stereographic-projection-matlab/
│
├── src/
│   ├── stereo_project.m          # Forward stereographic projection
│   ├── inverse_stereo.m          # Inverse stereographic mapping
│   ├── sphere_circle.m           # Circle generation on S²
│   ├── project_circle.m          # Circle image computation
│   ├── lift_curve.m              # Planar curve → sphere
│   ├── plot_sphere_grid.m        # Sphere + grid visualization
│   ├── conformality_check.m      # Angle-preservation verification
│   └── visualize_all.m           # Master runner script
│
├── outputs/
│   ├── figures/
│   │   ├── sphere_with_grid.png
│   │   ├── circle_projection.png
│   │   ├── inverse_map_result.png
│   │   └── conformality_demo.png
│   └── data/
│       ├── projected_coords.mat
│       └── sphere_mesh.mat
│
├── docs/
│   ├── mathematical_notes.pdf
│   └── references.md
│
├── tests/
│   ├── test_bijection.m          # Confirms ψ∘ψ⁻¹ = identity
│   ├── test_circle_map.m         # Validates circle-to-circle mapping
│   └── test_angles.m             # Conformality numerical tests
│
├── README.md
└── LICENSE
```

---

## Output Visualizations

### Sphere with Projected Cartesian Grid

> The standard Cartesian grid on $\mathbb{R}^2$ lifted to $S^2$ via $\psi^{-1}$. Grid lines become circles on the sphere that all pass through the south pole $(0, 0, -1)$.

```
[ INSERT: outputs/figures/sphere_with_grid.png ]
```

---

### Circle-to-Circle Mapping

> A family of circles on $S^2$ not passing through the pole, and their images as Euclidean circles in the plane.

```
[ INSERT: outputs/figures/circle_projection.png ]
```

---

### Inverse Stereographic Mapping Result

> Planar lemniscates, Archimedean spirals, and elliptic curves lifted to the sphere surface via the inverse map.

```
[ INSERT: outputs/figures/inverse_map_result.png ]
```

---

### Conformality Demonstration

> Two orthogonal curve families on the plane, lifted to $S^2$. Intersection angles are preserved exactly under the mapping.

```
[ INSERT: outputs/figures/conformality_demo.png ]
```

---

## Applications

Stereographic projection and its inverse appear across a wide range of disciplines:

| Domain | Application |
|---|---|
| Cartography | Stereographic map projections (polar maps, navigation charts) |
| Complex Analysis | The Riemann sphere; Möbius transformations as sphere rotations |
| Signal Processing | Directional data representation on the sphere |
| Computer Graphics | Environment mapping, spherical texture projection |
| Crystallography | Pole figures; orientation distribution analysis |
| Antenna Engineering | Radiation pattern visualization on the unit sphere |
| Physics | Spin states in quantum mechanics (Bloch sphere) |
| Astronomy | All-sky survey projections; stellar catalogue mapping |

---

## Research Inspiration

This project is grounded in the classical mathematical treatment of stereographic projection, as formalized in:

- **D. R. Wilkins**, *MA232A — Euclidean and Non-Euclidean Geometry*, School of Mathematics, Trinity College Dublin, Michaelmas Term 2017, Section 6.

The mathematical properties leveraged here — bijectivity (Proposition 6.1), circle preservation (Propositions 6.2 and 6.3), and conformality (Proposition 6.4) — are each proven formally in that reference and serve as the precise mathematical specification for this implementation.

The historical origins of stereographic projection trace to **Claudius Ptolemy's** *Planisphaerium* (2nd century AD), which described the projection and investigated its properties for astronomical applications. The work survived through its Arabic translation and remains one of the earliest documented treatments of a conformal map.

> Sidoli, N. & Berggren, J. L. (2007). *The Arabic version of Ptolemy's Planisphere or Flattening the Surface of the Sphere: Text, Translation, Commentary.* SCIAMVS 8, 37–139.

---

## Future Scope

- **Extension to hyperbolic geometry:** Implement the analogous projection from the hyperboloid model of $\mathbb{H}^2$ onto the Poincaré disk.
- **Möbius transformation visualization:** Represent Möbius transformations of $\mathbb{C} \cup \{\infty\}$ as isometries of $S^2$ acting through the stereographic correspondence.
- **Dynamic animation:** Animate continuous deformation of planar curves as they are lifted and projected, using MATLAB's `VideoWriter`.
- **Higher-dimensional extension:** Generalize to stereographic projection from $S^n \subset \mathbb{R}^{n+1}$ onto $\mathbb{R}^n$.
- **Numerical error analysis:** Quantify floating-point deviation from exact conformality and bijectivity across the sphere mesh.
- **GUI interface:** Build a MATLAB App Designer interface for interactive selection of projection poles and input curves.

---

## Technologies Used

| Tool | Role |
|---|---|
| **MATLAB R2023b** | Primary implementation and visualization environment |
| **Symbolic Math Toolbox** | Analytic verification of projection formulas |
| **MATLAB Graphics** | 3D surface rendering, curve overlay, figure export |
| **LaTeX / MathJax** | Mathematical documentation |

---

## Conclusion

This project demonstrates that stereographic projection — despite being derivable from elementary analytic geometry — encodes deep structural properties: it is bijective, circle-preserving, and conformal. The MATLAB implementation makes these properties computationally verifiable and visually intuitive, bridging the gap between formal mathematical proof and geometric intuition.

The inverse stereographic map in particular offers a powerful tool for lifting arbitrary planar geometry onto the sphere, enabling cross-domain applications in graphics, signal processing, and cartography. This codebase is intended as both a self-contained research artefact and an extensible platform for further investigation in computational spherical geometry.

---
