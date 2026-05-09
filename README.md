# Kalamkari Stereographic Projection → 3D Printable STL
### Transforming Traditional Indian Art into Spherical Geometry via Inverse Stereographic Mapping

> *A point light placed atop the printed sphere casts a shadow below — and that shadow is your original Kalamkari motif.*


---

## Table of Contents

- [Overview](#overview)
- [The Core Idea](#the-core-idea)
- [Mathematical Foundation](#mathematical-foundation)
  - [Inverse Stereographic Projection](#inverse-stereographic-projection)
  - [Shadow as Forward Projection](#shadow-as-forward-projection)
  - [Conformality and Circle Preservation](#conformality-and-circle-preservation)
- [Full Pipeline](#full-pipeline)
- [Pipeline Visualizations](#pipeline-visualizations)
- [MATLAB Implementation](#matlab-implementation)
- [Key Parameters](#key-parameters)
- [Repository Structure](#repository-structure)
- [3D Printing Guide](#3d-printing-guide)
- [Applications and Context](#applications-and-context)
- [Technologies Used](#technologies-used)
- [Mathematical Reference](#mathematical-reference)
- [Author](#author)

---

## Overview

This project implements a **9-step computational pipeline** in MATLAB that:

1. Takes any **Kalamkari motif image** as input
2. Extracts its ink geometry as a **2D point cloud**
3. Builds a **filtered Delaunay triangulation** over the motif
4. Lifts that mesh onto a **unit sphere** via **inverse stereographic projection**
5. Applies **Laplacian smoothing** with spherical re-projection
6. Extrudes it into a **watertight solid shell** suitable for 3D printing
7. Simulates the **shadow cast** by a point light through the sphere surface
8. Exports a **binary STL file** scaled to physical millimetres

The physical result is a 3D-printed spherical lamp. When a point light source is placed at the top (north pole) of the sphere, the shadow projected onto a flat surface below **exactly reconstructs** the original Kalamkari pattern — because stereographic projection is its own inverse.

---

## The Core Idea

**Kalamkari** is a centuries-old Indian hand-painted textile art form, characterized by intricate floral, figurative, and geometric motifs drawn with a tamarind-tipped pen using natural dyes. This project uses Kalamkari patterns as the geometric input to a mathematical transformation rooted in conformal geometry.

The insight driving the project:

> Stereographic projection from the north pole of a sphere onto a flat plane is conformal and maps circles to circles. Its inverse maps the flat motif back onto the sphere. A point light placed at the projection pole then casts a shadow that perfectly reconstructs the original flat image.

```
Flat Kalamkari Image
        ↓   inverse stereographic projection (Step 5)
Motif geometry wrapped on sphere surface
        ↓   solid extrusion + STL export (Steps 7–9)
Physical 3D-printed sphere lamp
        ↓   point light source at north pole
Shadow on floor = original Kalamkari motif  ✓
```

The mathematics closes on itself: the shadow simulation in Step 8 is the forward stereographic projection, undoing the inverse map applied in Step 5.

---

## Mathematical Foundation

### Inverse Stereographic Projection

The pipeline lifts each planar point from the normalized image domain $[-1,1]^2 \subset \mathbb{R}^2$ onto the unit sphere $S^2$ via the inverse stereographic map $\psi^{-1}: \mathbb{R}^2 \to S^2$.

Given a normalized planar point $(X, Y)$ extracted from the motif, let:

$$R^2 = X^2 + Y^2$$

Then the corresponding spherical coordinates are:

$$X_s = \frac{2X}{R^2 + 1}, \qquad Y_s = \frac{2Y}{R^2 + 1}, \qquad Z_s = \frac{R^2 - 1}{R^2 + 1} + 1$$

The $+1$ offset on $Z_s$ translates the sphere upward so its south pole rests exactly at $Z = 0$, placing the model flat on the 3D printer bed with no support material required beneath it.

**Verification:** Substituting back confirms every projected point lies on the unit sphere centred at $(0,0,1)$:

$$X_s^2 + Y_s^2 + (Z_s - 1)^2 = 1 \quad \forall\; (X, Y) \in \mathbb{R}^2$$

The image centre $(0, 0)$ maps to the **south pole** $(0, 0, 0)$. Points far from the origin approach the **north pole** $(0, 0, 2)$ — which is where the light source is placed for the shadow simulation.

---

### Shadow as Forward Projection

Step 8 implements the **forward** stereographic projection as a ray-casting shadow simulation. A point light at position $L = (L_x, L_y, L_z)$ casts rays through each sphere vertex $V_s$ onto the ground plane $Z = 0$.

The parametric ray is $P(t) = L + t(V_s - L)$. Setting $Z = 0$ and solving for $t$:

$$t = \frac{-L_z}{V_{s,z} - L_z}$$

$$P_x = L_x + t(V_{s,x} - L_x), \qquad P_y = L_y + t(V_{s,y} - L_y)$$

This is precisely the forward stereographic projection formula, mapping sphere points back to the plane. The shadow on the floor is therefore a scaled, geometrically faithful copy of the original flat motif — the mathematical loop is closed.

---

### Conformality and Circle Preservation

Because stereographic projection is **conformal** (angle-preserving), the angles between curves in the original Kalamkari image are preserved exactly on the sphere surface. The characteristic smooth curves, interlocking spirals, and floral arcs of Kalamkari — which depend on precise angular transitions — remain geometrically faithful after projection.

Two classical results govern the circle geometry (following Wilkins, 2017):

**Circles through the pole** (lines in the image that pass through the image centre) map to **great circles** on the sphere.

**Circles not through the pole** map to **small circles** on the sphere. Specifically, a circle of radius $r$ centred at $(a, b)$ in $\mathbb{R}^2$ lifts to the intersection of $S^2$ with the plane:

$$2au + 2bv + (1 + r^2 - a^2 - b^2)\,w = 1 - r^2 + a^2 + b^2$$

This means every circular element in the Kalamkari motif — petals, borders, medallions — becomes a spherical circle of precisely determinable radius and orientation on the sphere.

---

## Full Pipeline

| Step | Operation | Input → Output |
|:---:|---|---|
| **1** | Image Load | File dialog → raw image array |
| **2** | Image Processing | RGB → Grayscale → Binary mask → Morphological dilation |
| **3** | Point Cloud Generation | Binary mask → boundary + internal fill points in $[-1,1]^2$ |
| **4** | Delaunay Triangulation | 2D points → filtered triangle mesh (centroid + edge length filters) |
| **5** | Inverse Stereo Projection | 2D mesh → mesh lifted onto $S^2$ |
| **6** | Laplacian Smoothing | Raw sphere mesh → smooth sphere mesh (with spherical re-projection) |
| **7** | Solid Extrusion | Single-surface mesh → watertight solid shell |
| **8** | Shadow Preview | Sphere mesh + light position → ground-plane shadow patch |
| **9** | STL Export | Solid mesh → binary `.stl` at physical scale (mm) |

---

## Pipeline Visualizations

### Step 2 — Binary Mask After Processing

> The Kalamkari image is converted to grayscale, auto-polarity-detected (dark-on-light or light-on-dark), thresholded, and morphologically dilated to produce ink regions with printable line thickness.


<img width="200" height="200" alt="Screenshot 2026-04-09 005510" src="https://github.com/user-attachments/assets/377d390a-3e11-45ea-9bbf-07e87e9750c6" />



---

### Step 3 — 2D Point Cloud

> Boundary (Laplacian edge-detected) points overlaid with internal grid-fill points. All coordinates normalized to $[-1, +1]^2$. This is the raw geometric representation of the Kalamkari ink.

<img width="300" height="300" alt="Screenshot 2026-04-09 005932" src="https://github.com/user-attachments/assets/db85edb1-1586-408f-85cd-e0751da8b3ae" />


---

### Step 4 — Delaunay Mesh (Filtered)

> Delaunay triangulation of the point cloud, with two filtering passes: (1) centroid-in-mask filter removing triangles outside ink regions, (2) edge-length filter removing stretched artifact triangles near the boundary.


<img width="300" height="300" alt="Screenshot 2026-04-09 010006" src="https://github.com/user-attachments/assets/2fa1fa27-d416-4acd-957b-c2121cb38fed" />



---

### Steps 5–6 — Kalamkari Motif on Sphere

> The filtered 2D mesh lifted to $S^2$ via inverse stereographic projection, then smoothed with Laplacian iterations. Spherical re-projection after each smoothing step prevents the mesh from shrinking inward off the sphere surface.


<img width="300" height="300" alt="Screenshot 2026-04-09 011607" src="https://github.com/user-attachments/assets/0a8d2605-2664-4af3-8209-2bb536f49b27" />


---

### Step 7 — Watertight Solid Shell

> The sphere surface extruded radially outward by `Thickness_mm / PhysicalRadius_mm` along outward unit normals. Inner and outer shells are stitched at the boundary edges to form a fully enclosed, manifold solid.


<img width="300" height="300" alt="Screenshot 2026-04-09 011637" src="https://github.com/user-attachments/assets/5023423b-720a-4da9-82f3-160f693f0b29" />



---

### Step 8 — Simulated Shadow

> Ray-cast from the light source through each sphere vertex to the $Z = 0$ plane. The resulting patch on the floor is the forward stereographic projection of the sphere mesh — reconstructing the original Kalamkari motif.


<img width="300" height="300" alt="Screenshot 2026-04-09 160454" src="https://github.com/user-attachments/assets/85bac26f-bb58-439a-be98-e0a2a624e8ed" />





---

## MATLAB Implementation

### Auto-Polarity Detection

The script detects image polarity from the mean pixel value and inverts the mask if needed — handling both dark-ink-on-white and light-motif-on-dark inputs automatically:

```matlab
meanVal = mean(gry_resized(:));
if meanVal > 128
    mask = gry_resized < 128;   % dark ink on light background → invert
else
    mask = gry_resized > 128;   % bright motifs on dark background → keep
end
```

### Two-Pass Mesh Filtering (Step 4)

Raw Delaunay triangulation produces many triangles outside the ink region and long artifact triangles at boundaries. Two filters remove these:

```matlab
% Pass 1: centroid must fall inside the ink mask
keep = mask(sub2ind([N N], pr, pc)) > 0;
F = F(keep, :);

% Pass 2: no triangle edge longer than threshold
L = max([edge_ab, edge_bc, edge_ca], [], 2);
F = F(L < edgeLengthThresh, :);
```

### Laplacian Smoothing with Spherical Re-projection (Step 6)

Standard Laplacian smoothing causes vertices to migrate inward off the sphere. After each iteration, vertices are re-normalized back onto the unit sphere:

```matlab
for it = 1:smoothingIter
    W         = sparse(I, J, 1, size(SP,1), size(SP,1));
    W         = (W + W') > 0;
    SP_smooth = (W * SP) ./ sum(W, 2);       % Laplacian average

    SP_smooth(:,3) = SP_smooth(:,3) - 1;     % shift to sphere centred at origin
    norms          = sqrt(sum(SP_smooth.^2, 2));
    SP_smooth      = SP_smooth ./ norms;     % re-project onto unit sphere
    SP_smooth(:,3) = SP_smooth(:,3) + 1;     % shift back to printer bed
    SP = SP_smooth;
end
```

### Watertight Shell Assembly (Step 7)

The solid is built from three face sets with consistent winding:

```matlab
F_in    = F(:, [1 3 2]);        % inner faces — reversed winding (inward normals)
F_out   = F + numV;             % outer faces — offset vertex indices
F_wall1 = [u, v, numV+v];       % rim triangles connecting inner to outer
F_wall2 = [u, numV+v, numV+u];

F_solid = [F_in; F_out; F_wall1; F_wall2];
```

Boundary edges are identified via `freeBoundary()` on the inner triangulation. No manual edge-finding is needed.

### Binary STL Export (Step 9)

The file is written in binary format (80-byte header + triangle count + per-triangle records) for compact size and broad slicer compatibility:

```matlab
fwrite(fid, single(normals(i,:)), 'float32');   % face normal
fwrite(fid, single(v1(i,:)),      'float32');   % vertex 1
fwrite(fid, single(v2(i,:)),      'float32');   % vertex 2
fwrite(fid, single(v3(i,:)),      'float32');   % vertex 3
fwrite(fid, uint16(0),            'uint16');    % attribute byte count
```

---

## Key Parameters

All tunable parameters are declared at the top of `kalamkari_2.m` for easy adjustment:

| Parameter | Default | Description |
|---|---|---|
| `PhysicalRadius_mm` | `50` | Sphere radius → 100 mm total diameter |
| `Thickness_mm` | `2` | Wall thickness (2 mm is standard for FDM) |
| `N` | `800` | Processing resolution (800×800 pixel grid) |
| `thickeningAmount` | `7` | Dilation kernel size — controls printed line thickness |
| `smoothingIter` | `5` | Laplacian smoothing passes (3–8 recommended) |
| `edgeLengthThresh` | `0.04` | Maximum triangle edge length in normalized units |
| `gridStep` | `2` | Internal fill point spacing (smaller = denser mesh) |
| `Lpos` | `[0, 0, 3.5]` | Light source position for shadow simulation |

---



---

## 3D Printing Guide

1. Open the exported `.stl` in **Cura**, **PrusaSlicer**, or **Bambu Studio**
2. Verify mesh integrity — no holes, wall thickness ≥ 2 mm throughout
3. Orient with the south pole flat on the bed — no brim or raft needed
4. Recommended settings: 0.2 mm layer height, 15% infill, no supports
5. Material: **PLA** or **PETG**; translucent or white filament maximizes the lamp shadow effect
6. Post-print: place a small point LED or candle at the north pole (top of sphere)
7. Hold above a flat surface in a dark room — the Kalamkari motif appears in shadow below

> **Tip:** The closer the light to the pole, the larger and sharper the projected shadow. Moving the light laterally off-centre introduces a controlled Möbius-type distortion to the shadow — itself a mathematically interesting effect.

---

## Applications and Context

| Domain | Connection |
|---|---|
| **Computational Art** | Parametric encoding of traditional craft geometry |
| **Mathematical Visualization** | Physical, tactile demonstration of stereographic projection |
| **3D Printing / Fabrication** | Direct image-to-STL pipeline with no intermediate CAD |
| **Design Education** | *Mathematics for Designers* course project |
| **Conformal Geometry** | Applied demonstration of angle-preserving mappings |
| **Cultural Heritage** | Encoding Kalamkari patterns in geometrically precise 3D form |

---

## Technologies Used

| Tool | Role |
|---|---|
| **MATLAB R2023b** | Complete pipeline — image processing, geometry, STL export |
| **Image Processing Toolbox** | `imresize`, `rgb2gray`, `imshow` |
| **`delaunayTriangulation`** | 2D constrained mesh generation |
| **`freeBoundary`** | Boundary edge detection for shell stitching |
| **`trisurf` / `triplot`** | 3D and 2D mesh visualization |
| **Custom binary STL writer** | Implemented via MATLAB `fwrite` — no toolbox dependency |
| **Cura / PrusaSlicer** | Downstream slicing for FDM 3D printing |

---

## Mathematical Reference

This project directly implements the inverse stereographic mapping formalized in:

> D. R. Wilkins, *MA232A — Euclidean and Non-Euclidean Geometry*, School of Mathematics, Trinity College Dublin, Michaelmas Term 2017, Section 6: Stereographic Projection — Propositions 6.1 (bijectivity and inverse formula), 6.2–6.3 (circle and line preservation), 6.4 (conformality).

The conformal property (Prop. 6.4) explains why Kalamkari's intrinsic curved geometry is preserved faithfully on the sphere. The circle-preservation property (Props. 6.2–6.3) means every circular element in the motif — petals, medallions, borders — lifts to a precisely defined spherical circle. The shadow simulation is the forward projection of Prop. 6.1, completing the mathematical round-trip.

---
---

## Physical Output — 3D Print & Shadow Result

### The Printed Sphere

> The final 3D-printed spherical shell in PLA/PETG. Wall thickness: 2 mm. Diameter: 100 mm.


<img width="300" height="300" alt="Screenshot 2026-04-09 191802" src="https://github.com/user-attachments/assets/dfad573b-91fb-4081-82b8-66ac79a3ee57" />




---

### Shadow Projection — Kalamkari Motif Reconstructed

> Point LED placed at the north pole of the sphere in a dark room. The shadow cast on the flat surface below reconstructs the original Kalamkari motif — demonstrating the self-inverse property of stereographic projection physically.


<img width="300" height="300" alt="Screenshot 2026-04-09 191010" src="https://github.com/user-attachments/assets/26f69f47-6162-43a0-a10b-35508f262d2f" />

---

### Side-by-Side Comparison

| Original Kalamkari Motif | Shadow Projection |
<img width="300" height="300" alt="Screenshot 2026-04-09 005443" src="https://github.com/user-attachments/assets/18f68bda-8dd0-4611-bfd2-c6b9a59e2d00" />
<img width="300" height="300" alt="Screenshot 2026-04-09 191010" src="https://github.com/user-attachments/assets/b3129e62-777e-48f6-a0ee-2ae3b1bd8fbc" />
 

> The correspondence between the input motif and the projected shadow visually validates the mathematical pipeline end-to-end.
