# Vessel Track Map Viewer: Design & Rationale Document

## Executive Summary

This document describes the design and implementation of a web-based interactive map viewer for visualizing vessel tracks over time-series satellite imagery. The viewer was specifically designed for exploring Antarctic research vessel data (RSV Nuyina) overlaid on sea ice concentration imagery, but the architecture is generalizable to any vessel track and georeferenced imagery use case.

## Project Context & Goals

### Primary Use Case
Visualize the RSV Nuyina's movements through Antarctic waters in relation to sea ice conditions over multiple years (2020-present). The tool enables researchers to:
- Explore vessel movements during specific time periods
- Correlate vessel routes with sea ice conditions
- Identify patterns across multiple voyages
- Share interactive visualizations with colleagues

### Key Requirements
1. Handle custom map projections (Transverse Mercator centered on 115°E)
2. Display daily satellite imagery with automatic fallback for missing dates
3. Show vessel tracks with hourly position data
4. Enable temporal exploration across 5+ years of data
5. Work entirely in-browser without requiring a server-side mapping stack
6. Support future extensibility (different projections, regions, vessels)

## Architecture Overview

### Technology Stack
- **Pure HTML5/JavaScript/Canvas**: No framework dependencies for maximum portability
- **proj4js**: Client-side coordinate transformation library
- **Canvas 2D**: High-performance rendering for imagery and vector overlays
- **Natural Earth Data**: Global coastline geometries via CDN

### Data Sources
1. **Satellite Imagery**: Daily PNG files (sea ice concentration from NOAA)
2. **Vessel Track**: JSON file with hourly position data (longitude, latitude, datetime)
3. **Projection Metadata**: GDAL PAM XML files (.aux.xml) for automatic configuration
4. **Coastline Data**: GeoJSON from Natural Earth via CDN

### Key Design Decision: No Web Mapping Library

**Decision**: Build a custom viewer rather than use Leaflet/OpenLayers/MapLibre.

**Rationale**:
- Standard web mapping libraries assume spherical Mercator (Web Mercator/EPSG:3857)
- Custom projections require significant workarounds in these libraries
- Full control over rendering pipeline enables optimization for our specific use case
- Simpler codebase without framework abstraction layers
- Direct canvas rendering provides better performance for large imagery

**Trade-offs**:
- Had to implement pan/zoom manually (relatively straightforward)
- No built-in tile pyramid support (not needed for our resolution)
- Custom coordinate transformation logic (handled cleanly by proj4js)

## Core Features & Design Rationale

### 1. Dual-Range Time Slider

**Feature**: Two sliders (start/end) defining a temporal window, with draggable range bar.

**Rationale**:
- Single-date views don't show vessel movement context
- Range selection allows "show me the track from X to Y"
- Draggable range enables quick temporal scanning with constant window size
- Natural for voyage-based exploration (e.g., "December to March voyage")

**Implementation Details**:
- Blue slider: Start date (left thumb)
- Red slider: End date (right thumb)
- Blue highlight bar: Draggable to shift entire window
- Sliders prevent crossing (start must be ≤ end)
- Background image aligns to end date (most recent conditions for the track)

### 2. Year-Based Pagination

**Feature**: Navigate between year-long periods with Previous/Next buttons.

**Rationale**:
- 5+ years of daily data = 1,800+ dates
- Showing all dates in one slider is unusable
- Year-long pages provide natural seasonal boundaries
- June 1st boundaries align with Antarctic field season
- Each page maintains manageable slider resolution (~365 positions)

**Implementation**:
- `daysPerPage = 365` configurable
- Pages can be non-calendar-aligned (June-to-June for seasonal context)
- Automatic page advancement during animation playback
- Page info shows date range and position (e.g., "Page 5/6")

**Future Enhancement**: Replace fixed pages with voyage-based boundaries detected from track gaps.

### 3. Animation Controls

**Features**:
- Play forward (▶)
- Reverse (◀)
- Pause (⏸)
- Variable speed (0.1s to 2.0s per frame)
- Snap-to-start/end buttons (⏮ ⏭)

**Rationale**:
- Passive observation mode for presentations
- Reverse allows backing up to interesting events
- Speed control adapts to different use cases (quick scan vs. detailed observation)
- Snap buttons enable quick navigation within periods

**Implementation Details**:
- Animation moves entire time window (both start and end dates)
- Maintains constant range duration during animation
- Automatically pages when reaching period boundaries
- Spacebar toggles play/pause for keyboard-driven workflow

### 4. Automatic Metadata Loading

**Feature**: Read projection, extent, and dimensions from GDAL .aux.xml sidecar files.

**Rationale**:
- Eliminates need to hardcode projection parameters
- Supports easy switching between projections/regions
- Single source of truth (matches the imagery exactly)
- Standard GDAL format ensures compatibility

**Implementation**:
- Parses PAM XML on startup
- Extracts SRS (projection string), GeoTransform, and raster dimensions
- Falls back through dates if most recent .aux.xml unavailable
- Initializes proj4js transformer automatically

**Workflow**: Update imagery → no code changes needed → viewer adapts automatically

### 5. Image Fallback System

**Feature**: Automatically uses most recent available image if requested date is missing.

**Rationale**:
- Satellite data has 1-2 day latency
- Processing pipelines may have gaps
- Users shouldn't see blank maps for missing dates
- Timeline can extend to "today" while images lag behind

**Implementation**:
- Tries requested date first
- On 404, tries previous day, recursively
- Caches loaded images to avoid re-fetching
- Status message indicates when fallback is used
- Vessel track shows current data even when image is older

### 6. Coordinate Transformation Pipeline

**Feature**: proj4js transforms vessel track from WGS84 lon/lat to custom projection pixels.

**Rationale**:
- Vessel data is naturally in geographic coordinates (GPS)
- Imagery is in arbitrary projected coordinate systems
- Transformation must happen client-side for flexibility
- proj4js handles complex projection math reliably

**Pipeline**:
```
WGS84 (lon, lat)
  → proj4.forward()
  → Projected coords (x, y meters)
  → Linear transform
  → Pixel coords (x, y in image space)
```

**Key Code**:
```javascript
const [x, y] = state.transformer.forward([lon, lat]);
const pixelX = ((x - extent.xmin) / (extent.xmax - extent.xmin)) * imageWidth;
const pixelY = ((extent.ymax - y) / (extent.ymax - extent.ymin)) * imageHeight;
```

### 7. Coastline Overlay

**Feature**: Toggleable white coastline overlay with wrap-around artifact filtering.

**Rationale**:
- Geographic context aids interpretation
- White semi-transparent lines don't obscure ice data
- Toggle allows users to remove distraction if needed
- Natural Earth simplified data provides good performance

**Challenge**: Projection discontinuities create spurious long lines across the map.

**Solution**: Geometric filtering removes segments longer than 20% of image height.
```javascript
const distance = Math.sqrt(dx*dx + dy*dy);
if (distance > maxSegmentLength) {
    // Start new segment, discard wrap-around line
}
```

**Benefit**: Works for any projection orientation (vertical or horizontal discontinuities).

### 8. Precise Datetime Readouts

**Feature**: Display exact UTC timestamps for range endpoints (YYYY-MM-DD HH:MM:SS UTC).

**Rationale**:
- Daily slider positions are ambiguous (00:00:00 on that date)
- Vessel track has hourly precision
- UTC standard for global vessel operations
- Unambiguous communication with colleagues ("from 2024-06-15 00:00:00 to 2024-07-01 00:00:00 UTC")

**Design**: Monospace grey text, right-aligned, minimal visual weight.

### 9. Keyboard Shortcuts

**Feature**: Home, End, Space, Arrow keys for navigation.

**Rationale**:
- Power users prefer keyboard-driven workflows
- Reduces mouse travel for repeated operations
- Industry-standard mappings (Home/End for beginning/end)
- Space for play/pause follows media player conventions

**Mappings**:
- `Home`: Snap to start of period (or previous period if already at start)
- `End`: Snap to end of period (or next period if already at end)
- `Space`: Toggle play/pause
- `←/→`: Previous/next period

## Technical Implementation Details

### Canvas Rendering Pipeline

1. **Clear canvas** (black background)
2. **Draw background image** (scaled and positioned)
3. **Draw coastline** (if enabled, white semi-transparent)
4. **Draw vessel track** (red line for date range)
5. **Draw current position marker** (red circle with white outline)

### State Management

Single `state` object contains:
- Canvas/context references
- Date arrays (all dates, current page dates)
- Pagination state (current page, total pages)
- Time range indices (start/end)
- Transform state (scale, pan offset)
- Interaction state (dragging, animation ID)
- Data (vessel track, coastline, current image)

**No React/Vue**: State changes trigger explicit `render()` and `updateDisplay()` calls.

### Performance Optimizations

1. **Image caching**: Loaded images stored by URL to avoid re-fetching
2. **Coordinate pre-computation**: Vessel track transformed to pixels once on load
3. **Coastline filtering**: Geometry simplified at load time, not per-frame
4. **Canvas-only rendering**: No DOM manipulation during animation
5. **Throttled updates**: Animations run at configurable frame rate (default 500ms)

### Data Flow

```
User interaction (slider, button, keyboard)
  ↓
Update state variables
  ↓
Update UI elements (slider positions, text)
  ↓
updateDisplay() → loadImageWithFallback() → render()
  ↓
Canvas redraw with new image/track
```

## Future Enhancements

### Voyage-Based Navigation (Planned)

**Current**: Fixed year-long pages starting June 1st.

**Proposed**: Automatic voyage detection from track gaps.

**Implementation**:
1. Analyze vessel track for periods with no movement >7 days
2. Generate voyage boundaries automatically
3. Replace page navigation with voyage dropdown
4. "Voyage 1: 2020-12-15 to 2021-03-20"

**Benefits**:
- More intuitive for voyage-centric workflows
- Handles variable-length field seasons
- No manual configuration required

### Additional Data Layers

**Potential additions**:
- Bathymetry contours
- Sea ice edge
- Weather station locations
- Other vessel tracks (for comparison)

**Implementation approach**: Additional toggle buttons, separate render passes.

### Multi-Vessel Support

**Use case**: Compare multiple vessels or vessel vs. model trajectories.

**Design considerations**:
- Multiple JSON track files
- Color-coded tracks
- Toggle visibility per vessel
- Synchronized time ranges

### Export Capabilities

**Requested features**:
- Export current view as PNG
- Generate animated GIF of time range
- CSV export of visible track segment

## Deployment & Maintenance

### Hosting Architecture

**Current**: All resources on Pawsey S3-compatible storage
- HTML viewer: `https://projects.pawsey.org.au/nuyina.map/index.html`
- Imagery: `https://projects.pawsey.org.au/nuyina.map/NOAA/G02135/YYYY/*.png`
- Vessel track: `https://projects.pawsey.org.au/nuyina.map/vessel_track_hourly.json`

**Benefits**:
- No CORS issues (same origin)
- Fast delivery (Pawsey infrastructure)
- Simple updates (overwrite files)
- No build process required

### Update Workflow

**Daily automated process**:
1. Generate new satellite PNGs (with .aux.xml sidecars)
2. Update vessel track JSON from source database
3. Upload to Pawsey storage
4. Viewer automatically reflects new data (no code changes)

**Projection/region changes**:
1. Generate new imagery in desired projection
2. Update `imageBaseUrl` in CONFIG
3. Optionally update `startDate`/`daysPerPage` for new region

### Data Preparation

**Vessel track JSON generation** (R script):

```r
#d <- arrow::read_parquet("https://github.com/mdsumner/uwy.new/releases/download/v0.0.1/nuyina_underway.parquet")
d <- nuyina.underway::nuyina_underway() |> dplyr::select(datetime, longitude, latitude)
library(dplyr)
dh <- d |>
  dplyr::filter(format(datetime, "%M") %in% c("00", "10", "20", "30", "40", "50", "60"))

jsonlite::write_json(dh, "vessel_track_hourly.json", pretty = FALSE)

#system("aws s3 --profile pawsey1197 cp vessel_track_hourly.json s3://nuyina.map/vessel/vessel_track_hourly.json")

```

**Image generation**:

Code in project: https://github.com/mdsumner/seaice.map

## Lessons Learned

### What Worked Well

1. **proj4js integration**: Seamless coordinate transformation without server-side processing
2. **Canvas rendering**: Excellent performance, direct control over drawing
3. **Metadata-driven design**: .aux.xml approach enables true flexibility
4. **Pagination strategy**: Year-long pages balance usability and detail
5. **Fallback mechanisms**: Graceful degradation when data is incomplete

### Challenges Overcome

1. **Projection discontinuities**: Solved with geometric segment filtering
2. **CORS complexity**: Resolved by consolidating hosting
3. **Date range UX**: Multiple iterations to arrive at dual-slider design
4. **Animation smoothness**: Careful state management to avoid flicker
5. **Coastline performance**: Natural Earth's 110m simplification was key

### Design Trade-offs

| Choice | Benefit | Cost |
|--------|---------|------|
| No mapping framework | Projection flexibility | Manual pan/zoom |
| Client-side processing | No server required | Browser RAM usage |
| Daily imagery | Manageable file sizes | Temporal granularity |
| Year-based pages | Usable slider | Less flexibility than voyage-based |
| PNG images | Universal support | Larger than COG tiles |

## Technical Specifications

### Browser Compatibility
- Chrome/Edge 90+ (tested)
- Firefox 88+ (tested)
- Safari 14+ (expected, not tested)

### Dependencies
- proj4js 2.9.0+ (CDN: cdnjs.cloudflare.com)
- Natural Earth data (CDN: raw.githubusercontent.com)

### Performance Characteristics
- Initial load: ~2-5 seconds (depends on network)
- Vessel track: 21,000 points → ~2MB JSON → instant rendering
- Coastline: ~130 line segments → sub-second load and transform
- Image loading: ~500KB per PNG → 1-2 seconds per date
- Animation: 60+ FPS at default speed, smooth pan/zoom

### Data Volumes
- Imagery: ~180MB per year (365 days × ~500KB)
- Vessel track: ~2MB per year (hourly data)
- Total bandwidth for 5 years: ~900MB imagery + 10MB tracks

## Conclusion

This viewer demonstrates that sophisticated geospatial visualization can be achieved with lightweight web technologies when the problem is well-scoped. By focusing on a specific use case (vessel tracks over custom-projection imagery) rather than building a general-purpose mapping application, we achieved:

- **Simplicity**: Single HTML file, no build system
- **Flexibility**: Projection-agnostic via metadata
- **Performance**: Smooth interaction with large datasets
- **Extensibility**: Clear architecture for adding features

The design choices reflect the realities of Antarctic research data: custom projections, moderate spatial resolution, high temporal resolution, and the need for accessible interactive visualization without complex infrastructure.

## References & Resources

- **proj4js**: https://proj4js.org/
- **Natural Earth Data**: https://www.naturalearthdata.com/
- **GDAL PAM Format**: https://gdal.org/drivers/raster/pam.html
- **NOAA Sea Ice Data**: https://nsidc.org/data/g02135

## Contact & Acknowledgments

**Development**: Michael Sumner, Australian Antarctic Division
**Data Sources**: NOAA/NSIDC (sea ice), AAD (vessel tracks)
**Infrastructure**: Pawsey Supercomputing Research Centre

---

*Document Version 1.0 - December 2024*
