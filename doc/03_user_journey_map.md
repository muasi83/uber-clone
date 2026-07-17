================================================================================
                         RIDE NOW - USER JOURNEY MAP
         Complete Experience: Screens, Actions, Emotions, Touchpoints
================================================================================


================================================================================
JOURNEY 1: RIDER — COMPLETE RIDE JOURNEY
================================================================================

PHASE 1: OPENING THE APP
─────────────────────────────────────────────────────────────────────

  Screen:         Splash Screen → Auth Screen (if first time) → Rider Home
  Action:         Open app, login with email/password
  Emotion:        😐 Neutral → 😊 Positive (if fast load)
  Touchpoint:     Mobile device, WiFi/Mobile data
  Backend Call:   POST /api/auth/login
  WebSocket:      Connection established
  Duration:       5-10 seconds
  Pain Points:    Slow splash, login form errors
  Success:        Sees personalized home screen with map


PHASE 2: REQUESTING A RIDE
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Home → Pickup Location → Dropoff Location → Ride Preview
  Action:         Tap "Where to?" → Set pickup → Set dropoff → See route + fare
  Emotion:        😊 Excited → 🤔 Thinking (comparing prices) → 😃 Decided
  Touchpoint:     Map interaction, address search, fare display
  Backend Call:   GET /api/routes/calculate (fare estimate)
  External:       Google Maps API (route + directions)
  Duration:       30-60 seconds
  Pain Points:    Slow geocoding, inaccurate fare estimate, map lag
  Success:        Sees accurate route, fare, and ride type options


PHASE 3: WAITING FOR A DRIVER
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Searching Screen
  Action:         Wait for driver to accept, see timer counting up
  Emotion:        😃 Hopeful → 😟 Anxious (after 30s) → 😰 Worried (after 60s)
  Touchpoint:     Timer animation, search radius display
  Backend Call:   POST /api/rides/request
  WebSocket:      ride_available → nearby drivers, ride_accepted → rider
  Scheduler:      Timeout at 60s (expand radius), 120s (cancel)
  Duration:       10-120 seconds
  Pain Points:    Long wait, no driver found, timeout cancellation
  Success:        Driver accepts within 30 seconds
  Emotion at Success: 😄 Relieved and happy


PHASE 4: TRACKING DRIVER
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Tracking Screen
  Action:         Watch driver move on map in real-time
  Emotion:        😊 Watching, 😃 Getting closer, 😄 Almost there
  Touchpoint:     Real-time car icon on map, ETA countdown
  Backend Call:   WebSocket: driver_location updates
  External:       Google Maps (polyline rendering)
  Duration:       3-15 minutes (depends on distance)
  Pain Points:    Location lag, incorrect ETA, map not updating
  Success:        Smooth tracking, accurate ETA


PHASE 5: DRIVER ARRIVES
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Tracking → Rider Active Ride
  Action:         Driver taps "I've Arrived" → Rider notified
  Emotion:        😄 Excited, 😊 Ready to go
  Touchpoint:     Notification popup, screen transition
  Backend Call:   POST /api/rides/{id}/driver-arrived
  WebSocket:      driver_arrived event
  Duration:       1-2 minutes (waiting for pickup)
  Pain Points:    Driver arrives at wrong spot, no communication
  Mitigation:     Chat feature available
  Success:        Smooth pickup


PHASE 6: DURING THE RIDE
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Active Ride Screen + Chat Screen
  Action:         Track route, chat with driver, monitor ETA
  Emotion:        😊 Comfortable, 😃 Enjoying ride, 🤔 Checking ETA
  Touchpoint:     Map route, chat, ETA display
  Backend Call:   WebSocket: driver_location (continuous)
  External:       Google Maps (route to destination)
  Duration:       10-45 minutes
  Pain Points:    Wrong route, communication issues, slow ride
  Mitigation:     Chat for communication, call button
  Success:        Safe, timely arrival at destination


PHASE 7: RIDE COMPLETED + PAYMENT
─────────────────────────────────────────────────────────────────────

  Screen:         Rider Ride Completed Screen
  Action:         View trip summary, select payment method, pay
  Emotion:        😊 Satisfied (if smooth ride) → 😃 Happy
  Touchpoint:     Fare display, payment options, wallet balance
  Backend Call:   POST /api/payments/{id}/confirm
  Duration:       15-30 seconds
  Pain Points:    Wrong fare, payment failure, wallet insufficient
  Success:        Payment processed, receipt shown


PHASE 8: RATING
─────────────────────────────────────────────────────────────────────

  Screen:         Rating Section (on Ride Completed screen)
  Action:         Rate driver 1-5 stars, optional feedback
  Emotion:        😊 Grateful → 😃 Done, back to normal
  Touchpoint:     Star selector, text input
  Backend Call:   POST /api/ratings
  Duration:       10-20 seconds
  Pain Points:    Forgot to rate, accidental rating
  Success:        Rating submitted, back to home


─────────────────────────────────────────────────────────────────────
RIDER JOURNEY EMOTIONAL MAP:

  😃 ╱╲        ╱╲           ╱╲
  😊╱  ╲   ╱╲╱  ╲     ╱╲╱  ╲╱╲
  😐    ╲╱      ╲╱╲ ╱        ╲
  😟              ╲╱
  😰
  ├──────┼────────┼─────────┼────────┼──────────┤
  Open  Request  Waiting  Tracking  Ride     Rating
  App   Ride     Driver   Driver   Complete
─────────────────────────────────────────────────────────────────────


================================================================================
JOURNEY 2: DRIVER — COMPLETE RIDE JOURNEY
================================================================================

PHASE 1: GOING ONLINE
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Home Screen
  Action:         Toggle "Online" switch, wait for ride requests
  Emotion:        😊 Ready, 💪 Motivated
  Touchpoint:     Online/Offline toggle, status indicator
  Backend Call:   POST /api/drivers/toggle-online
  WebSocket:      online event
  Duration:       1-5 minutes (waiting)
  Pain Points:    Toggle doesn't work, no ride requests
  Success:        Online, ready to receive requests


PHASE 2: RECEIVING A RIDE REQUEST
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Home → Ride Preview Dialog
  Action:         Hear notification, see ride details, accept/decline
  Emotion:        😮 Surprise → 🤔 Evaluating → 😊 Accepted
  Touchpoint:     Audio alert, vibration, ride details card
  Backend Call:   WebSocket: ride_available
  Duration:       5-15 seconds (decision time)
  Pain Points:    Missed notification, too far away, low fare
  Success:        Accepts a profitable nearby ride


PHASE 3: NAVIGATING TO RIDER
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Navigation Screen
  Action:         Follow route to pickup, open Google Maps if needed
  Emotion:        😊 Focused, 😃 Getting closer
  Touchpoint:     Map route, "Open in Maps" button, ETA
  Backend Call:   WebSocket: driver_location (updates sent to rider)
  External:       Google Maps Navigation (optional)
  Duration:       3-15 minutes
  Pain Points:    Wrong pickup location, traffic, wrong turn
  Success:        Arrives at correct pickup point


PHASE 4: PICKING UP RIDER
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Navigation → Driver Active Ride
  Action:         Tap "I've Arrived", wait for rider, start ride
  Emotion:        😊 Waiting, 😃 Rider in car, 💪 Ready
  Touchpoint:     "I've Arrived" button, "Start Ride" button
  Backend Call:   POST /api/rides/{id}/driver-arrived, POST /api/rides/{id}/start
  Duration:       2-5 minutes
  Pain Points:    Rider late, wrong location, can't find each other
  Mitigation:     Chat + Call features
  Success:        Rider picked up, ride started


PHASE 5: DRIVING TO DESTINATION
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Active Ride Screen + Chat
  Action:         Navigate to dropoff, send location updates, chat if needed
  Emotion:        😊 Driving, 😃 Close to destination
  Touchpoint:     Map route, location updates, chat
  Backend Call:   POST /api/rides/{id}/location (continuous)
  Duration:       10-45 minutes
  Pain Points:    Wrong route, rider changes destination
  Success:        Arrived at dropoff


PHASE 6: COMPLETING THE RIDE
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Active Ride → Payment Handling → Ride Summary
  Action:         Tap "Complete Ride", handle payment, confirm
  Emotion:        😄 Done! 😊 Satisfied
  Touchpoint:     Complete button, payment options, earnings display
  Backend Call:   POST /api/rides/{id}/complete
  Duration:       30-60 seconds
  Pain Points:    Payment dispute, cash unpaid, wrong amount
  Success:        Payment confirmed, earnings recorded


PHASE 7: RATING + EARNINGS
─────────────────────────────────────────────────────────────────────

  Screen:         Driver Ride Summary → Driver Home
  Action:         View earnings breakdown, rate rider, return home
  Emotion:        😊 Happy with earnings → 😃 Ready for next ride
  Touchpoint:     Earnings display, star rating, "Done" button
  Backend Call:   POST /api/ratings
  Duration:       15-30 seconds
  Pain Points:    Low earnings, bad rider experience
  Success:        Rating submitted, earnings credited, ready for next ride


─────────────────────────────────────────────────────────────────────
DRIVER JOURNEY EMOTIONAL MAP:

  😊 ╱╲     ╱╲     ╱╲       ╱╲     ╱╲
  😃╱  ╲╱╲╱  ╲╱╲ ╱  ╲╱╲  ╱  ╲╱╲╱  ╲
  😐    ╲       ╲╱      ╲╱         ╲
  😟
  ├──────┼────────┼─────────┼────────┼──────────┤
  Go     Receive  Navigate  Pick Up  Complete  Rate
  Online Request  to Rider  Rider    Ride
─────────────────────────────────────────────────────────────────────


================================================================================
JOURNEY 3: NEW USER — FIRST-TIME REGISTRATION
================================================================================

  Step 1:  Open App → Splash Screen
           Emotion: 😊 Curious
           Touchpoint: App icon, splash animation

  Step 2:  Auth Screen → Tap "Register"
           Emotion: 🤔 Considering options
           Touchpoint: Email field, password field, role selector

  Step 3:  Enter Details → Email, Password, Phone, Role (Rider/Driver)
           Emotion: 😐 Filling forms, 😟 Worried about privacy
           Touchpoint: Form fields, country code picker

  Step 4:  Submit → OTP Verification Screen
           Emotion: ⏳ Waiting for OTP, 😟 Hopeful
           Touchpoint: OTP input (6 digits), resend timer
           Backend: POST /api/auth/register → OTP email sent

  Step 5:  Enter OTP → Verified
           Emotion: 😊 Progressing
           Touchpoint: OTP fields, verify button

  Step 6:  If Driver → Driver Registration Form
           Emotion: 😊 Providing details
           Touchpoint: License number, vehicle info fields
           Backend: POST /api/drivers/register

  Step 7:  First Home Screen
           Emotion: 😃 Welcome! Ready to explore
           Touchpoint: Map, "Where to?" prompt

  Step 8:  First Ride Request
           Emotion: 😃 Excited, 😟 Nervous (first time)
           Touchpoint: Full ride flow

  Step 9:  Ride Completed + Rating
           Emotion: 😄 Happy if good experience
           Touchpoint: Rating, summary

  Step 10: Returns Home as Regular User
           Emotion: 😊 Comfortable, 😃 Will use again
           Touchpoint: Familiar home screen


─────────────────────────────────────────────────────────────────────
FIRST-TIME USER EMOTIONAL MAP:

  😊 ╱╲     ╱╲        ╱╲
  😃╱  ╲╱╲╱  ╲  ╱╲╱╲╱  ╲╱╲
  😐    ╲       ╲╱        ╲╱
  🤔
  ├──────┼────────┼─────────┼────────┤
  Open   Register Verify    First
  App    Account  OTP      Ride
─────────────────────────────────────────────────────────────────────


================================================================================
JOURNEY 4: FORGOTTEN PASSWORD RECOVERY
================================================================================

  Step 1:  Auth Screen → Tap "Forgot Password?"
           Emotion: 😟 Frustrated
           Touchpoint: Link below password field

  Step 2:  Enter Email → Submit
           Emotion: 😟 Hopeful
           Touchpoint: Email input field
           Backend: POST /api/auth/forgot-password → OTP sent

  Step 3:  OTP Screen → Enter 6-digit code
           Emotion: ⏳ Waiting, 😟 Anxious
           Touchpoint: OTP input, timer, resend button
           Backend: POST /api/auth/verify-reset-otp

  Step 4:  Reset Password Screen → Enter new password
           Emotion: 😊 Progressing
           Touchpoint: Password field, confirm field
           Backend: POST /api/auth/reset-password

  Step 5:  Success → Back to Auth Screen (login)
           Emotion: 😊 Relieved, 😃 Back to normal
           Touchpoint: Success message, auto-navigate

  Step 6:  Login with New Password
           Emotion: 😊 Successful
           Touchpoint: Auth screen, login form


================================================================================
JOURNEY 5: SCHEDULED RIDE (RIDER)
================================================================================

  Step 1:  Rider Home → Tap "Where to?"
           Emotion: 😊 Planning ahead
           Touchpoint: Map, search

  Step 2:  Set Pickup + Dropoff Locations
           Emotion: 😊 Selecting locations
           Touchpoint: Map pins, address search

  Step 3:  Ride Preview → Tap "Schedule for Later"
           Emotion: 😊 Organizing schedule
           Touchpoint: Schedule button

  Step 4:  Schedule Sheet → Pick Date + Time + Ride Type
           Emotion: 😊 Confident, 😃 Set for future
           Touchpoint: Date picker, time picker, ride type selector
           Backend: POST /api/rides/schedule

  Step 5:  Confirmation → Scheduled Ride Detail Screen
           Emotion: 😊 Done, 😃 Looking forward
           Touchpoint: Confirmation message, detail screen

  Step 6:  (Later) Ride auto-triggered at scheduled time
           Emotion: 😃 Reminded, 😊 Ready
           Touchpoint: Push notification, auto-search for driver


================================================================================
JOURNEY 6: ADMIN — INVESTIGATING A RIDE
================================================================================

  Step 1:  Admin Home Dashboard
           Emotion: 😊 Overview, 😃 In control
           Touchpoint: Stats cards, filter bar
           Backend: GET /api/admin/rides

  Step 2:  Apply Filters → Search by status, date, name
           Emotion: 😊 Narrowing down, 😃 Finding it
           Touchpoint: Filter dropdowns, search input

  Step 3:  Click Trip → Trip Details Screen
           Emotion: 😊 Investigating
           Touchpoint: Rider info, driver info, timeline
           Backend: GET /api/admin/rides/{id}

  Step 4:  Review Timeline → All state transitions with timestamps
           Emotion: 🤔 Analyzing, 😊 Understanding
           Touchpoint: Timeline list, timestamps, actor names

  Step 5:  Read Chat History → Messages between rider and driver
           Emotion: 🤔 Understanding context
           Touchpoint: Chat message list
           Backend: GET /api/admin/rides/{id}/messages

  Step 6:  Add Admin Note
           Emotion: 😊 Documenting
           Touchpoint: Note input, save button
           Backend: POST /api/admin/rides/{id}/notes

  Step 7:  Toggle "Keep Forever" (audit retention)
           Emotion: 😊 Preserving evidence
           Touchpoint: Toggle switch
           Backend: PATCH /api/admin/rides/{id}/keep-forever


================================================================================
END OF USER JOURNEY MAP
================================================================================
