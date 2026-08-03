// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get $$locale => 'en';

  @override
  String get ridenow => 'RideNow';

  @override
  String get navigationError => 'Navigation Error';

  @override
  String get ok => 'OK';

  @override
  String get rideAccepted => 'Ride Accepted';

  @override
  String get aDriverIsOnTheirWayToPickYouUp =>
      'A driver is on their way to pick you up';

  @override
  String get rideConfirmed => 'Ride Confirmed';

  @override
  String get yourRideHasBeenConfirmed => 'Your ride has been confirmed';

  @override
  String get driverArrived => 'Driver Arrived';

  @override
  String get yourDriverHasArrivedAtThePickupLocation =>
      'Your driver has arrived at the pickup location';

  @override
  String get rideStarted => 'Ride Started';

  @override
  String get yourRideHasStarted => 'Your ride has started';

  @override
  String get rideCompleted => 'Ride Completed';

  @override
  String get youHaveReachedYourDestination =>
      'You have reached your destination';

  @override
  String get rideCancelled => 'Ride Cancelled';

  @override
  String get theRideHasBeenCancelled => 'The ride has been cancelled';

  @override
  String get noDriversFound => 'No Drivers Found';

  @override
  String get noDriversAreAvailableNearbyRightNow =>
      'No drivers are available nearby right now';

  @override
  String get paymentConfirmed => 'Payment Confirmed';

  @override
  String get paymentHasBeenConfirmed => 'Payment has been confirmed';

  @override
  String get paymentFinalized => 'Payment Finalized';

  @override
  String get yourPaymentHasBeenFinalized => 'Your payment has been finalized';

  @override
  String get paymentRefunded => 'Payment Refunded';

  @override
  String get yourPaymentHasBeenRefunded => 'Your payment has been refunded';

  @override
  String get someone => 'Someone';

  @override
  String missingArgumentsFor(String route) {
    return 'Missing arguments for $route';
  }

  @override
  String invalidArguments(String route) {
    return 'Invalid $route arguments';
  }

  @override
  String get missingDriverRegistrationData =>
      'Missing driver registration data';

  @override
  String get missingDriverSessionData => 'Missing driver session data';

  @override
  String get rideAlerts => 'Ride Alerts';

  @override
  String get highpriorityRideRequestNotifications =>
      'High-priority ride request notifications';

  @override
  String get chatMessages => 'Chat Messages';

  @override
  String get newChatMessagesDuringYourRide =>
      'New chat messages during your ride';

  @override
  String get dollar => '\$';

  @override
  String get sar => 'SAR';

  @override
  String get syp => 'SYP';

  @override
  String get newRideRequest => 'New Ride Request';

  @override
  String get aPassengerNeedsARide => 'A passenger needs a ride!';

  @override
  String get pleaseEnterAValidEmailAddress =>
      'Please enter a valid email address';

  @override
  String get passwordMustBeAtLeast6Characters =>
      'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get login => 'Login';

  @override
  String get signUp => 'Sign Up';

  @override
  String get getStartedCreateYourAccount => 'Get started — Create your account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get rider => 'Rider';

  @override
  String get driver => 'Driver';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get anErrorOccurredPleaseTryAgain =>
      'An error occurred. Please try again.';

  @override
  String get pleaseEnterAPassword => 'Please enter a password';

  @override
  String get anErrorOccurredDuringRegistrationPleaseTryAgain =>
      'An error occurred during registration. Please try again.';

  @override
  String get loginFailedPleaseCheckYourCredentialsAndTryAgain =>
      'Login failed. Please check your credentials and try again.';

  @override
  String get registrationSuccessfulPleaseCheckYourEmailForVerification =>
      'Registration successful! Please check your email for verification.';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get passwordCannotBeEmpty => 'Password cannot be empty';

  @override
  String get enterPassword => 'Enter Password';

  @override
  String get submit => 'Submit';

  @override
  String get goBack => 'Go Back';

  @override
  String get forgotYourPassword => 'Forgot your password?';

  @override
  String get useOtpInstead => 'Use OTP Instead';

  @override
  String get loading => 'Loading...';

  @override
  String get forgotPassword2 => 'Forgot Password';

  @override
  String get enterYourEmailAddressAndWellSendYouAResetLink =>
      'Enter your email address and we\'ll send you a reset link';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get sending => 'Sending...';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get resetLinkSentCheckYourEmail => 'Reset link sent! Check your email';

  @override
  String get emailNotFound => 'Email not found';

  @override
  String get errorSendingResetLinkPleaseTryAgain =>
      'Error sending reset link. Please try again.';

  @override
  String get pleaseEnterAValidEmail => 'Please enter a valid email';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get enterYourNewPassword => 'Enter your new password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get resetting => 'Resetting...';

  @override
  String get passwordResetSuccessful => 'Password reset successful';

  @override
  String get errorResettingPassword => 'Error resetting password';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String aVerificationEmailHasBeenSentTo(String email) {
    return 'A verification email has been sent to $email';
  }

  @override
  String get pleaseCheckYourInboxAndClickTheVerificationLink =>
      'Please check your inbox and click the verification link';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get emailResent => 'Email resent';

  @override
  String get verifiedRedirecting => 'Verified! Redirecting...';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get iveVerifiedMyEmail => 'I\'ve verified my email';

  @override
  String get checking => 'Checking...';

  @override
  String get didntReceiveTheEmailCheckYourSpamFolder =>
      'Didn\'t receive the email? Check your spam folder';

  @override
  String get changeEmailAddress => 'Change email address';

  @override
  String get verifyYourPhone => 'Verify Your Phone';

  @override
  String get enterYourPhoneNumber => 'Enter your phone number';

  @override
  String get wellSendYouAVerificationCodeViaSms =>
      'We\'ll send you a verification code via SMS';

  @override
  String get sendCode => 'Send Code';

  @override
  String codeSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get changePhoneNumber => 'Change phone number';

  @override
  String get phoneVerifiedSuccessfully => 'Phone verified successfully';

  @override
  String get invalidPhoneNumber => 'Invalid phone number';

  @override
  String get errorSendingCode => 'Error sending code';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String enterTheCodeSentTo(String phone_or_email) {
    return 'Enter the code sent to $phone_or_email';
  }

  @override
  String get didntReceiveTheCode => 'Didn\'t receive the code?';

  @override
  String get resendCode => 'Resend Code';

  @override
  String get verify => 'Verify';

  @override
  String get verifying => 'Verifying...';

  @override
  String get invalidCodePleaseTryAgain => 'Invalid code. Please try again.';

  @override
  String get codeVerifiedSuccessfully => 'Code verified successfully';

  @override
  String get codeExpiredRequestANewOne => 'Code expired. Request a new one';

  @override
  String resendCodeIn(String seconds) {
    return 'Resend code in $seconds';
  }

  @override
  String get setADestinationToGetStarted => 'Set a destination to get started';

  @override
  String get whereTo => 'Where to?';

  @override
  String get enterDestination => 'Enter destination...';

  @override
  String get searchResultsFor => 'Search results for:';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get requestANewRide => 'Request a new ride';

  @override
  String get ride => 'Ride';

  @override
  String get scheduleARideForLater => 'Schedule a ride for later';

  @override
  String get schedule => 'Schedule';

  @override
  String get connectionLostRetrying => 'Connection lost — retrying...';

  @override
  String get myLocation => 'My Location';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get dropoffLocation => 'Dropoff location';

  @override
  String get currentLocation => 'Current location';

  @override
  String min(String min) {
    return '$min min';
  }

  @override
  String km(String distance) {
    return '$distance km';
  }

  @override
  String get findingYourLocation => 'Finding your location...';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get locationPermissionPermanentlyDeniedEnableInSettings =>
      'Location permission permanently denied — enable in Settings';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get enableLocationServices => 'Enable location services';

  @override
  String get locationServicesAreDisabled => 'Location services are disabled';

  @override
  String get noInternetConnectionShowingOfflineMap =>
      'No internet connection — showing offline map';

  @override
  String get networkError => 'Network error';

  @override
  String get setPickupLocation => 'Set pickup location';

  @override
  String get searchAddress => 'Search address...';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get confirmPickupLocation => 'Confirm pickup location';

  @override
  String get searchResults => 'Search results:';

  @override
  String get noResults => 'No results';

  @override
  String get dragTheMapToSetPickupPoint => 'Drag the map to set pickup point';

  @override
  String get locationAccessDenied => 'Location access denied';

  @override
  String get gettingCurrentLocation => 'Getting current location...';

  @override
  String get pickupPoint => 'Pickup point';

  @override
  String get searchDestination => 'Search destination...';

  @override
  String get setDestination => 'Set destination';

  @override
  String get confirmDestination => 'Confirm destination';

  @override
  String get promoApplied => 'Promo applied';

  @override
  String get baseFare => 'Base fare';

  @override
  String distanceKm(String distance) {
    return 'Distance ($distance km)';
  }

  @override
  String get total => 'Total';

  @override
  String get confirmRide => 'Confirm Ride';

  @override
  String get requesting => 'Requesting...';

  @override
  String get promoCode => 'Promo code';

  @override
  String get enterPromoCode => 'Enter promo code';

  @override
  String get apply => 'Apply';

  @override
  String get invalidPromoCode => 'Invalid promo code';

  @override
  String get noRideTypesAvailableInYourArea =>
      'No ride types available in your area';

  @override
  String get routeNotAvailableNoRoadsNearPickup =>
      'Route not available — no roads near pickup';

  @override
  String get noPriceAvailable => 'No price available';

  @override
  String get wallet => 'Wallet';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get tripDetails => 'Trip details';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get distance => 'Distance';

  @override
  String get duration => 'Duration';

  @override
  String get fare => 'Fare';

  @override
  String get requestRide => 'Request Ride';

  @override
  String rideType(String type) {
    return 'Ride type: $type';
  }

  @override
  String get estimatedArrival => 'Estimated arrival';

  @override
  String get priceBreakdown => 'Price breakdown';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get totalFare => 'Total fare';

  @override
  String get payment => 'Payment';

  @override
  String get pickup => 'Pickup';

  @override
  String get selectRideType => 'Select ride type';

  @override
  String get chooseRide => 'Choose Ride';

  @override
  String get authenticationError => 'Authentication error';

  @override
  String get failedToRequestRide => 'Failed to request ride';

  @override
  String get searchingForADriver => 'Searching for a driver...';

  @override
  String get searchingForNearbyDrivers => 'Searching for nearby drivers...';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get findingYourDriver => 'Finding your driver...';

  @override
  String estimatedWaitTime(String time) {
    return 'Estimated wait time: $time';
  }

  @override
  String get driverFound => 'Driver found!';

  @override
  String get yourDriverIsOnTheWay => 'Your driver is on the way';

  @override
  String arrivingIn(String time) {
    return 'Arriving in $time';
  }

  @override
  String get driverArrived2 => 'Driver arrived';

  @override
  String get tripStartedHeadingToDestination =>
      'Trip started — heading to destination';

  @override
  String arrivingInMin(String min) {
    return 'Arriving in $min min';
  }

  @override
  String get callDriver => 'Call driver';

  @override
  String get messageDriver => 'Message driver';

  @override
  String get shareTripStatus => 'Share trip status';

  @override
  String get emergency => 'Emergency';

  @override
  String get cancelRide => 'Cancel ride';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get areYouSureYouWantToCancelThisRide =>
      'Are you sure you want to cancel this ride?';

  @override
  String get no => 'No';

  @override
  String get yes => 'Yes';

  @override
  String get enterYourMessage => 'Enter your message';

  @override
  String get send => 'Send';

  @override
  String chatWith(String name) {
    return 'Chat with $name';
  }

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String pickupInMin(String min) {
    return 'Pickup in $min min';
  }

  @override
  String get arrivingAtDestination => 'Arriving at destination';

  @override
  String paymentMethod2(String method) {
    return 'Payment method: $method';
  }

  @override
  String totalFare2(String amount) {
    return 'Total fare: $amount';
  }

  @override
  String get viewOnMap => 'View on map';

  @override
  String get rideCancelled2 => 'Ride cancelled';

  @override
  String get cancelReason => 'Cancel reason';

  @override
  String get trackingYourDriver => 'Tracking your driver';

  @override
  String driverIsMetersAway(String distance) {
    return 'Driver is $distance meters away';
  }

  @override
  String driverIsKmAway(String distance) {
    return 'Driver is $distance km away';
  }

  @override
  String driverArrivingInMin(String min) {
    return 'Driver arriving in $min min';
  }

  @override
  String get pickupLocationReached => 'Pickup location reached';

  @override
  String get driverHasArrived => 'Driver has arrived';

  @override
  String get tripInProgress => 'Trip in progress';

  @override
  String get driverIsHeadingToDestination => 'Driver is heading to destination';

  @override
  String estimatedArrivalInMin(String min) {
    return 'Estimated arrival in $min min';
  }

  @override
  String get call => 'Call';

  @override
  String get message => 'Message';

  @override
  String get share => 'Share';

  @override
  String get shareYourTrip => 'Share your trip';

  @override
  String imOnARideWithTrackMyTrip(String name, String link) {
    return 'I\'m on a ride with $name. Track my trip: $link';
  }

  @override
  String get tripCompleted => 'Trip completed';

  @override
  String get youHaveArrived => 'You have arrived';

  @override
  String payment2(String method) {
    return 'Payment: $method';
  }

  @override
  String get rideCompleted2 => 'Ride completed!';

  @override
  String get thanksForRidingWithUs => 'Thanks for riding with us';

  @override
  String get rateYourDriver => 'Rate your driver';

  @override
  String get howWasYourTrip => 'How was your trip?';

  @override
  String get addAComment => 'Add a comment';

  @override
  String get leaveAReview => 'Leave a review...';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get yourDriverWas => 'Your driver was';

  @override
  String tripFare(String amount) {
    return 'Trip fare: $amount';
  }

  @override
  String get receipt => 'Receipt';

  @override
  String get viewReceipt => 'View receipt';

  @override
  String get reportAnIssue => 'Report an issue';

  @override
  String get rideAgain => 'Ride again';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get email => 'Email';

  @override
  String get profilePhoto => 'Profile Photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get weNeedYourLocationToFindNearbyDriversAndProvideAccuratePickup =>
      'We need your location to find nearby drivers and provide accurate pickup';

  @override
  String get allowLocationAccess => 'Allow Location Access';

  @override
  String get notNow => 'Not now';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get locationPermissionIsRequiredToUseThisApp =>
      'Location permission is required to use this app';

  @override
  String get enableLocationServicesToRequestRides =>
      'Enable location services to request rides';

  @override
  String get account => 'Account';

  @override
  String get myProfile => 'My Profile';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get safety => 'Safety';

  @override
  String get support => 'Support';

  @override
  String get settings => 'Settings';

  @override
  String get logOut => 'Log Out';

  @override
  String get areYouSureYouWantToLogOut => 'Are you sure you want to log out?';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get switchToDriver => 'Switch to Driver';

  @override
  String get switchToRider => 'Switch to Rider';

  @override
  String get addPaymentMethod => 'Add Payment Method';

  @override
  String get creditCard => 'Credit Card';

  @override
  String get debitCard => 'Debit Card';

  @override
  String get cardNumber => 'Card Number';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get cvv => 'CVV';

  @override
  String get cardholderName => 'Cardholder Name';

  @override
  String get saveCard => 'Save Card';

  @override
  String get remove => 'Remove';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get defaultText => 'Default';

  @override
  String get noPaymentMethodsAdded => 'No payment methods added';

  @override
  String get addAPaymentMethodToGetStarted =>
      'Add a payment method to get started';

  @override
  String get cardExpired => 'Card expired';

  @override
  String get invalidCardNumber => 'Invalid card number';

  @override
  String get enterYourCardDetails => 'Enter your card details';

  @override
  String get adding => 'Adding...';

  @override
  String get cardAddedSuccessfully => 'Card added successfully';

  @override
  String get failedToAddCard => 'Failed to add card';

  @override
  String get areYouSureYouWantToRemoveThisCard =>
      'Are you sure you want to remove this card?';

  @override
  String get notifications => 'Notifications';

  @override
  String get privacy => 'Privacy';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get systemDefault => 'System Default';

  @override
  String get about => 'About';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get licenses => 'Licenses';

  @override
  String appVersion(String version) {
    return 'App Version: $version';
  }

  @override
  String get rateTheApp => 'Rate the App';

  @override
  String get shareTheApp => 'Share the App';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get areYouSureYouWantToDeleteYourAccountThisCannotBeUndone =>
      'Are you sure you want to delete your account? This cannot be undone';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get smsNotifications => 'SMS notifications';

  @override
  String get emailNotifications => 'Email notifications';

  @override
  String get rideUpdates => 'Ride updates';

  @override
  String get promotionsAndOffers => 'Promotions and offers';

  @override
  String get chatMessages2 => 'Chat messages';

  @override
  String get sound => 'Sound';

  @override
  String get vibration => 'Vibration';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get reportAProblem => 'Report a Problem';

  @override
  String get howCanWeHelpYou => 'How can we help you?';

  @override
  String get describeYourIssue => 'Describe your issue...';

  @override
  String get submitting => 'Submitting...';

  @override
  String get messageSentSuccessfully => 'Message sent successfully';

  @override
  String get failedToSendMessagePleaseTryAgain =>
      'Failed to send message. Please try again.';

  @override
  String emailUsAt(String email) {
    return 'Email us at $email';
  }

  @override
  String get callUs => 'Call us';

  @override
  String get liveChat => 'Live Chat';

  @override
  String supportHours(String hours) {
    return 'Support hours: $hours';
  }

  @override
  String get wellGetBackToYouWithin24Hours =>
      'We\'ll get back to you within 24 hours';

  @override
  String get safetyFeatures => 'Safety Features';

  @override
  String get shareMyTrip => 'Share My Trip';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get reportAnIncident => 'Report an Incident';

  @override
  String get n247Support => '24/7 Support';

  @override
  String get locationSharing => 'Location Sharing';

  @override
  String get trustedContacts => 'Trusted Contacts';

  @override
  String get addEmergencyContact => 'Add emergency contact';

  @override
  String get callEmergencyServices => 'Call emergency services';

  @override
  String get yourSafetyIsOurPriority => 'Your safety is our priority';

  @override
  String get rideCheck => 'Ride Check';

  @override
  String get shareYourRideStatusWithTrustedContacts =>
      'Share your ride status with trusted contacts';

  @override
  String get audioRecordingDuringTrip => 'Audio recording during trip';

  @override
  String get speedAlerts => 'Speed alerts';

  @override
  String get driverIdentityVerification => 'Driver identity verification';

  @override
  String get inappEmergencyButton => 'In-app emergency button';

  @override
  String get manageEmergencyContacts => 'Manage emergency contacts';

  @override
  String get noEmergencyContactsAdded => 'No emergency contacts added';

  @override
  String get addContact => 'Add contact';

  @override
  String get removeContact => 'Remove contact';

  @override
  String get areYouSureYouWantToRemoveThisEmergencyContact =>
      'Are you sure you want to remove this emergency contact?';

  @override
  String get enterYourDestination => 'Enter your destination';

  @override
  String get chooseOnMap => 'Choose on map';

  @override
  String get setPickupOnMap => 'Set pickup on map';

  @override
  String get setDropoffOnMap => 'Set dropoff on map';

  @override
  String get pleaseSelectAPickupLocation => 'Please select a pickup location';

  @override
  String get pleaseSelectADropoffLocation => 'Please select a dropoff location';

  @override
  String get continueText => 'Continue';

  @override
  String get recentPlaces => 'Recent places';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get home => 'Home';

  @override
  String get work => 'Work';

  @override
  String get addAPlace => 'Add a place';

  @override
  String get search => 'Search...';

  @override
  String get gettingAddress => 'Getting address...';

  @override
  String get noRecentPlaces => 'No recent places';

  @override
  String get setLocation => 'Set location';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get map => 'Map';

  @override
  String get searchResults2 => 'Search results';

  @override
  String get dragTheMapToSetLocation => 'Drag the map to set location';

  @override
  String get rideMap => 'Ride map';

  @override
  String get loadingMap => 'Loading map...';

  @override
  String get mapError => 'Map error';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get tripPreview => 'Trip Preview';

  @override
  String distance2(String distance) {
    return 'Distance: $distance';
  }

  @override
  String duration2(String duration) {
    return 'Duration: $duration';
  }

  @override
  String fareEstimate(String fare) {
    return 'Fare estimate: $fare';
  }

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get dropoff => 'Dropoff';

  @override
  String rider2(String name) {
    return 'Rider: $name';
  }

  @override
  String rating(String rating) {
    return 'Rating: $rating';
  }

  @override
  String get yourRides => 'Your Rides';

  @override
  String get past => 'Past';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get noPastRides => 'No past rides';

  @override
  String get noUpcomingRides => 'No upcoming rides';

  @override
  String get noScheduledRides => 'No scheduled rides';

  @override
  String fromTo(String pickup, String dropoff) {
    return 'From $pickup to $dropoff';
  }

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String scheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get viewDetails => 'View details';

  @override
  String passengers(String count) {
    return '$count passengers';
  }

  @override
  String rideOn(String date) {
    return 'Ride on $date';
  }

  @override
  String get redirecting => 'Redirecting...';

  @override
  String get welcome => 'Welcome';

  @override
  String get continueAsRider => 'Continue as Rider';

  @override
  String get continueAsDriver => 'Continue as Driver';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get confirm => 'Confirm';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get debugLogs => 'Debug Logs';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get copyLogs => 'Copy logs';

  @override
  String get logsCopiedToClipboard => 'Logs copied to clipboard';

  @override
  String get logsCleared => 'Logs cleared';

  @override
  String get noLogs => 'No logs';

  @override
  String get shareLogs => 'Share logs';

  @override
  String get filter => 'Filter';

  @override
  String get all => 'All';

  @override
  String get info => 'Info';

  @override
  String get warning => 'Warning';

  @override
  String get error => 'Error';

  @override
  String get toggleServerUrl => 'Toggle server URL';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get update => 'Update';

  @override
  String get enterServerUrl => 'Enter server URL';

  @override
  String get showDebugBanner => 'Show debug banner';

  @override
  String get hideDebugBanner => 'Hide debug banner';

  @override
  String get simulateRideEvents => 'Simulate ride events';

  @override
  String get exportLogs => 'Export logs';

  @override
  String get downloadingLogs => 'Downloading logs...';

  @override
  String get tripHistory => 'Trip History';

  @override
  String get noTripsYet => 'No trips yet';

  @override
  String get yourCompletedTripsWillAppearHere =>
      'Your completed trips will appear here';

  @override
  String completedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String fare2(String amount) {
    return 'Fare: $amount';
  }

  @override
  String get viewTrip => 'View trip';

  @override
  String driver2(String name) {
    return 'Driver: $name';
  }

  @override
  String get filterBy => 'Filter by';

  @override
  String get today => 'Today';

  @override
  String get customRange => 'Custom range';

  @override
  String get searchTrips => 'Search trips...';

  @override
  String get noTripsFound => 'No trips found';

  @override
  String get failedToLoadTrips => 'Failed to load trips';

  @override
  String get tripBehaviour => 'Trip Behaviour';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get recording => 'Recording...';

  @override
  String get recordingStarted => 'Recording started';

  @override
  String get recordingStopped => 'Recording stopped';

  @override
  String recordedEvents(String count) {
    return 'Recorded events: $count';
  }

  @override
  String get clearEvents => 'Clear events';

  @override
  String get exportEvents => 'Export events';

  @override
  String get eventsExported => 'Events exported';

  @override
  String get noEventsRecorded => 'No events recorded';

  @override
  String get eventType => 'Event Type';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get details => 'Details';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get replay => 'Replay';

  @override
  String get eventLog => 'Event log';

  @override
  String get recordingSaved => 'Recording saved';

  @override
  String get failedToSaveRecording => 'Failed to save recording';

  @override
  String get tripReplay => 'Trip Replay';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get restart => 'Restart';

  @override
  String speedX(String speed) {
    return 'Speed: ${speed}x';
  }

  @override
  String get replaySpeed => 'Replay speed';

  @override
  String get tripTimeline => 'Trip timeline';

  @override
  String get noTripDataToReplay => 'No trip data to replay';

  @override
  String get loadingReplay => 'Loading replay...';

  @override
  String get replayComplete => 'Replay complete';

  @override
  String tripDuration(String duration) {
    return 'Trip duration: $duration';
  }

  @override
  String get mapView => 'Map view';

  @override
  String get listView => 'List view';

  @override
  String eventAt(String type, String time) {
    return 'Event: $type at $time';
  }

  @override
  String get close => 'Close';

  @override
  String get scheduledRideIn30Min => 'Scheduled ride in 30 min';

  @override
  String get scheduledRideWasCancelled => 'Scheduled ride was cancelled';

  @override
  String get aScheduledRideWasCancelledByTheRider =>
      'A scheduled ride was cancelled by the rider';

  @override
  String get aScheduledRideHasExpired => 'A scheduled ride has expired';

  @override
  String get rideHasBeenCancelled => 'Ride has been cancelled';

  @override
  String get pleaseEnableGpslocationServices =>
      'Please enable GPS/Location services';

  @override
  String get locationPermissionIsRequired => 'Location permission is required';

  @override
  String get locationPermissionDeniedPleaseEnableInSettings =>
      'Location permission denied. Please enable in settings.';

  @override
  String get recenterMap => 'Recenter map';

  @override
  String get activeRide => 'Active Ride';

  @override
  String get pickupEtaMin => 'Pickup ETA: -- min';

  @override
  String get navigate => 'Navigate';

  @override
  String get menu => 'Menu';

  @override
  String get toggleOnlineStatus => 'Toggle online status';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get goOnline => 'Go Online';

  @override
  String get noNearbyRides => 'No nearby rides';

  @override
  String rideNearby(String count) {
    return '$count ride nearby';
  }

  @override
  String ridesNearby(String count) {
    return '$count rides nearby';
  }

  @override
  String get availableRides => 'Available Rides';

  @override
  String get noRidesAvailable => 'No rides available';

  @override
  String get newRideRequestsWillAppearHere =>
      'New ride requests will appear here';

  @override
  String get availableNow => 'Available Now';

  @override
  String get scheduledRides => 'Scheduled Rides';

  @override
  String get myUpcoming => 'My Upcoming';

  @override
  String get todaysEarnings => 'Today\'s earnings';

  @override
  String get financialSummary => 'Financial Summary';

  @override
  String get lifetimeEarnings => 'Lifetime Earnings';

  @override
  String get platformFees15 => 'Platform Fees (15%)';

  @override
  String get amountSettled => 'Amount Settled';

  @override
  String get outstandingBalance => 'Outstanding Balance';

  @override
  String lastSettlement(String date) {
    return 'Last Settlement: $date';
  }

  @override
  String get profile => 'Profile';

  @override
  String get rating2 => 'Rating';

  @override
  String get totalRides => 'Total Rides';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get na => 'N/A';

  @override
  String get view => 'View';

  @override
  String get arrived => 'Arrived';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get acceptScheduledRide => 'Accept Scheduled Ride';

  @override
  String acceptRideScheduledFor(String date) {
    return 'Accept ride scheduled for $date?';
  }

  @override
  String get ignore => 'Ignore';

  @override
  String get scheduledRideAccepted => 'Scheduled ride accepted';

  @override
  String get cancelScheduledRide => 'Cancel Scheduled Ride';

  @override
  String get releaseThisRideSoOtherDriversCanAcceptIt =>
      'Release this ride so other drivers can accept it?';

  @override
  String get keep => 'Keep';

  @override
  String get release => 'Release';

  @override
  String get scheduledRideReleased => 'Scheduled ride released';

  @override
  String get markedAsArrivedAskRiderForPickupCode =>
      'Marked as arrived — ask rider for pickup code';

  @override
  String get enterPickupCode => 'Enter Pickup Code';

  @override
  String get askTheRiderForThe6digitPickupCode =>
      'Ask the rider for the 6-digit pickup code';

  @override
  String get verifyStart => 'Verify & Start';

  @override
  String get invalidCodePleaseTryAgain2 => 'Invalid code — please try again';

  @override
  String get rideStartedNavigatingToTrip => 'Ride started — navigating to trip';

  @override
  String get debug => 'Debug';

  @override
  String get logout => 'Logout';

  @override
  String get available => 'Available';

  @override
  String get readyToStart => 'Ready to Start';

  @override
  String get chatWithRider => 'Chat with rider';

  @override
  String get chatWithRider2 => 'Chat with Rider';

  @override
  String get toggleDriverMarker => 'Toggle driver marker';

  @override
  String get rideStarted2 => 'Ride started!';

  @override
  String get theRiderCancelledTheRide => 'The rider cancelled the ride.';

  @override
  String reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get destination => 'DESTINATION';

  @override
  String get didTheCustomerPayInCash => 'Did the customer pay in cash?';

  @override
  String get cashReceived => 'Cash Received';

  @override
  String get processing => 'Processing...';

  @override
  String get didNotPay => 'Did Not Pay';

  @override
  String get completeRide => 'Complete Ride';

  @override
  String get completing => 'Completing...';

  @override
  String get startRide => 'Start Ride';

  @override
  String get navigateToDestination => 'Navigate to Destination';

  @override
  String get couldNotOpenMapsLinkCopiedToClipboard =>
      'Could not open Maps — link copied to clipboard';

  @override
  String get rideInProgress => 'Ride in progress';

  @override
  String get back => 'Back';

  @override
  String get navigateToRider => 'Navigate to Rider';

  @override
  String get yourLocation => 'Your Location';

  @override
  String pickup2(String address) {
    return 'Pickup: $address';
  }

  @override
  String get riderNotified => 'Rider notified!';

  @override
  String get rideWasCancelled => 'Ride was cancelled';

  @override
  String get pickup3 => 'PICKUP';

  @override
  String get iveArrived => 'I\'ve Arrived';

  @override
  String get notifying => 'Notifying...';

  @override
  String get openGoogleMaps => 'Open Google Maps';

  @override
  String get cancelRide2 => 'Cancel Ride';

  @override
  String get youHaveArrived2 => 'You have arrived!';

  @override
  String get riderHasBeenNotified => 'Rider has been notified';

  @override
  String get goBack2 => 'Go back';

  @override
  String registrationStepOf(String current, String total) {
    return 'Registration step $current of $total';
  }

  @override
  String get becomeADriver => 'Become a Driver';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get vehicleInformation => 'Vehicle Information';

  @override
  String get reviewSubmit => 'Review & Submit';

  @override
  String get enterYourDrivingLicenseDetails =>
      'Enter your driving license details';

  @override
  String get tellUsAboutYourVehicle => 'Tell us about your vehicle';

  @override
  String get verifyYourInformationBeforeSubmitting =>
      'Verify your information before submitting';

  @override
  String get licenseNumber => 'License Number';

  @override
  String get egDl123456789 => 'e.g., DL123456789';

  @override
  String get vehicleNumber => 'Vehicle Number';

  @override
  String get egAbc1234 => 'e.g., ABC-1234';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get car => 'Car';

  @override
  String get bike => 'Bike';

  @override
  String get van => 'Van';

  @override
  String get vehicleModel => 'Vehicle Model';

  @override
  String get egToyotaCamry => 'e.g., Toyota Camry';

  @override
  String get vehicleColor => 'Vehicle Color';

  @override
  String get egWhite => 'e.g., White';

  @override
  String get vehicleYear => 'Vehicle Year';

  @override
  String get license => 'License';

  @override
  String get nextStep => 'Next step';

  @override
  String get submitRegistration => 'Submit registration';

  @override
  String get submitRegistration2 => 'Submit Registration';

  @override
  String get previousStep => 'Previous step';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get driverProfileRegistered => 'Driver profile registered!';

  @override
  String get driverProfileRegistrationFailedYouMayAlreadyBeRegistered =>
      'Driver profile registration failed. You may already be registered.';

  @override
  String get pleaseEnterYourLicenseNumber => 'Please enter your license number';

  @override
  String get pleaseFillAllVehicleFields => 'Please fill all vehicle fields';

  @override
  String get reviewYourDetails => 'Review your details';

  @override
  String stepOf(String current, String total) {
    return 'Step $current of $total';
  }

  @override
  String get rideSummary => 'Ride Summary';

  @override
  String get rideCompletedSuccessfully => 'Ride completed successfully';

  @override
  String get rideComplete => 'Ride Complete!';

  @override
  String minutes(String duration) {
    return '$duration minutes';
  }

  @override
  String get totalFare3 => 'Total Fare';

  @override
  String get pending => 'PENDING';

  @override
  String get yourEarnings => 'Your Earnings';

  @override
  String get platformFee => 'Platform Fee';

  @override
  String get rateYourRider => 'Rate your rider';

  @override
  String get additionalFeedbackOptional => 'Additional feedback (optional)';

  @override
  String get submitRating2 => 'Submit Rating';

  @override
  String get ratingSubmittedThankYou => 'Rating submitted — thank you!';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get pleaseSelectARating => 'Please select a rating';

  @override
  String get adminTripInvestigation => 'Admin — Trip Investigation';

  @override
  String get drivers => 'Drivers';

  @override
  String get earnings => 'Earnings';

  @override
  String get rideId => 'Ride ID';

  @override
  String get status => 'Status';

  @override
  String get riderName => 'Rider Name';

  @override
  String get driverName => 'Driver Name';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get search2 => 'Search';

  @override
  String get clear => 'Clear';

  @override
  String get retry => 'Retry';

  @override
  String get unknown => 'Unknown';

  @override
  String get failedToLoadDriverDetails => 'Failed to load driver details';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get active => 'Active';

  @override
  String get blocked => 'Blocked';

  @override
  String get verified => 'Verified';

  @override
  String get unverified => 'Unverified';

  @override
  String get onRide => 'On Ride';

  @override
  String get unverify => 'Unverify';

  @override
  String get block => 'Block';

  @override
  String get unblock => 'Unblock';

  @override
  String get model => 'Model';

  @override
  String get color => 'Color';

  @override
  String get plate => 'Plate';

  @override
  String get type => 'Type';

  @override
  String get statistics => 'Statistics';

  @override
  String get rides => 'Rides';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get lastSeen => 'Last Seen';

  @override
  String get currentRide => 'Current Ride';

  @override
  String get ride2 => 'Ride #';

  @override
  String get recentRides => 'Recent Rides';

  @override
  String get blockThisDriverTheyWillBeUnableToLoginOrAcceptRides =>
      'Block this driver? They will be unable to login or accept rides.';

  @override
  String get unblockThisDriver => 'Unblock this driver?';

  @override
  String get allDrivers => 'All Drivers';

  @override
  String get searchByNameVehiclePlate => 'Search by name, vehicle, plate...';

  @override
  String get failedToLoadDrivers => 'Failed to load drivers';

  @override
  String get noDriversFound2 => 'No drivers found';

  @override
  String get earningsDashboard => 'Earnings Dashboard';

  @override
  String get settlementLedger => 'Settlement Ledger';

  @override
  String get failedToLoadEarningsData => 'Failed to load earnings data';

  @override
  String get topDrivers => 'Top Drivers';

  @override
  String get noEarningsDataYet => 'No earnings data yet';

  @override
  String get revenueOverview => 'Revenue Overview';

  @override
  String get grossRevenue => 'Gross Revenue';

  @override
  String get driverPayouts => 'Driver Payouts';

  @override
  String rides2(String count) {
    return '$count rides';
  }

  @override
  String get createSettlement => 'Create Settlement';

  @override
  String get noSettlementsRecorded => 'No settlements recorded';

  @override
  String get settled => 'SETTLED';

  @override
  String get gross => 'Gross';

  @override
  String get fee => 'Fee';

  @override
  String get net => 'Net';

  @override
  String ref(String ref) {
    return 'Ref: $ref';
  }

  @override
  String receipt2(String receipt) {
    return 'Receipt: $receipt';
  }

  @override
  String get driverId => 'Driver ID';

  @override
  String get enterDriverUserId => 'Enter driver user ID';

  @override
  String get grossAmount => 'Gross Amount';

  @override
  String get appFee => 'App Fee';

  @override
  String get netAmount => 'Net Amount';

  @override
  String get settlementReference => 'Settlement Reference';

  @override
  String get egStl001 => 'e.g. STL-001';

  @override
  String get receiptNumberOptional => 'Receipt Number (optional)';

  @override
  String get create => 'Create';

  @override
  String get settlementDashboard => 'Settlement Dashboard';

  @override
  String get payToday => 'Pay Today';

  @override
  String get recommendedSettlement => 'Recommended Settlement';

  @override
  String get waitingForPayment => 'Waiting for Payment';

  @override
  String get underReview => 'Under Review';

  @override
  String get rejected => 'Rejected';

  @override
  String get payable => 'Payable';

  @override
  String get waitingPayment => 'Waiting';

  @override
  String get underReviewShort => 'Review';

  @override
  String get rejectedShort => 'Rejected';

  @override
  String get settlementRange => 'Range';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get custom => 'Custom';

  @override
  String get noSettlementData => 'No settlement data for the selected period';

  @override
  String get noDriversInRange => 'No drivers found in this range';

  @override
  String get driverSettlementDetails => 'Driver Settlement Details';

  @override
  String get settlementStatus => 'Settlement Status';

  @override
  String get verificationStatus => 'Verification Status';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get reasons => 'Reasons';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortDate => 'Date';

  @override
  String get sortScore => 'Score';

  @override
  String get sortNet => 'Net Amount';

  @override
  String get completedTrips => 'Completed Trips';

  @override
  String get reliability => 'Reliability';

  @override
  String get verification => 'Verification';

  @override
  String get settlement => 'Settlement';

  @override
  String get score => 'Score';

  @override
  String get unverifiedRides => 'Unverified';

  @override
  String get suspicious => 'Suspicious';

  @override
  String get failed => 'Failed';

  @override
  String get trips => 'Trips';

  @override
  String trip(String id) {
    return 'Trip #$id';
  }

  @override
  String get enableRetention => 'Enable retention';

  @override
  String get disableRetention => 'Disable retention';

  @override
  String get overview => 'Overview';

  @override
  String get tripNotFound => 'Trip not found';

  @override
  String get errorLoadingTrip => 'Error loading trip';

  @override
  String get failedToLoadEventsTapToRetry =>
      'Failed to load events. Tap to retry.';

  @override
  String get noTimelineEvents => 'No timeline events';

  @override
  String get addAnInvestigationNote => 'Add an investigation note...';

  @override
  String get failedToLoadRetry => 'Failed to load. Retry.';

  @override
  String get noMessages => 'No messages';

  @override
  String get adminNotes => 'Admin Notes';

  @override
  String get timeline => 'Timeline';

  @override
  String get chat => 'Chat';

  @override
  String chatMessages3(String count) {
    return 'Chat Messages ($count)';
  }

  @override
  String get requested => 'Requested';

  @override
  String get reason2 => 'Reason';

  @override
  String get method => 'Method';

  @override
  String get rideInfo => 'Ride Info';

  @override
  String get pickupCoord => 'Pickup Coord';

  @override
  String get dropoffCoord => 'Dropoff Coord';

  @override
  String min2(String duration) {
    return '$duration min';
  }

  @override
  String get estFare => 'Est. Fare';

  @override
  String get finalFare => 'Final Fare';

  @override
  String get retentionEnabledForThisRide => 'Retention enabled for this ride';

  @override
  String get retentionDisabledForThisRide => 'Retention disabled for this ride';

  @override
  String get failedToUpdateRetention => 'Failed to update retention';

  @override
  String get noteAdded => 'Note added';

  @override
  String get failedToAddNote => 'Failed to add note';

  @override
  String get other => 'Other';

  @override
  String get typing => 'typing';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sendAMessageToStartChatting => 'Send a message to start chatting';

  @override
  String get yesterday => 'Yesterday';

  @override
  String isTyping(String name) {
    return '$name is typing...';
  }

  @override
  String get failedToSendMessage => 'Failed to send message';

  @override
  String get onMyWay => 'On my way';

  @override
  String get beThereSoon => 'Be there soon';

  @override
  String get thanks => 'Thanks!';

  @override
  String get sendMessage => 'Send message';

  @override
  String get rideDetails => 'Ride Details';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get pickupCode => 'Pickup Code';

  @override
  String get shareThisCodeWithYourDriverToStartTheRide =>
      'Share this code with your driver to start the ride';

  @override
  String get cancelRide3 => 'Cancel Ride?';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get riderCancelledRide => 'Rider cancelled ride';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get turnOnLocationItWillHelpUsFindYourRider =>
      'Turn on location — it will help us find your rider.';

  @override
  String get turnOnLocationItWillHelpUsFindYourDriver =>
      'Turn on location — it will help us find your driver.';

  @override
  String get allowLocation => 'Allow location';

  @override
  String get allowLocation2 => 'Allow Location';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get setDropoffLocation => 'Set drop-off location';

  @override
  String get findingAddress => 'Finding address...';

  @override
  String get moveTheMapToSelectLocation => 'Move the map to select location';

  @override
  String get moveTheMap => 'Move the map';

  @override
  String get confirmLocation2 => 'Confirm Location';

  @override
  String get noPastRidesYet => 'No past rides yet';

  @override
  String get yourTripHasBeenCompleted => 'Your trip has been completed.';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paymentReceived => 'Payment Received?';

  @override
  String get didYouReceiveThisPayment => 'Did you receive this payment?';

  @override
  String get reasonRequiredIfNo => 'Reason (required if No)';

  @override
  String get pleaseProvideAReason => 'Please provide a reason';

  @override
  String get noIDidnt => 'No, I didn\'t';

  @override
  String get yesReceived => 'Yes, Received';

  @override
  String get scheduleYourLaterRide => 'Schedule your later ride';

  @override
  String scheduleRideAt(String date, String time) {
    return 'Schedule Ride — $date at $time';
  }

  @override
  String get pleaseSelectAFutureDateAndTime =>
      'Please select a future date and time';

  @override
  String get rideScheduledSuccessfully => 'Ride scheduled successfully!';

  @override
  String get failedToScheduleRide => 'Failed to schedule ride';

  @override
  String get anUnexpectedErrorOccurred => 'An unexpected error occurred';

  @override
  String get noLocationsFound => 'No locations found';

  @override
  String get startTypingToSearchLocations => 'Start typing to search locations';

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get pending2 => 'Pending';

  @override
  String get arriving => 'Arriving';

  @override
  String get laterRide => 'Later Ride';

  @override
  String get scheduleARideUsingTheButtonAbove =>
      'Schedule a ride using the button above';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get sun => 'Sun';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get invalidEmailFormat => 'Invalid email format';

  @override
  String get countryCodeIsRequired => 'Country code is required';

  @override
  String get phoneNumberIsRequired => 'Phone number is required';

  @override
  String get emailAlreadyRegistered => 'Email already registered';

  @override
  String get phoneNumberAlreadyRegistered => 'Phone number already registered';

  @override
  String get registrationSuccessful => 'Registration successful!';

  @override
  String get emailAndPasswordAreRequired => 'Email and password are required';

  @override
  String get invalidEmailOrPassword => 'Invalid email or password';

  @override
  String get accountIsBlockedContactAdmin =>
      'Account is blocked. Contact admin.';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get unauthorized => 'Unauthorized';

  @override
  String get deviceTokenUpdated => 'Device token updated';

  @override
  String error2(String error) {
    return 'Error: $error';
  }

  @override
  String get noAccountFoundWithThatEmail => 'No account found with that email';

  @override
  String get tooManyRequestsPleaseTryAgainLater =>
      'Too many requests. Please try again later.';

  @override
  String get failedToSendOtpPleaseTryAgain =>
      'Failed to send OTP. Please try again.';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully';

  @override
  String get emailAndCodeAreRequired => 'Email and code are required';

  @override
  String get invalidOrExpiredOtp => 'Invalid or expired OTP';

  @override
  String get otpHasExpired => 'OTP has expired';

  @override
  String get userNotFound => 'User not found';

  @override
  String get tooManyAttemptsPleaseTryAgainLater =>
      'Too many attempts. Please try again later.';

  @override
  String get ifAnAccountWithThatEmailExistsAnOtpHasBeenSent =>
      'If an account with that email exists, an OTP has been sent.';

  @override
  String get emailCodeAndNewPasswordAreRequired =>
      'Email, code, and new password are required';

  @override
  String get passwordHasBeenResetSuccessfully =>
      'Password has been reset successfully';

  @override
  String get otpIsValid => 'OTP is valid';

  @override
  String get yourLoginCode => 'Your Login Code';

  @override
  String get passwordResetYourOtpCode => 'Password Reset - Your OTP Code';

  @override
  String get hello => 'Hello,';

  @override
  String yourVerificationCodeIs(String otp) {
    return 'Your verification code is: $otp';
  }

  @override
  String get thisCodeWillExpireIn10Minutes =>
      'This code will expire in 10 minutes.';

  @override
  String get ifYouDidntRequestThisCodePleaseIgnoreThisEmail =>
      'If you didn\'t request this code, please ignore this email.';

  @override
  String get bestRegards => 'Best regards,';

  @override
  String get ridenowTeam => 'RideNow Team';

  @override
  String yourPasswordResetCodeIs(String otp) {
    return 'Your password reset code is: $otp';
  }

  @override
  String get ifYouDidntRequestAPasswordResetPleaseIgnoreThisEmail =>
      'If you didn\'t request a password reset, please ignore this email.';

  @override
  String get ridetypeIsRequired => 'rideType is required';

  @override
  String get latitudeAndLongitudeRequired => 'latitude and longitude required';

  @override
  String get noActiveRide => 'No active ride';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get adminAccessRequired => 'Admin access required';

  @override
  String get emailAlreadyInUse => 'Email already in use';

  @override
  String get logoutSuccessful => 'Logout successful';

  @override
  String get alreadyRegisteredAsDriver => 'Already registered as driver';

  @override
  String get driverProfileCreatedSuccessfully =>
      'Driver profile created successfully.';

  @override
  String get driverProfileNotFound => 'Driver profile not found';

  @override
  String get onlineStatusUpdated => 'Online status updated';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String invalidStatusValue(String status) {
    return 'Invalid status value: $status';
  }

  @override
  String retentionEnabledForRide(String id) {
    return 'Retention enabled for ride $id';
  }

  @override
  String retentionDisabledForRide(String id) {
    return 'Retention disabled for ride $id';
  }

  @override
  String noteAddedToRide(String id) {
    return 'Note added to ride $id';
  }

  @override
  String get settlementCreated => 'Settlement created';

  @override
  String get paymentConfirmed2 => 'Payment confirmed';

  @override
  String get paymentReceived2 => 'Payment received';

  @override
  String get cashPaymentConfirmed => 'Cash payment confirmed';

  @override
  String get markedAsUnpaid => 'Marked as unpaid';

  @override
  String get paymentDisputedAmountRefundedToRider =>
      'Payment disputed, amount refunded to rider';

  @override
  String get ratingMustBeBetween1And5 => 'Rating must be between 1 and 5';

  @override
  String get youHaveAlreadyRatedThisRide => 'You have already rated this ride';

  @override
  String get invalidRideOrUser => 'Invalid ride or user';

  @override
  String get youWereNotPartOfThisRide => 'You were not part of this ride';

  @override
  String get noDriverToRateOnThisRide => 'No driver to rate on this ride';

  @override
  String get rateeNotFound => 'Ratee not found';

  @override
  String get ratingSubmittedSuccessfully => 'Rating submitted successfully';

  @override
  String get fileIsEmpty => 'File is empty';

  @override
  String get missingAuthorizationHeader => 'Missing authorization header';

  @override
  String get invalidToken => 'Invalid token';

  @override
  String get notificationMarkedAsRead => 'Notification marked as read';

  @override
  String get allNotificationsMarkedAsRead => 'All notifications marked as read';

  @override
  String get allNotificationsDeleted => 'All notifications deleted';

  @override
  String get messageContentCannotBeEmpty => 'Message content cannot be empty';

  @override
  String get messageIsTooLongMax10000Characters =>
      'Message is too long (max 10000 characters)';

  @override
  String get senderOrReceiverNotFound => 'Sender or receiver not found';

  @override
  String get messageSent => 'Message sent';

  @override
  String newMessageFrom(String username) {
    return 'New message from $username';
  }

  @override
  String get codeIsRequired => 'Code is required';

  @override
  String get eventtypeIsRequired => 'eventType is required';

  @override
  String get youAlreadyHaveAnActiveRide => 'You already have an active ride';

  @override
  String get rideNotFound => 'Ride not found';

  @override
  String get rideIsNoLongerAvailable => 'Ride is no longer available';

  @override
  String get rideAlreadyAccepted => 'Ride already accepted';

  @override
  String get driverNotFound => 'Driver not found';

  @override
  String get onlyDriversCanAcceptRides => 'Only drivers can accept rides';

  @override
  String cannotTransitionFromTo(String current, String next) {
    return 'Cannot transition from $current to $next';
  }

  @override
  String get rideNotInRequestedStatus => 'Ride not in REQUESTED status';

  @override
  String get onlyTheDriverCanUpdateRideLocation =>
      'Only the driver can update ride location';

  @override
  String get rideIsNotActive => 'Ride is not active';

  @override
  String get youHaveAcceptedARideNavigateToPickupLocation =>
      'You have accepted a ride. Navigate to pickup location.';

  @override
  String get noDriversAvailableYetContinueSearching =>
      'No drivers available yet. Continue searching?';

  @override
  String get noWomenDriversFoundSwitchToAnotherRideType =>
      'No women drivers found. Switch to another ride type?';

  @override
  String get yourScheduledRideIsIn30Minutes =>
      'Your scheduled ride is in 30 minutes';

  @override
  String get scheduledRideHasExpired => 'Scheduled ride has expired';

  @override
  String get driverHasCancelledTheScheduledRide =>
      'Driver has cancelled the scheduled ride';

  @override
  String get xxx1234 => 'XXX-1234';

  @override
  String get rideAcceptedADriverIsOnTheWayToPickYouUp =>
      'Ride Accepted - A driver is on the way to pick you up';

  @override
  String get rideConfirmedYouHaveAcceptedARideNavigateToPickup =>
      'Ride Confirmed - You have accepted a ride. Navigate to pickup.';

  @override
  String get driverArrivedYourDriverHasArrivedAtThePickupLocation =>
      'Driver Arrived - Your driver has arrived at the pickup location';

  @override
  String get rideStartedYourRideHasStartedEnjoyTheTrip =>
      'Ride Started - Your ride has started. Enjoy the trip!';

  @override
  String get rideCompletedYouHaveReachedYourDestination =>
      'Ride Completed - You have reached your destination';

  @override
  String rideCancelled3(String reason) {
    return 'Ride Cancelled - $reason';
  }

  @override
  String get noWomenDriversFoundNoWomenDriversAvailableSwitchRideType =>
      'No Women Drivers Found - No women drivers available. Switch ride type?';

  @override
  String get noDriversFoundNoDriversAvailableYetContinueSearching =>
      'No Drivers Found - No drivers available yet. Continue searching?';

  @override
  String get paymentConfirmedPaymentHasBeenConfirmed =>
      'Payment Confirmed - Payment has been confirmed';

  @override
  String get paymentFinalizedYourPaymentHasBeenFinalized =>
      'Payment Finalized - Your payment has been finalized';

  @override
  String get paymentRefundedYourPaymentHasBeenRefunded =>
      'Payment Refunded - Your payment has been refunded';

  @override
  String get driverAssignedADriverHasAcceptedYourScheduledRide =>
      'Driver Assigned - A driver has accepted your scheduled ride';

  @override
  String get driverArrivedYourDriverHasArrivedForYourScheduledRide =>
      'Driver Arrived - Your driver has arrived for your scheduled ride';

  @override
  String get rideStartedYourScheduledRideHasStarted =>
      'Ride Started - Your scheduled ride has started';

  @override
  String get rideReminderYourScheduledRideIsIn30Minutes =>
      'Ride Reminder - Your scheduled ride is in 30 minutes';

  @override
  String scheduledRideCancelled(String reason) {
    return 'Scheduled Ride Cancelled - $reason';
  }

  @override
  String paymentNotFoundForRide(String rideId) {
    return 'Payment not found for ride: $rideId';
  }

  @override
  String get onlyTheRiderCanConfirmPayment =>
      'Only the rider can confirm payment';

  @override
  String paymentCannotBeConfirmedInStatus(String status) {
    return 'Payment cannot be confirmed in status: $status';
  }

  @override
  String get insufficientWalletBalance => 'Insufficient wallet balance';

  @override
  String tripFareForRide(String rideId) {
    return 'Trip fare for ride #$rideId';
  }

  @override
  String get onlyTheDriverCanConfirmCashReceipt =>
      'Only the driver can confirm cash receipt';

  @override
  String get thisEndpointIsOnlyForCashPayments =>
      'This endpoint is only for CASH payments';

  @override
  String get onlyTheDriverCanReportCashUnpaid =>
      'Only the driver can report cash unpaid';

  @override
  String get customerDidNotPayCash => 'Customer did not pay cash';

  @override
  String get onlyTheDriverCanConfirmReceipt =>
      'Only the driver can confirm receipt';

  @override
  String get onlyTheDriverCanDisputePayment =>
      'Only the driver can dispute payment';

  @override
  String refundForRide(String rideId, String reason) {
    return 'Refund for ride #$rideId - $reason';
  }

  @override
  String get onlyTheRiderOrDriverCanViewPaymentStatus =>
      'Only the rider or driver can view payment status';

  @override
  String get scheduledTimeMustBeInTheFuture =>
      'Scheduled time must be in the future';

  @override
  String get scheduledRideNotFound => 'Scheduled ride not found';

  @override
  String get canOnlyCancelScheduledOrAssignedScheduledRides =>
      'Can only cancel scheduled or assigned scheduled rides';

  @override
  String get cancelledByUser => 'Cancelled by user';

  @override
  String get cancelledByRider => 'Cancelled by rider';

  @override
  String get canOnlyCompleteStartedScheduledRides =>
      'Can only complete started scheduled rides';

  @override
  String get latitudeAndLongitudeAreRequired =>
      'Latitude and longitude are required';

  @override
  String get thisRideIsNoLongerAvailable => 'This ride is no longer available';

  @override
  String get thisRideIsNotAssignedToYou => 'This ride is not assigned to you';

  @override
  String get canOnlyUnassignARideThatIsInAssignedStatus =>
      'Can only unassign a ride that is in ASSIGNED status';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get rideMustBeAssignedBeforeArriving =>
      'Ride must be assigned before arriving';

  @override
  String get onlyTheAssignedDriverCanVerifyThePickupCode =>
      'Only the assigned driver can verify the pickup code';

  @override
  String get pickupCodeCanOnlyBeVerifiedAfterTheDriverHasArrived =>
      'Pickup code can only be verified after the driver has arrived';

  @override
  String get driverMustArriveBeforeStartingTheRide =>
      'Driver must arrive before starting the ride';

  @override
  String get pickupCodeMustBeVerifiedBeforeStartingTheRide =>
      'Pickup code must be verified before starting the ride';

  @override
  String get pickupCodeVerificationHasExpiredPleaseVerifyAgain =>
      'Pickup code verification has expired. Please verify again.';

  @override
  String get paymentStartedButNeverCompleted =>
      'Payment started but never completed';

  @override
  String get rideCompletedButPaymentStillPending =>
      'Ride completed but payment still pending';

  @override
  String eventOccurredTimes(String name, String count) {
    return 'Event \'$name\' occurred $count times';
  }

  @override
  String retryLoopDetectedRetries(String count) {
    return 'Retry loop detected: $count retries';
  }

  @override
  String get apiTimeoutOccurred => 'API timeout occurred';

  @override
  String serverException(String message) {
    return 'Server exception: $message';
  }

  @override
  String websocketDisconnectedTimes(String count) {
    return 'WebSocket disconnected $count times';
  }

  @override
  String get driverAcceptedButPassengerMayNotHaveReceivedUpdate =>
      'Driver accepted but passenger may not have received update';

  @override
  String tripRemainedInForS(String state, String seconds) {
    return 'Trip remained in \'$state\' for ${seconds}s';
  }

  @override
  String gpsUpdatingForS(String seconds) {
    return 'GPS updating for ${seconds}s';
  }

  @override
  String get coordinatesCannotBeNull => 'Coordinates cannot be null';

  @override
  String geocodingFailed(String status) {
    return 'Geocoding failed: $status';
  }

  @override
  String get usingEstimatedRouteActualRouteMayDiffer =>
      'Using estimated route - actual route may differ';

  @override
  String get noDriversAvailableAutoCancelled =>
      'No drivers available - auto cancelled';

  @override
  String get autocancelledDriverNeverMovedToPickupFor2Hours =>
      'Auto-cancelled - driver never moved to pickup for 2+ hours';

  @override
  String get autocancelledDriverNeverStartedRideFor2Hours =>
      'Auto-cancelled - driver never started ride for 2+ hours';

  @override
  String get noDriversAvailable => 'No drivers available';

  @override
  String get urlCannotBeEmpty => 'URL cannot be empty';

  @override
  String get serverUrlUpdated => 'Server URL updated';

  @override
  String get rideUpdatesAndOffers => 'Receive ride updates and offers';

  @override
  String get receiveTextMessagesForRides => 'Receive text messages for rides';

  @override
  String get receivePromotionalEmails => 'Receive promotional emails';

  @override
  String get displayCurrency => 'Display Currency';

  @override
  String get saveServerUrl => 'Save Server URL';

  @override
  String get currency => 'Currency';

  @override
  String get premiumRideSharing => 'Premium ride sharing';

  @override
  String get grantLocationAccess => 'Grant Location Access';

  @override
  String get date => 'Date';

  @override
  String get adminNote => 'Admin note';

  @override
  String get approved => 'Approved';

  @override
  String get approvedBy => 'Approved by';

  @override
  String get approveDocument => 'Approve';

  @override
  String get documents => 'Documents';

  @override
  String get documentReviewTitle => 'Document Review';

  @override
  String get expiresOn => 'Expires';

  @override
  String get issueDate => 'Issue date';

  @override
  String get documentNumber => 'Document number';

  @override
  String get reviewedBy => 'Reviewed by';

  @override
  String get noDocuments => 'No documents uploaded';

  @override
  String get noteHint => 'Note (optional)';

  @override
  String get rejectDocument => 'Reject';

  @override
  String get requestReupload => 'Request re-upload';

  @override
  String get reviewedAt => 'Reviewed';

  @override
  String get tapToViewDocument => 'Tap to view';

  @override
  String get uploadedOn => 'Uploaded';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get totalDrivers => 'Total Drivers';

  @override
  String get pendingDocuments => 'Pending Documents';

  @override
  String get noPendingDocuments => 'No pending documents';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusPending => 'Pending';

  @override
  String get documentExpiry => 'Document Expiry';

  @override
  String get expiredDocuments => 'Expired';

  @override
  String get expiringWithin7Days => 'Expiring within 7 days';

  @override
  String get expiringWithin30Days => 'Expiring within 30 days';

  @override
  String get noExpiringDocuments => 'No documents in this window';
}
