% =========================================================================
% KALAMKARI STEREOGRAPHIC PROJECTION → 3D PRINTABLE STL
% =========================================================================
% PROJECT   : Stereographic Projection of Kalamkari Motif
% COURSE    : Mathematics for Designers
% TOOLBOXES : Image Processing Toolbox (required)
% =========================================================================

clc; clear; close all;
warning('off', 'MATLAB:triangulation:PtsNotInTriWarnId');

fprintf('==============================================\n');
fprintf('  KALAMKARI STEREOGRAPHIC PROJECTION\n');
fprintf('==============================================\n\n');

% % =========================================================================
% PARAMETERS — Adjust these to tune your output
% =========================================================================

PhysicalRadius_mm  = 50;   % Sphere radius in mm (50 = 100mm total diameter)
Thickness_mm       = 2;    % Wall thickness in mm (2mm is standard for FDM)
N                  = 800;  % Image resolution (800x800 grid)
thickeningAmount   = 7;    % Line dilation kernel size (bigger = thicker lines)
smoothingIter      = 5;    % Laplacian smoothing iterations (3–8 recommended)
edgeLengthThresh   = 0.04; % Max triangle edge length (remove stretched triangles)
gridStep           = 2;    % Internal grid spacing (smaller = denser fill mesh)
Lpos               = [0, 0, 3.5]; % Light source position for shadow preview

% =========================================================================
% STEP 1 — LOAD IMAGE
% =========================================================================

fprintf('STEP 1: Loading your Kalamkari image...\n');
disp('>>> A file dialog will open. Select your Kalamkari image file.');

[fname, fpath] = uigetfile( ...
    {'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image Files'}, ...
    'Select your Kalamkari image');

if isequal(fname, 0)
    error('No file selected. Please run again and choose your image.');
end

raw = imread(fullfile(fpath, fname));
fprintf('    Image loaded: %s\n', fname);
fprintf('    Original size: %d x %d\n', size(raw,1), size(raw,2));

% =========================================================================
% STEP 2 — IMAGE PROCESSING: Grayscale → Resize → Threshold → Dilate
% =========================================================================

fprintf('\nSTEP 2: Processing image (grayscale, threshold, dilation)...\n'); 

% Convert to grayscale
if size(raw, 3) == 3
    gry = rgb2gray(raw);
else
    gry = raw;
end

% Resize to NxN for uniform processing
gry_resized = imresize(double(gry), [N N], 'bilinear');

% -------------------------------------------------------------------
% AUTO-DETECT image polarity
% Dark ink on white background → invert so ink = 1
% Light motifs on dark background → keep as is
% -------------------------------------------------------------------
meanVal = mean(gry_resized(:));
if meanVal > 128
    % Most pixels are bright → ink is dark → invert
    mask = gry_resized < 128;   % ink pixels = 1
    fprintf('    Detected: Dark ink on light background (inverted)\n');
else
    % Most pixels are dark → motifs are bright
    mask = gry_resized > 128;   % bright motifs = 1
    fprintf('    Detected: Light motifs on dark background\n');
end

% Thicken lines using 2D convolution (morphological dilation without toolbox)
fprintf('    Thickening lines (kernel size: %dx%d)...\n', ...
    thickeningAmount, thickeningAmount);
dilateKernel = ones(thickeningAmount, thickeningAmount);
mask = conv2(double(mask), dilateKernel, 'same') > 0;

% Visualize Step 2
figure('Name', 'STEP 2: Binary Mask After Processing', 'NumberTitle', 'off');
subplot(1,2,1);
imshow(gry_resized, []);
title('Original Grayscale', 'FontSize', 12, 'FontWeight', 'bold');

subplot(1,2,2);
imshow(mask);
title('Binary Mask (White = Ink)', 'FontSize', 12, 'FontWeight', 'bold');
sgtitle('Step 2: Image Processing Result', 'FontSize', 14);

fprintf('    Binary mask created: %d ink pixels active\n', sum(mask(:)));

% =========================================================================
% STEP 3 — POINT CLOUD GENERATION (Boundary + Internal Fill)
% =========================================================================

fprintf('\nSTEP 3: Generating 2D point cloud...\n');

% --- 3a. Edge / Boundary Points (Laplacian edge detection) ---
edge_kernel  = [0 1 0; 1 -4 1; 0 1 0];
edge_pixels  = abs(conv2(double(mask), edge_kernel, 'same')) > 0;
boundary_mask = mask & edge_pixels;

[brow, bcol] = find(boundary_mask);
% Normalize pixel coords from [1,N] → [-1, +1]
bx =  (bcol - 1) / (N - 1) * 2 - 1;
by = -((brow - 1) / (N - 1) * 2 - 1);  % flip Y (image vs math coords)

% --- 3b. Internal Fill Points (sparse grid inside ink) ---
[cg, rg] = meshgrid(1:gridStep:N, 1:gridStep:N);
cg = cg(:); rg = rg(:);
valid = mask(sub2ind([N N], rg, cg)) > 0;
cx =  (cg(valid) - 1) / (N - 1) * 2 - 1;
cy = -((rg(valid) - 1) / (N - 1) * 2 - 1);

% --- 3c. Merge and deduplicate ---
P2 = unique([bx, by; cx, cy], 'rows');

fprintf('    Boundary points : %d\n', length(bx));
fprintf('    Internal points : %d\n', sum(valid));
fprintf('    Total unique pts: %d\n', size(P2, 1));

% Visualize Step 3
figure('Name', 'STEP 3: 2D Point Cloud', 'NumberTitle', 'off');
plot(cx, cy, 'g.', 'MarkerSize', 4); hold on;
plot(bx, by, 'b.', 'MarkerSize', 3);
axis equal; grid on;
legend('Internal Fill Points', 'Boundary Points', 'Location', 'best');
title('Step 3: 2D Point Cloud (Kalamkari Motif)', 'FontSize', 13, ...
    'FontWeight', 'bold');
xlabel('X (normalized)'); ylabel('Y (normalized)');

% =========================================================================
% STEP 4 — DELAUNAY TRIANGULATION + FILTERING
% =========================================================================

fprintf('\nSTEP 4: Delaunay triangulation and filtering...\n');

DT = delaunayTriangulation(P2(:,1), P2(:,2));
F  = DT.ConnectivityList;   % Triangle faces (indices)
V2 = DT.Points;             % 2D vertices

fprintf('    Raw triangles: %d\n', size(F, 1));

% --- 4a. Centroid Filter: remove triangles outside ink ---
tcx = (V2(F(:,1),1) + V2(F(:,2),1) + V2(F(:,3),1)) / 3;
tcy = (V2(F(:,1),2) + V2(F(:,2),2) + V2(F(:,3),2)) / 3;

% Map centroid back to pixel coordinates
pr = round((-tcy + 1) / 2 * (N-1) + 1);
pc = round(( tcx + 1) / 2 * (N-1) + 1);
pr = max(1, min(N, pr));
pc = max(1, min(N, pc));

keep = mask(sub2ind([N N], pr, pc)) > 0;
F = F(keep, :);
fprintf('    After centroid filter: %d triangles\n', size(F, 1));

% --- 4b. Edge Length Filter: remove stretched artifact triangles ---
a = V2(F(:,1), :);  b = V2(F(:,2), :);  c = V2(F(:,3), :);
L = max([sqrt(sum((a-b).^2, 2)), ...
         sqrt(sum((b-c).^2, 2)), ...
         sqrt(sum((c-a).^2, 2))], [], 2);
F = F(L < edgeLengthThresh, :);
fprintf('    After length filter : %d triangles\n', size(F, 1));

% Visualize Step 4
figure('Name', 'STEP 4: Filtered 2D Mesh', 'NumberTitle', 'off');
triplot(F, V2(:,1), V2(:,2), 'b-', 'LineWidth', 0.3);
axis equal; grid on;
title('Step 4: Delaunay Mesh (Filtered)', 'FontSize', 13, 'FontWeight', 'bold');
xlabel('X'); ylabel('Y');

% =========================================================================
% STEP 5 — INVERSE STEREOGRAPHIC PROJECTION ONTO SPHERE
% =========================================================================

fprintf('\nSTEP 5: Inverse stereographic projection onto sphere...\n');

% Formulas:
%   R² = X² + Y²
%   Xs = 2X / (R²+1)
%   Ys = 2Y / (R²+1)
%   Zs = (R²-1) / (R²+1)  +1  [+1 shifts sphere to sit on printer bed Z=0]

Xs = V2(:, 1);
Ys = V2(:, 2);
R2 = Xs.^2 + Ys.^2;

SP = [ 2*Xs./(R2+1), ...       % X on sphere
       2*Ys./(R2+1), ...       % Y on sphere
      (R2-1)./(R2+1) + 1 ];   % Z on sphere (shifted up by 1)

fprintf('    Projected %d vertices onto sphere surface\n', size(SP, 1));
fprintf('    Z range: [%.3f, %.3f]\n', min(SP(:,3)), max(SP(:,3)));

% =========================================================================
% STEP 6 — LAPLACIAN MESH SMOOTHING
% =========================================================================

fprintf('\nSTEP 6: Laplacian mesh smoothing (%d iterations)...\n', ...
    smoothingIter);

for it = 1:smoothingIter
    % Build adjacency matrix from triangle edges
    I = [F(:,1); F(:,2); F(:,3)];
    J = [F(:,2); F(:,3); F(:,1)];
    W = sparse(I, J, 1, size(SP,1), size(SP,1));
    W = W + W';       % make symmetric (undirected)
    W = W > 0;        % binary adjacency

    % Laplacian average: move each vertex to mean of neighbors
    deg        = sum(W, 2);
    SP_smooth  = (W * SP) ./ deg;

    % Spherical re-projection (THE SHRINK FIX):
    % Smoothing shrinks the mesh inward — re-normalize to stay on sphere
    SP_smooth(:, 3) = SP_smooth(:, 3) - 1;    % shift back to unit sphere
    norms           = sqrt(sum(SP_smooth.^2, 2));
    SP_smooth       = SP_smooth ./ norms;     % normalize to unit sphere
    SP_smooth(:, 3) = SP_smooth(:, 3) + 1;% shift back up to printer bed

    SP = SP_smooth;
end

fprintf('    Smoothing complete\n');

% Visualize Step 5+6 (sphere mesh)
figure('Name', 'STEP 5-6: Spherical Mesh', 'NumberTitle', 'off');
trisurf(F, SP(:,1), SP(:,2), SP(:,3), ...
    'FaceColor', [0.3 0.6 1.0], 'EdgeColor', [0.1 0.1 0.5], ...
    'FaceAlpha', 0.7, 'EdgeAlpha', 0.3);
axis equal; grid on; lighting phong;
camlight('headlight');
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Step 5-6: Kalamkari Motif Projected onto Sphere', ...
    'FontSize', 13, 'FontWeight', 'bold');
view(3);

% =========================================================================
% STEP 7 — SOLID EXTRUSION (Watertight Shell for 3D Printing)
% =========================================================================

fprintf('\nSTEP 7: Solid extrusion (watertight shell)...\n');

% --- 7a. Calculate outward radial normals ---
% Normal points from sphere center [0,0,1] outward
N_vec = SP - [0, 0, 1];        % vector from center to surface point
norms = sqrt(sum(N_vec.^2, 2));
N_vec = N_vec ./ norms;        % normalize to unit normals

% --- 7b. Generate outer shell vertices ---
t_prop  = Thickness_mm / PhysicalRadius_mm;%thickness as fraction of radius
SP_out  = SP + N_vec * t_prop;                 % push outward

% Combined vertex list: [inner shell; outer shell]
V_solid = [SP; SP_out];
numV    = size(SP, 1);

% --- 7c. Inner faces (normals flipped inward) ---
F_in  = F(:, [1 3 2]);         % reverse winding = inward normals

% --- 7d. Outer faces (normals outward) ---
F_out = F + numV;               % offset indices to outer shell vertices

% --- 7e. Find boundary edges and stitch rim ---
TR_flat = triangulation(F, SP);
eBnd    = freeBoundary(TR_flat);   % Nx2 list of boundary edge vertex pairs

u = eBnd(:, 1);
v = eBnd(:, 2);

% Two triangles per boundary edge quad (inner→outer wall)
F_wall1 = [u,          v,          numV+v];
F_wall2 = [u,          numV+v,     numV+u];

% --- 7f. Assemble complete solid ---
F_solid = [F_in; F_out; F_wall1; F_wall2];

fprintf('    Inner faces    : %d\n', size(F_in, 1));
fprintf('    Outer faces    : %d\n', size(F_out, 1));
fprintf('    Wall faces     : %d\n', size(F_wall1,1) + size(F_wall2,1));
fprintf('    Total faces    : %d\n', size(F_solid, 1));
fprintf('    Total vertices : %d\n', size(V_solid, 1));

% Visualize Step 7
figure('Name', 'STEP 7: Watertight Solid (3D Print Ready)', 'NumberTitle', 'off');
trisurf(F_solid, V_solid(:,1), V_solid(:,2), V_solid(:,3), ...
    'FaceColor', [0.2 0.8 0.2], 'EdgeColor', 'none', ...
    'FaceAlpha', 0.9);
axis equal; grid on; lighting phong;
camlight('left'); camlight('right');
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Step 7: Watertight Solid Shell (Ready for 3D Print)', ...
    'FontSize', 13, 'FontWeight', 'bold');
view(3);

% =========================================================================
% STEP 8 — SHADOW PREVIEW (Stereographic Projection Simulation)
% =========================================================================

fprintf('\nSTEP 8: Generating shadow projection preview...\n');

% Simulate: rays from light source Lpos through each sphere vertex
% project onto Z=0 plane (the shadow plane below)

L  = Lpos;                     % light position
Vs = SP;             % sphere vertices (inner shell = projection surface)

% Ray: P(t) = L + t*(Vs - L)
% Find t where Z = 0: L(3) + t*(Vs(:,3) - L(3)) = 0
%                     t = -L(3) / (Vs(:,3) - L(3))

t  = -L(3) ./ (Vs(:,3) - L(3));
Px = L(1) + t .* (Vs(:,1) - L(1));
Py = L(2) + t .* (Vs(:,2) - L(2));

% Visualize shadow
figure('Name', 'STEP 8: Shadow Preview on Ground Plane', 'NumberTitle', ...
    'off');
patch('Faces', F, 'Vertices', [Px, Py], ...
    'FaceColor', [0.1 0.1 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.85);
axis equal; axis off;
set(gca, 'Color', [0.95 0.95 0.90]);
title('Step 8: Simulated Shadow (Light → Sphere → Floor)', ...
    'FontSize', 13, 'FontWeight', 'bold');

% =========================================================================
% STEP 9 — SCALE TO PHYSICAL DIMENSIONS & EXPORT STL
% =========================================================================

fprintf('\nSTEP 9: Scaling to physical dimensions and exporting STL...\n');

% Scale from unit sphere to real millimeters
V_final = V_solid * PhysicalRadius_mm;

fprintf('    Sphere diameter: %.0f mm\n', PhysicalRadius_mm * 2);
fprintf('    Wall thickness : %.1f mm\n', Thickness_mm);

% --- Compute face normals for STL ---
v1 = V_final(F_solid(:,1), :);
v2 = V_final(F_solid(:,2), :);
v3 = V_final(F_solid(:,3), :);
e1 = v2 - v1;
e2 = v3 - v1;
normals = cross(e1, e2, 2);
nLen    = sqrt(sum(normals.^2, 2));
nLen(nLen == 0) = 1;           % avoid divide-by-zero
normals = normals ./ nLen;

% --- Write Binary STL ---
outFile = '2026_Maths4Des_04CAD_STL_EC23B1031._Kalamkari.stl';
fid = fopen(outFile, 'wb');

% STL binary header: 80 bytes
header = sprintf('Kalamkari Stereographic Projection - %s', datestr(now));
header = [header, blanks(80 - length(header))];
fwrite(fid, uint8(header(1:80)), 'uint8');

% Number of triangles
nTri = size(F_solid, 1);
fwrite(fid, uint32(nTri), 'uint32');

% Write each triangle
for i = 1:nTri
    fwrite(fid, single(normals(i,:)), 'float32');     % normal vector
    fwrite(fid, single(v1(i,:)),      'float32');     % vertex 1
    fwrite(fid, single(v2(i,:)),      'float32');     % vertex 2
    fwrite(fid, single(v3(i,:)),      'float32');     % vertex 3
    fwrite(fid, uint16(0),            'uint16');      % attribute byte count
end

fclose(fid);

fprintf('    STL exported: %s\n', outFile);
fprintf('    File size   : %.1f KB\n', dir(outFile).bytes / 1024);

% =========================================================================
% FINAL SUMMARY
% =========================================================================

fprintf('\n==============================================\n');
fprintf('  PIPELINE COMPLETE!\n');
fprintf('==============================================\n');
fprintf('  Image loaded       : %s\n', fname);
fprintf('  Vertices (solid)   : %d\n', size(V_solid, 1));
fprintf('  Triangles (solid)  : %d\n', size(F_solid, 1));
fprintf('  Sphere diameter    : %d mm\n', PhysicalRadius_mm * 2);
fprintf('  Wall thickness     : %.1f mm\n', Thickness_mm);
fprintf('  Output STL file    : %s\n', outFile);
fprintf('\n  NEXT STEPS:\n');
fprintf('  1. Open %s in Cura / PrusaSlicer\n', outFile);
fprintf('  2. Verify: no holes, wall thickness ~%.0fmm\n', Thickness_mm);
fprintf('  3. Print with supports if needed\n');
fprintf('  4. Place point light source at TOP of sphere\n');
fprintf('  5. Shadow below = your original Kalamkari motif!\n');
fprintf('==============================================\n');

% =========================================================================
% BONUS: ALL FIGURES SUMMARY VIEW
% =========================================================================

figure('Name', 'FULL PIPELINE SUMMARY', 'NumberTitle', 'off', ...
    'Position', [50 50 1400 800]);

subplot(2,3,1);
imshow(mask);
title('1. Binary Mask', 'FontWeight', 'bold');

subplot(2,3,2);
plot(P2(:,1), P2(:,2), 'b.', 'MarkerSize', 2);
axis equal; grid on;
title('2. Point Cloud', 'FontWeight', 'bold');

subplot(2,3,3);
triplot(F, V2(:,1), V2(:,2), 'b-', 'LineWidth', 0.3);
axis equal; grid on;
title('3. Filtered Mesh', 'FontWeight', 'bold');

subplot(2,3,4);
trisurf(F, SP(:,1), SP(:,2), SP(:,3), ...
    'FaceColor', [0.3 0.6 1], 'EdgeColor', [0 0 0.5], ...
    'FaceAlpha', 0.7, 'EdgeAlpha', 0.2);
axis equal; lighting phong; camlight;
view(3);
title('4. Sphere Projection', 'FontWeight', 'bold');

subplot(2,3,5);
trisurf(F_solid, V_solid(:,1), V_solid(:,2), V_solid(:,3), ...
    'FaceColor', [0.2 0.8 0.2], 'EdgeColor', 'none', 'FaceAlpha', 0.9);
axis equal; lighting phong; camlight;
view(3);
title('5. Watertight Solid', 'FontWeight', 'bold');

subplot(2,3,6);
patch('Faces', F, 'Vertices', [Px, Py], ...
    'FaceColor', [0.1 0.1 0.1], 'EdgeColor', 'none', 'FaceAlpha', 0.85);
axis equal; axis off;
set(gca, 'Color', [0.95 0.95 0.90]);
title('6. Shadow Preview', 'FontWeight', 'bold');

sgtitle('KALAMKARI STEREOGRAPHIC PROJECTION — Full Pipeline', ...
    'FontSize', 15, 'FontWeight', 'bold');

fprintf('\nAll figures generated. Check each figure window.\n');