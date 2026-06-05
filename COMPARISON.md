# Original Files Comparison

Downloaded from the shared Google Drive folder on 2026-06-03.

## Downloaded Sets

- `imp_and_media.zip`: bundled media/original package from Drive.
- `imp_and_media/`: extracted archive contents.
- `drive_top_level/`: additional visible top-level Drive files not all present in the archive.

## Original Runtime

The historical launch pages are small HTML wrappers for the old Imagine Logo browser plugin:

- `lunar402.HTM` embeds `lunar402.IIP` at 804 x 604.
- `lunar403.HTM` embeds `lunar403.IIP` at 804 x 604.
- `lunar588.HTM` embeds `lunar588.IIP` at 804 x 604.

The downloaded package includes large `.IMP` Imagine project files (`lunar402b.IMP`, `lunar589.IMP`, `diana.IMP`) but not the `.IIP` plugin packages named by those HTML files.

The Flash files (`demo1.swf`, `gauge_demo.swf`, `demo1.old.swf`) appear to be Captivate-style demos. Modern browsers will not run them natively without a Flash emulator or converter.

## Source And Asset Inventory

Archive contents:

- 2 `.IMP` Imagine projects: `lunar402b.IMP`, `lunar589.IMP`.
- 5 `.htm` launch/demo pages.
- 2 `.lgf` files: `diagonal_vs_h_and_v.lgf`, `velocity_vs_speed.lgf`.
- 19 GIFs, including astronaut, lander, rocks, moon/space backgrounds, and chart recorder assets.
- 25 JPGs, including teammate portraits and historical/science imagery.
- 1 WAV sound: `Phut.wav`.

Additional top-level downloads:

- `diana.IMP`.
- `extrapolate.IMP` through `extrapolate13.IMP`.
- `extrapolate.imt` and `extrapolate11.txt`.
- `demo1.swf`, `demo1.old.swf`, `gauge_demo.swf`.

## Extracted Original Behaviours

Readable strings inside the `.IMP` files expose these named fragments and messages:

- `update_velocity_and_position_code`: vertical position is updated 30 times per second from vertical velocity.
- `vertical_thruster_code`: throws projectiles according to throttle, projectile velocity, projectile mass, and the lander's mass.
- `constant_gravity_code`: gravity changes vertical velocity once per second.
- `auto_pilot_preamble_code`: generated autopilot code from recorded slider changes.
- Landing/help messages for missing programs, missing gravity, missing thrusters, safe landing setup, hovering, copying code, and flipping gadgets.

The original code emphasizes conservation of momentum. A key fragment changes vertical velocity by:

`-1 * value_of_slider_for_vertical_velocity_of_a_projectile * value_of_slider_for_mass_of_a_projectile / my_mass`

## Current Prototype Match

The modern `index.html` / `app.js` recreation already matches several core ideas:

- Browser-playable construction kit rather than a static page.
- Rescue and Lunar Lander modes.
- Behaviour gadgets with sliders.
- Code boxes showing pseudo-Logo fragments mined from the `.IMP` files.
- Gravity, velocity, fuel/projectile mass, gauges, and editable autopilot replay.
- Six original-style teammates: Jammer, Tist, Signer, Mator, Ian, and Ound.
- Original GIF/JPG/WAV assets for sprites, backgrounds, portraits, and sound.
- Object-back drag/drop and flip-over / flip-back code views.
- A stage-local `Behaviour Gadgets...` drawer modeled on the original rail workflow.

## Main Gaps

- The app is a reconstruction, not a direct execution of the original Imagine Logo runtime.
- The original `.IIP` plugin packages referenced by launch pages are missing from the downloaded set.
- The `.IMP` project files expose many labels, messages, RTF help pages, and code fragments, but they are not a complete modern JavaScript source tree.
- Some original diagnostic and help flows remain richer than the current web recreation.
- Some original gadgets, especially reached/missed ship and landing action gadgets, are represented by web game rules rather than separate attachable code boxes.

## Recommended Next Integration

1. Continue mining `.IMP` RTF strings to broaden each teammate's visit sequence.
2. Split reached/missed ship and landing action into separate draggable gadgets.
3. Add more original diagnostic messages for missing velocity, gravity, thruster, and landing action behaviours.
4. Improve the code-box editor so editable constants are visually marked like the original red RTF sections.
