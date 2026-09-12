# Framing Rules v2

This project now uses safety-first framing.

### Replaced rule
Old rule: all frames of an exercise should use the same crop.

### New rule
- Setup frame may use a different crop from motion frames.
- Motion frames must share the same camera angle and crop.
- No relevant limb may be cropped.
- Wider framing is preferred over cropped motion clarity.

### Validation flags
```yaml
setup_frame_may_use_different_crop: true
motion_frames_same_camera: true
motion_frames_same_crop: true
no_relevant_limb_cropping: true
active_limb_safe_margin_min: 0.05
```
