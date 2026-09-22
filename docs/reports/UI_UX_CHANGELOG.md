# UI/UX Changelog

## Phase 0 — Foundation Release (Design System Migration)
- Phase 1: Brand system (colors, typography, spacing, radius, shadows, theme)
- Phase 2: 19 shared widgets + marker factory
- Phase 2.5: Bottom nav theme consistency
- Phase 3: Splash screen redesign
- Phase 4: Rider home token migration
- Phase 5: Driver home token migration
- Phase 6: 6 tracking screens token migration
- Phase 7: Chat screen token migration
- Phase 8: Loading/empty/error state widgets
- Phase 9: 26 remaining screens token migration
- Phase 10: Final polish + BoxShadow cleanup + audit

## Premium UX Redesign — Tier 1 (Layout & Hierarchy)

### Rider Home
- Reduced default bottom sheet height from 35% → 25% for a more glanceable interface
- Added floating gradient overlay above sheet for visual separation from map
- Quick destination chips on collapsed sheet (3 most recent dropoff addresses)
- Premium search bar: larger (60px), rounded (xl), with shadow, tinted icon
- Richer trip cards: larger icons, relative timestamps, fare display, pill badges
- Polished floating buttons with AppShadows instead of raw elevation
- Animated loading state with location icon

### Driver Home
- Large pill online/offline toggle (28px padding, 100 border radius) with pulsing dot animation
- Online state shows ride count subtitle ("5 rides nearby")
- New earnings card showing "Today's earnings" below top bar when online
- Premium active ride card: rider avatar, visual route connector (green dot→red dot with line), address hierarchy, timer chip
- Enhanced ride request cards: avatar initials, fare pill, visual route connector, "View" button
- New `_PulsingDot` animated widget for online status

### Rider Tracking
- Driver card: 28px radius avatar, titleLarge name, gold star ratings, chat button with unread badge
- ETA as hero element: large number (titleLarge w800) in a primary-tinted capsule
- Animated progress bar with gradient fill (TweenAnimationBuilder 0→0.85 over 1.5s)
- Clean status row with pulse dot + StatusBadge
- "Calculating..." placeholder when ETA not yet available

### Rider Active Ride
- Hero ETA: centered vertical layout with "Estimated arrival" label + large time in primary capsule
- Animated progress bar with gradient (TweenAnimationBuilder 0→0.65 over 1.5s)
- All text migrated from const TextStyle to theme.textTheme
- Premium destination section with label, address, coordinates hierarchy
- Driver info reduced to compact (16px radius) at bottom of panel

### Driver Navigation to Rider
- Premium address card: card-within-card pattern, "PICKUP" label with letter spacing
- Time and distance as symmetrical cards (headlineMedium numbers in surfaceVariant containers)
- Smooth arrival overlay with scale bounce animation (easeOutBack curve)
- All text uses theme.textTheme, all spacing uses AppSpacing tokens

### Driver Active Ride
- Ride progress header with gradient card when active: elapsed time in displaySmall with tabularFigures
- Premium destination card with card-within-card pattern and "DESTINATION" label
- Time + distance as symmetrical cards matching navigation screen
- New `_PulseAnimation` widget for "Waiting for payment..." text (0.4→1.0 opacity loop)
- All text uses theme.textTheme, all spacing uses AppSpacing tokens

### Chat Screen
- Premium AppBar: surface background with elevation, animated typing dots (3 bouncing dots via sin() math)
- Modern message bubbles: top corners 20px, bottom 20px/4px, increased padding
- Date separators: "Today"/"Yesterday"/formatted date in centered chips
- Quick replies: 4 contextual ActionChips ("On my way", "Be there soon", "Thanks!", "OK") above input bar
- Refined input bar: 28px radius text field, increased padding, quick replies integrated
- Premium empty state: 120px icon circle, larger text, better spacing

## Remaining Opportunities
- RTL direction support
- Dark mode verification across all redesigned screens
- Tier 2 screens (Chat Details, Trip Details, Ride Selection, Ride Completed, Profile)
- Haptic feedback on interactions
- Reduced motion accessibility
- Font scaling (accessibility)
