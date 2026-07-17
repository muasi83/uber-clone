================================================================================
                         RIDE NOW - INFORMATION ARCHITECTURE
                    Complete App Structure & Data Organization
================================================================================


================================================================================
SECTION 1: TOP-LEVEL APP STRUCTURE
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │                        RIDE NOW APP                             │
  │                                                                 │
  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
  │  │             │  │              │  │                      │  │
  │  │   RIDER     │  │   DRIVER     │  │      ADMIN           │  │
  │  │   MODULE    │  │   MODULE     │  │      MODULE          │  │
  │  │             │  │              │  │                      │  │
  │  │  20 screens │  │  8 screens   │  │  4 screens           │  │
  │  │             │  │              │  │                      │  │
  │  └──────┬──────┘  └──────┬───────┘  └──────────┬───────────┘  │
  │         │                │                      │              │
  │         └────────────────┼──────────────────────┘              │
  │                          │                                     │
  │  ┌───────────────────────┼─────────────────────────────────┐  │
  │  │                  SHARED SERVICES                         │  │
  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │  │
  │  │  │WebSocket │ │  HTTP    │ │ Location │ │  Auth    │   │  │
  │  │  │ Service  │ │ Service  │ │ Service  │ │ Service  │   │  │
  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │  │
  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │  │
  │  │  │  Chat    │ │  Ride    │ │  Driver  │ │  Admin   │   │  │
  │  │  │ Service  │ │ Service  │ │ Service  │ │ Service  │   │  │
  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │  │
  │  └─────────────────────────────────────────────────────────┘  │
  │                          │                                     │
  │  ┌───────────────────────┼─────────────────────────────────┐  │
  │  │                    MODELS                                │  │
  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐   │  │
  │  │  │  Ride    │ │  User    │ │  Message │ │ Payment  │   │  │
  │  │  │  Model   │ │  Model   │ │  Model   │ │ Model    │   │  │
  │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘   │  │
  │  └─────────────────────────────────────────────────────────┘  │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 2: SCREEN MAP (All 32 Screens)
================================================================================

  RIDER SCREENS (20)
  ──────────────────────────────────────────────────────────────
  │                                                              │
  │  AUTH FLOW                                                   │
  │  ├── 1.  Auth Screen (Login + Register)                      │
  │  ├── 2.  OTP Verification Screen                             │
  │  ├── 3.  Forgot Password Screen                              │
  │  ├── 4.  Reset Password Screen                               │
  │  ├── 5.  Email Verification Screen                           │
  │  └── 6.  Phone Verification Screen                           │
  │                                                              │
  │  RIDE FLOW                                                   │
  │  ├── 7.  Rider Home Screen (Map)                             │
  │  ├── 8.  Rider Pickup Location Screen                        │
  │  ├── 9.  Rider Dropoff Location Screen                       │
  │  ├── 10. Ride Preview Screen                                 │
  │  ├── 11. Rider Searching Driver Screen                       │
  │  ├── 12. Rider Tracking Screen                               │
  │  ├── 13. Rider Active Ride Screen                            │
  │  ├── 14. Rider Ride Completed Screen                         │
  │  ├── 15. Ride Map Screen                                     │
  │  └── 16. Ride Location Picker Screen                         │
  │                                                              │
  │  SCHEDULED RIDE                                              │
  │  ├── 17. Scheduled Ride Detail Screen                        │
  │  └── 18. Rides Screen (Upcoming + Past)                      │
  │                                                              │
  │  PROFILE & SETTINGS                                          │
  │  ├── 19. Rider Profile Screen                                │
  │  ├── 20. Rider Location Permission Screen                    │
  │  ├── 21. Settings Screen                                     │
  │  ├── 22. Payment Methods Screen                              │
  │  └── 23. Support Screen                                      │
  │                                                              │
  │  CHAT                                                        │
  │  └── 24. Chat Screen                                         │
  │                                                              │
  │  HISTORY & TRIPS                                             │
  │  ├── 25. Trip History Screen                                 │
  │  ├── 26. Trip Replay Screen                                  │
  │  └── 27. Trip Behaviour Screen                               │
  │                                                              │
  │  SAFETY                                                      │
  │  └── 28. Safety Screen                                       │
  │                                                              │
  └─────────────────────────────────────────────────────────────

  DRIVER SCREENS (8)
  ──────────────────────────────────────────────────────────────
  │                                                              │
  │  ├── 29. Driver Home Screen                                  │
  │  ├── 30. Driver Registration Screen                          │
  │  ├── 31. Driver Navigation to Rider Screen                   │
  │  ├── 32. Driver Active Ride Screen                           │
  │  ├── 33. Driver Ride Summary Screen                          │
  │  ├── 34. Map Picker Screen                                   │
  │  └── 35. Ride Preview Screen (Driver version)                │
  │                                                              │
  └─────────────────────────────────────────────────────────────

  ADMIN SCREENS (4)
  ──────────────────────────────────────────────────────────────
  │                                                              │
  │  ├── 36. Admin Home Screen                                   │
  │  ├── 37. Admin Trip Details Screen                           │
  │  ├── 38. Admin Driver List Screen                            │
  │  └── 39. Admin Driver Details Screen                         │
  │                                                              │
  └─────────────────────────────────────────────────────────────

  SHARED / DEBUG (4)
  ──────────────────────────────────────────────────────────────
  │                                                              │
  │  ├── 40. Splash Screen                                       │
  │  ├── 41. Debug Screen                                        │
  │  ├── 42. Test WebSocket Screen                               │
  │  └── 43. Home Screen                                         │
  │                                                              │
  └─────────────────────────────────────────────────────────────


================================================================================
SECTION 3: SERVICE ARCHITECTURE (23 Services)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                    CORE SERVICES                                │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  AUTHENTICATION                                          │  │
  │  │  ├── StorageService      (JWT tokens, user data)         │  │
  │  │  ├── FirebaseService     (FCM push notifications)        │  │
  │  │  └── NotificationService (In-app notifications)          │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  COMMUNICATION                                           │  │
  │  │  ├── WebSocketService    (Real-time connection)          │  │
  │  │  ├── ChatService         (Messages, typing, delivery)    │  │
  │  │  └── PlaceSearchService  (Address autocomplete)          │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  RIDE MANAGEMENT                                         │  │
  │  │  ├── RideService         (CRUD, state transitions)       │  │
  │  │  ├── DriverService       (Profile, availability)         │  │
  │  │  ├── ScheduledRideService (Future rides)                 │  │
  │  │  ├── RideRecoveryService (Crash recovery)                │  │
  │  │  └── DirectionsService   (Route calculation)             │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  LOCATION                                                │  │
  │  │  ├── LocationService     (GPS permissions + tracking)    │  │
  │  │  ├── LocationMonitorService (Background monitoring)      │  │
  │  │  └── BackgroundNavigationService (BG location updates)   │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  UI HELPERS                                              │  │
  │  │  ├── PhotoService        (Image loading/caching)         │  │
  │  │  └── AppLifecycleObserver (App background/foreground)     │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  ADMIN                                                   │  │
  │  │  ├── AdminService        (Trip management)               │  │
  │  │  └── AdminDriversService (Driver management)             │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  │  ┌──────────────────────────────────────────────────────────┐  │
  │  │  DEBUGGING / LOGGING                                     │  │
  │  │  ├── CrashReporter      (Error logging)                  │  │
  │  │  ├── EventRecorderService (Event tracking)               │  │
  │  │  ├── UiEventRecorder    (UI event logging)               │  │
  │  │  └── NavigationRecorder (Navigation logging)             │  │
  │  └──────────────────────────────────────────────────────────┘  │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 4: DATA MODELS (5 Core Models)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │
  │  │    USER      │     │    RIDE      │     │   MESSAGE    │   │
  │  │──────────────│     │──────────────│     │──────────────│   │
  │  │ id           │◄────│ rider_id     │     │ id           │   │
  │  │ username     │     │ driver_id    │◄────│ sender_id    │   │
  │  │ email        │     │ pickup_lat   │     │ receiver_id  │   │
  │  │ password     │     │ pickup_lng   │     │ content      │   │
  │  │ full_name    │     │ pickup_addr  │     │ status       │   │
  │  │ role         │     │ dropoff_lat  │     │ ride_id      │   │
  │  │ phone        │     │ dropoff_lng  │     │ sent_at      │   │
  │  │ is_verified  │     │ dropoff_addr │     └──────────────┘   │
  │  │ is_online    │     │ status       │                        │
  │  │ device_token │     │ ride_type    │     ┌──────────────┐   │
  │  └──────┬───────┘     │ estimated_   │     │  PAYMENT     │   │
  │         │             │   fare       │     │──────────────│   │
  │         │             │ final_fare   │     │ id           │   │
  │         │             │ distance     │     │ ride_id      │   │
  │         │             │ duration     │     │ amount       │   │
  │         │             │ search_      │     │ currency     │   │
  │         │             │   radius_km  │     │ method       │   │
  │         │             │ timestamps   │     │ status       │   │
  │         │             │ version      │     └──────────────┘   │
  │         │             └──────────────┘                        │
  │         │                                                     │
  │         │             ┌──────────────┐     ┌──────────────┐   │
  │         │             │   LOCATION   │     │  SCHEDULED   │   │
  │         │             │──────────────│     │    RIDE      │   │
  │         └────────────►│ id           │     │──────────────│   │
  │                       │ user_id      │     │ id           │   │
  │                       │ ride_id      │     │ rider_id     │   │
  │                       │ latitude     │     │ pickup/      │   │
  │                       │ longitude    │     │   dropoff    │   │
  │                       │ updated_at   │     │ ride_type    │   │
  │                       └──────────────┘     │ scheduled_at │   │
  │                                            │ status       │   │
  │                                            └──────────────┘   │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 5: WIDGET LIBRARY (18 Reusable Widgets)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  LAYOUT WIDGETS                                                 │
  │  ├── MapScaffold          (Map + overlay content)               │
  │  ├── GlassCard            (Frosted glass effect)                │
  │  ├── BottomSheetHandle    (Drag handle for sheets)             │
  │  └── EmptyState           (No data placeholder)                │
  │                                                                 │
  │  FORM WIDGETS                                                   │
  │  ├── PremiumButton        (Styled action button)               │
  │  ├── PremiumCard          (Tappable card)                      │
  │  ├── PremiumTextField     (Styled input field)                 │
  │  └── ShimmerLoading       (Loading skeleton)                    │
  │                                                                 │
  │  RIDE WIDGETS                                                   │
  │  ├── DriverInfoCard       (Driver details card)                │
  │  ├── RideStatusBar        (Ride state indicator)                │
  │  ├── StatusBadge          (Status label pill)                  │
  │  └── LocationBanner       (Location warning)                    │
  │                                                                 │
  │  DIALOG WIDGETS                                                 │
  │  ├── CancelRideDialog     (Cancel confirmation)                │
  │  ├── PaymentDialog        (Payment selection)                  │
  │  └── ReceivedPaymentDialog (Cash received confirm)             │
  │                                                                 │
  │  LIST WIDGETS                                                   │
  │  ├── UpcomingRidesView    (Future rides list)                  │
  │  ├── PastRidesView        (History rides list)                 │
  │  └── ScheduleRideSheet    (Schedule ride bottom sheet)         │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 6: UTILITY LAYER (6 Utilities)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  ┌──────────────────┐  Route & Navigation                      │
  │  │  RideUtils       │  - Calculate fare                        │
  │  │                  │  - Format duration                       │
  │  │                  │  - Format distance                       │
  │  └──────────────────┘                                          │
  │                                                                 │
  │  ┌──────────────────┐  Map Markers                             │
  │  │  MarkerUtils     │  - Create pickup marker                  │
  │  │                  │  - Create dropoff marker                 │
  │  └──────────────────┘                                          │
  │                                                                 │
  │  ┌──────────────────┐  Marker Factory                          │
  │  │  MarkerFactory   │  - Create car marker                     │
  │  │                  │  - Create custom markers                 │
  │  └──────────────────┘                                          │
  │                                                                 │
  │  ┌──────────────────┐  Car Animation                           │
  │  │  MarkerAnimator  │  - Animate car movement                  │
  │  │                  │  - Smooth position transitions           │
  │  └──────────────────┘                                          │
  │                                                                 │
  │  ┌──────────────────┐  Map Styling                             │
  │  │  MapStyleLoader  │  - Load dark map style                   │
  │  │                  │  - Apply theme to map                    │
  │  └──────────────────┘                                          │
  │                                                                 │
  │  ┌──────────────────┐  Bearing Calculation                     │
  │  │  BearingUtils    │  - Calculate compass direction           │
  │  │                  │  - Rotate car icon based on heading      │
  │  └──────────────────┘                                          │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 7: THEME SYSTEM (4 Theme Files)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  ┌──────────────┐  Color Palette                               │
  │  │  AppColors   │  - Primary, Secondary, Accent                │
  │  │              │  - Background, Surface, Card                 │
  │  │              │  - Text, Error, Success, Warning             │
  │  └──────────────┘                                              │
  │                                                                 │
  │  ┌──────────────┐  Typography                                  │
  │  │  AppTypo-    │  - Headlines (H1, H2, H3)                   │
  │  │  graphy      │  - Body text (large, medium, small)         │
  │  │              │  - Labels, captions, buttons                 │
  │  └──────────────┘                                              │
  │                                                                 │
  │  ┌──────────────┐  Spacing                                     │
  │  │  AppSpacing  │  - Margins (xs, sm, md, lg, xl)             │
  │  │              │  - Paddings, gaps, border radius             │
  │  └──────────────┘                                              │
  │                                                                 │
  │  ┌──────────────┐  Theme Configuration                        │
  │  │  AppTheme    │  - Light theme definition                   │
  │  │              │  - Dark theme definition                     │
  │  │              │  - ThemeData objects                         │
  │  └──────────────┘                                              │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 8: API STRUCTURE (Backend Endpoints)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  /api/auth                                                     │
  │  ├── POST   /register          Create account                  │
  │  ├── POST   /login             Authenticate                    │
  │  ├── POST   /device-token      Register FCM token              │
  │  ├── POST   /forgot-password   Request OTP                     │
  │  ├── POST   /verify-reset-otp  Verify OTP                      │
  │  └── POST   /reset-password    Set new password                 │
  │                                                                 │
  │  /api/rides                                                    │
  │  ├── POST   /request           Create ride request             │
  │  ├── GET    /available         List available rides             │
  │  ├── POST   /{id}/accept       Accept ride                     │
  │  ├── POST   /{id}/start        Start ride                      │
  │  ├── POST   /{id}/complete     Complete ride                   │
  │  ├── POST   /{id}/driver-arrived Notify arrival                │
  │  ├── POST   /{id}/cancel       Cancel ride                     │
  │  ├── POST   /{id}/continue-search Resume search                │
  │  ├── POST   /{id}/location     Update location                 │
  │  ├── GET    /{id}              Get ride details                │
  │  ├── GET    /active            Check active ride               │
  │  ├── GET    /driver/active     Driver's active ride            │
  │  ├── GET    /user/history      Paginated history               │
  │  └── GET    /matching/*        Driver matching endpoints       │
  │                                                                 │
  │  /api/drivers                                                  │
  │  ├── POST   /register          Register as driver              │
  │  ├── GET    /profile           Get own profile                 │
  │  ├── PUT    /profile           Update profile                  │
  │  ├── POST   /location          Update GPS location             │
  │  ├── POST   /toggle-online     Go online/offline               │
  │  └── GET    /nearby            Find nearby drivers             │
  │                                                                 │
  │  /api/payments                                                 │
  │  ├── GET    /pending-ride      Get pending payment ride        │
  │  ├── GET    /{id}/status       Payment status                  │
  │  ├── POST   /{id}/confirm      Confirm payment                 │
  │  ├── POST   /{id}/receive      Driver confirms receipt         │
  │  ├── POST   /{id}/cash-received Cash confirmed                 │
  │  ├── POST   /{id}/cash-unpaid  Cash unpaid                     │
  │  └── POST   /{id}/dispute      Dispute payment                 │
  │                                                                 │
  │  /api/chat                                                     │
  │  ├── POST   /send              Send message                    │
  │  ├── GET    /history           Chat history                    │
  │  ├── POST   /{id}/mark-delivered Mark delivered                │
  │  └── POST   /{id}/mark-read    Mark read                       │
  │                                                                 │
  │  /api/ratings                                                  │
  │  ├── POST   /                  Submit rating                   │
  │  └── GET    /user/{id}         Get user ratings                │
  │                                                                 │
  │  /api/notifications                                            │
  │  ├── GET    /                  List notifications               │
  │  ├── GET    /unread-count      Unread count                     │
  │  ├── POST   /{id}/read         Mark read                       │
  │  ├── POST   /read-all          Mark all read                   │
  │  └── DELETE /                  Delete all                      │
  │                                                                 │
  │  /api/admin                                                    │
  │  ├── GET    /rides             List rides (filtered)           │
  │  ├── GET    /rides/{id}        Ride details                    │
  │  ├── GET    /rides/{id}/events Audit events                    │
  │  ├── GET    /rides/{id}/messages Chat messages                 │
  │  ├── PATCH  /rides/{id}/keep-forever Toggle retention          │
  │  ├── POST   /rides/{id}/notes  Add admin note                  │
  │  ├── GET    /drivers           List drivers                    │
  │  └── GET    /drivers/{id}      Driver details                  │
  │                                                                 │
  │  /api/locations                                                │
  │  └── POST   /update            Record location                 │
  │                                                                 │
  │  /api/routes                                                   │
  │  ├── GET    /geocode           Reverse geocode                 │
  │  └── /calculate          Calculate route                      │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 9: WEBSOCKET EVENT MAP
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  CLIENT → SERVER (Outgoing)                                     │
  │  ─────────────────────────────                                  │
  │  ├── login              (on connect)                            │
  │  ├── message            (chat message)                          │
  │  ├── typing             (typing indicator)                      │
  │  ├── message_delivered  (receipt)                               │
  │  ├── message_read       (read receipt)                          │
  │  ├── ride_status_update (state change)                          │
  │  ├── online             (go online)                             │
  │  ├── offline            (go offline)                            │
  │  ├── driver_location    (GPS update)                            │
  │  └── heartbeat          (keep-alive every 2 min)                │
  │                                                                 │
  │  SERVER → CLIENT (Incoming)                                     │
  │  ─────────────────────────────                                  │
  │  ├── ride_available         → Drivers (new ride nearby)         │
  │  ├── ride_accepted          → Rider (driver accepted)           │
  │  ├── ride_confirmed         → Other drivers (ride taken)        │
  │  ├── driver_arrived         → Rider (at pickup)                 │
  │  ├── ride_started           → Rider (trip started)              │
  │  ├── ride_completed         → Rider (trip ended)                │
  │  ├── ride_cancelled         → Rider + Driver                    │
  │  ├── search_timeout         → Rider (60s elapsed)               │
  │  ├── payment_confirmed      → Rider + Driver                    │
  │  ├── payment_finalized      → Rider + Driver                    │
  │  ├── payment_refunded       → Rider                             │
  │  ├── driver_location        → Rider (real-time GPS)             │
  │  ├── driver_heading         → Rider (compass direction)         │
  │  ├── message                → Receiver (chat)                   │
  │  ├── message_delivered      → Sender (receipt)                  │
  │  ├── message_read           → Sender (read receipt)             │
  │  ├── typing                 → Receiver (typing)                 │
  │  ├── user_online            → Both (presence)                   │
  │  ├── user_offline           → Both (presence)                   │
  │  ├── pong                   → Sender (heartbeat reply)          │
  │  └── force_logout           → Sender (duplicate login)          │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 10: DATABASE SCHEMA (14 Tables)
================================================================================

  ┌─────────────────────────────────────────────────────────────────┐
  │                                                                 │
  │  CORE TABLES                                                    │
  │  ───────────                                                    │
  │  ┌──────────┐  ┌──────────────┐  ┌──────────────┐              │
  │  │  users   │──│driver_profiles│  │   wallets    │              │
  │  └────┬─────┘  └──────────────┘  └──────┬───────┘              │
  │       │                                  │                      │
  │       │         ┌──────────────┐         │                      │
  │       ├─────────│    rides     │─────────┤                      │
  │       │         └──────┬───────┘         │                      │
  │       │                │                 │                      │
  │  TRANSACTIONS TABLES                      │                      │
  │  ──────────────────                       │                      │
  │  │         ┌──────────────┐  ┌───────────┴───────┐              │
  │  │         │   payments   │  │ wallet_transactions│              │
  │  │         └──────────────┘  └───────────────────┘              │
  │  │         ┌──────────────┐                                     │
  │  ├─────────│    ratings   │                                     │
  │  │         └──────────────┘                                     │
  │  │                                                              │
  │  COMMUNICATION TABLES                                           │
  │  ─────────────────────                                          │
  │  │         ┌──────────────┐                                     │
  │  ├─────────│   messages   │                                     │
  │  │         └──────────────┘                                     │
  │  │         ┌────────────────────┐                               │
  │  ├─────────│  notifications     │                               │
  │  │         └────────────────────┘                               │
  │  │                                                              │
  │  TRACKING TABLES                                                │
  │  ───────────────                                                │
  │  │         ┌──────────────────┐                                 │
  │  ├─────────│ location_updates │                                 │
  │  │         └──────────────────┘                                 │
  │  │         ┌───────────────────┐                                │
  │  ├─────────│ride_audit_events  │                                │
  │  │         └───────────────────┘                                │
  │  │                                                              │
  │  AUTH TABLE                                                     │
  │  ──────────                                                     │
  │  │         ┌──────────────┐                                     │
  │  └─────────│  otp_codes   │                                     │
  │            └──────────────┘                                     │
  │                                                                 │
  │  DRIVER EARNINGS                                                │
  │  ───────────────                                                │
  │            ┌──────────────────┐                                 │
  │            │ driver_earnings  │                                 │
  │            └──────────────────┘                                 │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘


================================================================================
SECTION 11: FILE STRUCTURE MAP
================================================================================

  chat_app/
  ├── lib/
  │   ├── main.dart                    (Entry point, routing, providers)
  │   │
  │   ├── models/                      (5 data models)
  │   │   ├── models.dart              (Shared exports)
  │   │   ├── ride_model.dart          (Ride data)
  │   │   ├── location_model.dart      (GPS coordinates)
  │   │   ├── scheduled_ride.dart      (Future ride)
  │   │   └── trip_events.dart         (Trip events)
  │   │
  │   ├── services/                    (23 service files)
  │   │   ├── websocket_service.dart   (WS connection)
  │   │   ├── ride_service.dart        (Ride CRUD)
  │   │   ├── chat_service.dart        (Messaging)
  │   │   ├── driver_service.dart      (Driver ops)
  │   │   ├── location_service.dart    (GPS tracking)
  │   │   ├── firebase_service.dart    (Push notif)
  │   │   ├── notification_service.dart(In-app notif)
  │   │   ├── storage_service.dart     (Local storage)
  │   │   ├── admin_service.dart       (Admin ops)
  │   │   ├── admin_drivers_service.dart (Admin drivers)
  │   │   ├── directions_service.dart  (Routes)
  │   │   ├── place_search_service.dart(Geocoding)
  │   │   ├── photo_service.dart       (Images)
  │   │   ├── scheduled_ride_service.dart (Scheduling)
  │   │   ├── ride_recovery_service.dart (Crash recovery)
  │   │   ├── location_monitor_service.dart (BG monitor)
  │   │   ├── background_navigation_service.dart (BG nav)
  │   │   ├── trip_behaviour_service.dart (Trip analytics)
  │   │   ├── app_lifecycle_observer.dart (Lifecycle)
  │   │   ├── crash_reporter.dart      (Error logging)
  │   │   ├── event_recorder_service.dart (Event tracking)
  │   │   ├── ui_event_recorder.dart   (UI events)
  │   │   ├── navigation_recorder.dart (Nav tracking)
  │   │   └── recorded_screen_mixin.dart (Recording mixin)
  │   │
  │   ├── screens/                     (30+ screen files)
  │   │   ├── auth_screen.dart
  │   │   ├── splash_screen.dart
  │   │   ├── home_screen.dart
  │   │   ├── rider_home_screen.dart
  │   │   ├── driver_home_screen.dart
  │   │   ├── chat_screen.dart
  │   │   ├── admin_home_screen.dart
  │   │   ├── settings_screen.dart
  │   │   └── ... (25+ more)
  │   │
  │   ├── widgets/                     (18 reusable widgets)
  │   │   ├── premium_button.dart
  │   │   ├── premium_card.dart
  │   │   ├── glass_card.dart
  │   │   ├── map_scaffold.dart
  │   │   └── ... (14 more)
  │   │
  │   ├── utils/                       (6 utility files)
  │   │   ├── ride_utils.dart
  │   │   ├── marker_utils.dart
  │   │   ├── marker_factory.dart
  │   │   ├── marker_animator.dart
  │   │   ├── map_style_loader.dart
  │   │   └── bearing_utils.dart
  │   │
  │   └── theme/                       (4 theme files)
  │       ├── app_colors.dart
  │       ├── app_typography.dart
  │       ├── app_spacing.dart
  │       └── app_theme.dart
  │
  ├── assets/
  │   ├── images/                      (App icons, images)
  │   └── map_style.json               (Dark map style)
  │
  ├── android/                         (Android platform)
  ├── ios/                             (iOS platform)
  ├── web/                             (Web platform)
  ├── windows/                         (Windows platform)
  ├── macos/                           (macOS platform)
  └── linux/                           (Linux platform)


================================================================================
END OF INFORMATION ARCHITECTURE
================================================================================
