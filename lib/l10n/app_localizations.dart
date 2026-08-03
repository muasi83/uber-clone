import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar')
  ];

  /// No description provided for @$$locale.
  ///
  /// In en, this message translates to:
  /// **'en'**
  String get $$locale;

  /// No description provided for @ridenow.
  ///
  /// In en, this message translates to:
  /// **'RideNow'**
  String get ridenow;

  /// No description provided for @navigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation Error'**
  String get navigationError;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @rideAccepted.
  ///
  /// In en, this message translates to:
  /// **'Ride Accepted'**
  String get rideAccepted;

  /// No description provided for @aDriverIsOnTheirWayToPickYouUp.
  ///
  /// In en, this message translates to:
  /// **'A driver is on their way to pick you up'**
  String get aDriverIsOnTheirWayToPickYouUp;

  /// No description provided for @rideConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Ride Confirmed'**
  String get rideConfirmed;

  /// No description provided for @yourRideHasBeenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Your ride has been confirmed'**
  String get yourRideHasBeenConfirmed;

  /// No description provided for @driverArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver Arrived'**
  String get driverArrived;

  /// No description provided for @yourDriverHasArrivedAtThePickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Your driver has arrived at the pickup location'**
  String get yourDriverHasArrivedAtThePickupLocation;

  /// No description provided for @rideStarted.
  ///
  /// In en, this message translates to:
  /// **'Ride Started'**
  String get rideStarted;

  /// No description provided for @yourRideHasStarted.
  ///
  /// In en, this message translates to:
  /// **'Your ride has started'**
  String get yourRideHasStarted;

  /// No description provided for @rideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Ride Completed'**
  String get rideCompleted;

  /// No description provided for @youHaveReachedYourDestination.
  ///
  /// In en, this message translates to:
  /// **'You have reached your destination'**
  String get youHaveReachedYourDestination;

  /// No description provided for @rideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled'**
  String get rideCancelled;

  /// No description provided for @theRideHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'The ride has been cancelled'**
  String get theRideHasBeenCancelled;

  /// No description provided for @noDriversFound.
  ///
  /// In en, this message translates to:
  /// **'No Drivers Found'**
  String get noDriversFound;

  /// No description provided for @noDriversAreAvailableNearbyRightNow.
  ///
  /// In en, this message translates to:
  /// **'No drivers are available nearby right now'**
  String get noDriversAreAvailableNearbyRightNow;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentHasBeenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment has been confirmed'**
  String get paymentHasBeenConfirmed;

  /// No description provided for @paymentFinalized.
  ///
  /// In en, this message translates to:
  /// **'Payment Finalized'**
  String get paymentFinalized;

  /// No description provided for @yourPaymentHasBeenFinalized.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been finalized'**
  String get yourPaymentHasBeenFinalized;

  /// No description provided for @paymentRefunded.
  ///
  /// In en, this message translates to:
  /// **'Payment Refunded'**
  String get paymentRefunded;

  /// No description provided for @yourPaymentHasBeenRefunded.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been refunded'**
  String get yourPaymentHasBeenRefunded;

  /// No description provided for @someone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// No description provided for @missingArgumentsFor.
  ///
  /// In en, this message translates to:
  /// **'Missing arguments for {route}'**
  String missingArgumentsFor(String route);

  /// No description provided for @invalidArguments.
  ///
  /// In en, this message translates to:
  /// **'Invalid {route} arguments'**
  String invalidArguments(String route);

  /// No description provided for @missingDriverRegistrationData.
  ///
  /// In en, this message translates to:
  /// **'Missing driver registration data'**
  String get missingDriverRegistrationData;

  /// No description provided for @missingDriverSessionData.
  ///
  /// In en, this message translates to:
  /// **'Missing driver session data'**
  String get missingDriverSessionData;

  /// No description provided for @rideAlerts.
  ///
  /// In en, this message translates to:
  /// **'Ride Alerts'**
  String get rideAlerts;

  /// No description provided for @highpriorityRideRequestNotifications.
  ///
  /// In en, this message translates to:
  /// **'High-priority ride request notifications'**
  String get highpriorityRideRequestNotifications;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Chat Messages'**
  String get chatMessages;

  /// No description provided for @newChatMessagesDuringYourRide.
  ///
  /// In en, this message translates to:
  /// **'New chat messages during your ride'**
  String get newChatMessagesDuringYourRide;

  /// No description provided for @dollar.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get dollar;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @syp.
  ///
  /// In en, this message translates to:
  /// **'SYP'**
  String get syp;

  /// No description provided for @newRideRequest.
  ///
  /// In en, this message translates to:
  /// **'New Ride Request'**
  String get newRideRequest;

  /// No description provided for @aPassengerNeedsARide.
  ///
  /// In en, this message translates to:
  /// **'A passenger needs a ride!'**
  String get aPassengerNeedsARide;

  /// No description provided for @pleaseEnterAValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterAValidEmailAddress;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @getStartedCreateYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Get started — Create your account'**
  String get getStartedCreateYourAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @rider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get rider;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @anErrorOccurredPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get anErrorOccurredPleaseTryAgain;

  /// No description provided for @pleaseEnterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterAPassword;

  /// No description provided for @anErrorOccurredDuringRegistrationPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during registration. Please try again.'**
  String get anErrorOccurredDuringRegistrationPleaseTryAgain;

  /// No description provided for @loginFailedPleaseCheckYourCredentialsAndTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials and try again.'**
  String get loginFailedPleaseCheckYourCredentialsAndTryAgain;

  /// No description provided for @registrationSuccessfulPleaseCheckYourEmailForVerification.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email for verification.'**
  String get registrationSuccessfulPleaseCheckYourEmailForVerification;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Password cannot be empty'**
  String get passwordCannotBeEmpty;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @useOtpInstead.
  ///
  /// In en, this message translates to:
  /// **'Use OTP Instead'**
  String get useOtpInstead;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @forgotPassword2.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword2;

  /// No description provided for @enterYourEmailAddressAndWellSendYouAResetLink.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a reset link'**
  String get enterYourEmailAddressAndWellSendYouAResetLink;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @resetLinkSentCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your email'**
  String get resetLinkSentCheckYourEmail;

  /// No description provided for @emailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Email not found'**
  String get emailNotFound;

  /// No description provided for @errorSendingResetLinkPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Error sending reset link. Please try again.'**
  String get errorSendingResetLinkPleaseTryAgain;

  /// No description provided for @pleaseEnterAValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterAValidEmail;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @enterYourNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get enterYourNewPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @resetting.
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get resetting;

  /// No description provided for @passwordResetSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get passwordResetSuccessful;

  /// No description provided for @errorResettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Error resetting password'**
  String get errorResettingPassword;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @aVerificationEmailHasBeenSentTo.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to {email}'**
  String aVerificationEmailHasBeenSentTo(String email);

  /// No description provided for @pleaseCheckYourInboxAndClickTheVerificationLink.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and click the verification link'**
  String get pleaseCheckYourInboxAndClickTheVerificationLink;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @emailResent.
  ///
  /// In en, this message translates to:
  /// **'Email resent'**
  String get emailResent;

  /// No description provided for @verifiedRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Verified! Redirecting...'**
  String get verifiedRedirecting;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @iveVerifiedMyEmail.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get iveVerifiedMyEmail;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @didntReceiveTheEmailCheckYourSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email? Check your spam folder'**
  String get didntReceiveTheEmailCheckYourSpamFolder;

  /// No description provided for @changeEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get changeEmailAddress;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// No description provided for @enterYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterYourPhoneNumber;

  /// No description provided for @wellSendYouAVerificationCodeViaSms.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code via SMS'**
  String get wellSendYouAVerificationCodeViaSms;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @phoneVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Phone verified successfully'**
  String get phoneVerifiedSuccessfully;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @errorSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Error sending code'**
  String get errorSendingCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @enterTheCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phone_or_email}'**
  String enterTheCodeSentTo(String phone_or_email);

  /// No description provided for @didntReceiveTheCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didntReceiveTheCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @invalidCodePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCodePleaseTryAgain;

  /// No description provided for @codeVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Code verified successfully'**
  String get codeVerifiedSuccessfully;

  /// No description provided for @codeExpiredRequestANewOne.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Request a new one'**
  String get codeExpiredRequestANewOne;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}'**
  String resendCodeIn(String seconds);

  /// No description provided for @setADestinationToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Set a destination to get started'**
  String get setADestinationToGetStarted;

  /// No description provided for @whereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// No description provided for @enterDestination.
  ///
  /// In en, this message translates to:
  /// **'Enter destination...'**
  String get enterDestination;

  /// No description provided for @searchResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Search results for:'**
  String get searchResultsFor;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @requestANewRide.
  ///
  /// In en, this message translates to:
  /// **'Request a new ride'**
  String get requestANewRide;

  /// No description provided for @ride.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get ride;

  /// No description provided for @scheduleARideForLater.
  ///
  /// In en, this message translates to:
  /// **'Schedule a ride for later'**
  String get scheduleARideForLater;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @connectionLostRetrying.
  ///
  /// In en, this message translates to:
  /// **'Connection lost — retrying...'**
  String get connectionLostRetrying;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @dropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Dropoff location'**
  String get dropoffLocation;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String min(String min);

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String km(String distance);

  /// No description provided for @findingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get findingYourLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDeniedEnableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied — enable in Settings'**
  String get locationPermissionPermanentlyDeniedEnableInSettings;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable location services'**
  String get enableLocationServices;

  /// No description provided for @locationServicesAreDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesAreDisabled;

  /// No description provided for @noInternetConnectionShowingOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'No internet connection — showing offline map'**
  String get noInternetConnectionShowingOfflineMap;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @setPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Set pickup location'**
  String get setPickupLocation;

  /// No description provided for @searchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search address...'**
  String get searchAddress;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @confirmPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup location'**
  String get confirmPickupLocation;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results:'**
  String get searchResults;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @dragTheMapToSetPickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to set pickup point'**
  String get dragTheMapToSetPickupPoint;

  /// No description provided for @locationAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access denied'**
  String get locationAccessDenied;

  /// No description provided for @gettingCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting current location...'**
  String get gettingCurrentLocation;

  /// No description provided for @pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup point'**
  String get pickupPoint;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search destination...'**
  String get searchDestination;

  /// No description provided for @setDestination.
  ///
  /// In en, this message translates to:
  /// **'Set destination'**
  String get setDestination;

  /// No description provided for @confirmDestination.
  ///
  /// In en, this message translates to:
  /// **'Confirm destination'**
  String get confirmDestination;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo applied'**
  String get promoApplied;

  /// No description provided for @baseFare.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get baseFare;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance ({distance} km)'**
  String distanceKm(String distance);

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @confirmRide.
  ///
  /// In en, this message translates to:
  /// **'Confirm Ride'**
  String get confirmRide;

  /// No description provided for @requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting...'**
  String get requesting;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromoCode;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @invalidPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code'**
  String get invalidPromoCode;

  /// No description provided for @noRideTypesAvailableInYourArea.
  ///
  /// In en, this message translates to:
  /// **'No ride types available in your area'**
  String get noRideTypesAvailableInYourArea;

  /// No description provided for @routeNotAvailableNoRoadsNearPickup.
  ///
  /// In en, this message translates to:
  /// **'Route not available — no roads near pickup'**
  String get routeNotAvailableNoRoadsNearPickup;

  /// No description provided for @noPriceAvailable.
  ///
  /// In en, this message translates to:
  /// **'No price available'**
  String get noPriceAvailable;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetails;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @fare.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fare;

  /// No description provided for @requestRide.
  ///
  /// In en, this message translates to:
  /// **'Request Ride'**
  String get requestRide;

  /// No description provided for @rideType.
  ///
  /// In en, this message translates to:
  /// **'Ride type: {type}'**
  String rideType(String type);

  /// No description provided for @estimatedArrival.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get estimatedArrival;

  /// No description provided for @priceBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Price breakdown'**
  String get priceBreakdown;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @totalFare.
  ///
  /// In en, this message translates to:
  /// **'Total fare'**
  String get totalFare;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @selectRideType.
  ///
  /// In en, this message translates to:
  /// **'Select ride type'**
  String get selectRideType;

  /// No description provided for @chooseRide.
  ///
  /// In en, this message translates to:
  /// **'Choose Ride'**
  String get chooseRide;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authenticationError;

  /// No description provided for @failedToRequestRide.
  ///
  /// In en, this message translates to:
  /// **'Failed to request ride'**
  String get failedToRequestRide;

  /// No description provided for @searchingForADriver.
  ///
  /// In en, this message translates to:
  /// **'Searching for a driver...'**
  String get searchingForADriver;

  /// No description provided for @searchingForNearbyDrivers.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby drivers...'**
  String get searchingForNearbyDrivers;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @findingYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding your driver...'**
  String get findingYourDriver;

  /// No description provided for @estimatedWaitTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated wait time: {time}'**
  String estimatedWaitTime(String time);

  /// No description provided for @driverFound.
  ///
  /// In en, this message translates to:
  /// **'Driver found!'**
  String get driverFound;

  /// No description provided for @yourDriverIsOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Your driver is on the way'**
  String get yourDriverIsOnTheWay;

  /// No description provided for @arrivingIn.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {time}'**
  String arrivingIn(String time);

  /// No description provided for @driverArrived2.
  ///
  /// In en, this message translates to:
  /// **'Driver arrived'**
  String get driverArrived2;

  /// No description provided for @tripStartedHeadingToDestination.
  ///
  /// In en, this message translates to:
  /// **'Trip started — heading to destination'**
  String get tripStartedHeadingToDestination;

  /// No description provided for @arrivingInMin.
  ///
  /// In en, this message translates to:
  /// **'Arriving in {min} min'**
  String arrivingInMin(String min);

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call driver'**
  String get callDriver;

  /// No description provided for @messageDriver.
  ///
  /// In en, this message translates to:
  /// **'Message driver'**
  String get messageDriver;

  /// No description provided for @shareTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Share trip status'**
  String get shareTripStatus;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel ride'**
  String get cancelRide;

  /// No description provided for @cancelTrip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @areYouSureYouWantToCancelThisRide.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride?'**
  String get areYouSureYouWantToCancelThisRide;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @enterYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your message'**
  String get enterYourMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWith(String name);

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @pickupInMin.
  ///
  /// In en, this message translates to:
  /// **'Pickup in {min} min'**
  String pickupInMin(String min);

  /// No description provided for @arrivingAtDestination.
  ///
  /// In en, this message translates to:
  /// **'Arriving at destination'**
  String get arrivingAtDestination;

  /// No description provided for @paymentMethod2.
  ///
  /// In en, this message translates to:
  /// **'Payment method: {method}'**
  String paymentMethod2(String method);

  /// No description provided for @totalFare2.
  ///
  /// In en, this message translates to:
  /// **'Total fare: {amount}'**
  String totalFare2(String amount);

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @rideCancelled2.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled'**
  String get rideCancelled2;

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancel reason'**
  String get cancelReason;

  /// No description provided for @trackingYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Tracking your driver'**
  String get trackingYourDriver;

  /// No description provided for @driverIsMetersAway.
  ///
  /// In en, this message translates to:
  /// **'Driver is {distance} meters away'**
  String driverIsMetersAway(String distance);

  /// No description provided for @driverIsKmAway.
  ///
  /// In en, this message translates to:
  /// **'Driver is {distance} km away'**
  String driverIsKmAway(String distance);

  /// No description provided for @driverArrivingInMin.
  ///
  /// In en, this message translates to:
  /// **'Driver arriving in {min} min'**
  String driverArrivingInMin(String min);

  /// No description provided for @pickupLocationReached.
  ///
  /// In en, this message translates to:
  /// **'Pickup location reached'**
  String get pickupLocationReached;

  /// No description provided for @driverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has arrived'**
  String get driverHasArrived;

  /// No description provided for @tripInProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip in progress'**
  String get tripInProgress;

  /// No description provided for @driverIsHeadingToDestination.
  ///
  /// In en, this message translates to:
  /// **'Driver is heading to destination'**
  String get driverIsHeadingToDestination;

  /// No description provided for @estimatedArrivalInMin.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival in {min} min'**
  String estimatedArrivalInMin(String min);

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareYourTrip.
  ///
  /// In en, this message translates to:
  /// **'Share your trip'**
  String get shareYourTrip;

  /// No description provided for @imOnARideWithTrackMyTrip.
  ///
  /// In en, this message translates to:
  /// **'I\'m on a ride with {name}. Track my trip: {link}'**
  String imOnARideWithTrackMyTrip(String name, String link);

  /// No description provided for @tripCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get tripCompleted;

  /// No description provided for @youHaveArrived.
  ///
  /// In en, this message translates to:
  /// **'You have arrived'**
  String get youHaveArrived;

  /// No description provided for @payment2.
  ///
  /// In en, this message translates to:
  /// **'Payment: {method}'**
  String payment2(String method);

  /// No description provided for @rideCompleted2.
  ///
  /// In en, this message translates to:
  /// **'Ride completed!'**
  String get rideCompleted2;

  /// No description provided for @thanksForRidingWithUs.
  ///
  /// In en, this message translates to:
  /// **'Thanks for riding with us'**
  String get thanksForRidingWithUs;

  /// No description provided for @rateYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Rate your driver'**
  String get rateYourDriver;

  /// No description provided for @howWasYourTrip.
  ///
  /// In en, this message translates to:
  /// **'How was your trip?'**
  String get howWasYourTrip;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addAComment;

  /// No description provided for @leaveAReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review...'**
  String get leaveAReview;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yourDriverWas.
  ///
  /// In en, this message translates to:
  /// **'Your driver was'**
  String get yourDriverWas;

  /// No description provided for @tripFare.
  ///
  /// In en, this message translates to:
  /// **'Trip fare: {amount}'**
  String tripFare(String amount);

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;

  /// No description provided for @reportAnIssue.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get reportAnIssue;

  /// No description provided for @rideAgain.
  ///
  /// In en, this message translates to:
  /// **'Ride again'**
  String get rideAgain;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermissionRequired;

  /// No description provided for @weNeedYourLocationToFindNearbyDriversAndProvideAccuratePickup.
  ///
  /// In en, this message translates to:
  /// **'We need your location to find nearby drivers and provide accurate pickup'**
  String get weNeedYourLocationToFindNearbyDriversAndProvideAccuratePickup;

  /// No description provided for @allowLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow Location Access'**
  String get allowLocationAccess;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @locationPermissionIsRequiredToUseThisApp.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to use this app'**
  String get locationPermissionIsRequiredToUseThisApp;

  /// No description provided for @enableLocationServicesToRequestRides.
  ///
  /// In en, this message translates to:
  /// **'Enable location services to request rides'**
  String get enableLocationServicesToRequestRides;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get rideHistory;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @areYouSureYouWantToLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureYouWantToLogOut;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @switchToDriver.
  ///
  /// In en, this message translates to:
  /// **'Switch to Driver'**
  String get switchToDriver;

  /// No description provided for @switchToRider.
  ///
  /// In en, this message translates to:
  /// **'Switch to Rider'**
  String get switchToRider;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethod;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @debitCard.
  ///
  /// In en, this message translates to:
  /// **'Debit Card'**
  String get debitCard;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// No description provided for @saveCard.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCard;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @defaultText.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultText;

  /// No description provided for @noPaymentMethodsAdded.
  ///
  /// In en, this message translates to:
  /// **'No payment methods added'**
  String get noPaymentMethodsAdded;

  /// No description provided for @addAPaymentMethodToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add a payment method to get started'**
  String get addAPaymentMethodToGetStarted;

  /// No description provided for @cardExpired.
  ///
  /// In en, this message translates to:
  /// **'Card expired'**
  String get cardExpired;

  /// No description provided for @invalidCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid card number'**
  String get invalidCardNumber;

  /// No description provided for @enterYourCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your card details'**
  String get enterYourCardDetails;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get adding;

  /// No description provided for @cardAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Card added successfully'**
  String get cardAddedSuccessfully;

  /// No description provided for @failedToAddCard.
  ///
  /// In en, this message translates to:
  /// **'Failed to add card'**
  String get failedToAddCard;

  /// No description provided for @areYouSureYouWantToRemoveThisCard.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this card?'**
  String get areYouSureYouWantToRemoveThisCard;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String appVersion(String version);

  /// No description provided for @rateTheApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateTheApp;

  /// No description provided for @shareTheApp.
  ///
  /// In en, this message translates to:
  /// **'Share the App'**
  String get shareTheApp;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @areYouSureYouWantToDeleteYourAccountThisCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This cannot be undone'**
  String get areYouSureYouWantToDeleteYourAccountThisCannotBeUndone;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @smsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications'**
  String get smsNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get emailNotifications;

  /// No description provided for @rideUpdates.
  ///
  /// In en, this message translates to:
  /// **'Ride updates'**
  String get rideUpdates;

  /// No description provided for @promotionsAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Promotions and offers'**
  String get promotionsAndOffers;

  /// No description provided for @chatMessages2.
  ///
  /// In en, this message translates to:
  /// **'Chat messages'**
  String get chatMessages2;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportAProblem;

  /// No description provided for @howCanWeHelpYou.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get howCanWeHelpYou;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue...'**
  String get describeYourIssue;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @messageSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully'**
  String get messageSentSuccessfully;

  /// No description provided for @failedToSendMessagePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message. Please try again.'**
  String get failedToSendMessagePleaseTryAgain;

  /// No description provided for @emailUsAt.
  ///
  /// In en, this message translates to:
  /// **'Email us at {email}'**
  String emailUsAt(String email);

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get callUs;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @supportHours.
  ///
  /// In en, this message translates to:
  /// **'Support hours: {hours}'**
  String supportHours(String hours);

  /// No description provided for @wellGetBackToYouWithin24Hours.
  ///
  /// In en, this message translates to:
  /// **'We\'ll get back to you within 24 hours'**
  String get wellGetBackToYouWithin24Hours;

  /// No description provided for @safetyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Safety Features'**
  String get safetyFeatures;

  /// No description provided for @shareMyTrip.
  ///
  /// In en, this message translates to:
  /// **'Share My Trip'**
  String get shareMyTrip;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @reportAnIncident.
  ///
  /// In en, this message translates to:
  /// **'Report an Incident'**
  String get reportAnIncident;

  /// No description provided for @n247Support.
  ///
  /// In en, this message translates to:
  /// **'24/7 Support'**
  String get n247Support;

  /// No description provided for @locationSharing.
  ///
  /// In en, this message translates to:
  /// **'Location Sharing'**
  String get locationSharing;

  /// No description provided for @trustedContacts.
  ///
  /// In en, this message translates to:
  /// **'Trusted Contacts'**
  String get trustedContacts;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add emergency contact'**
  String get addEmergencyContact;

  /// No description provided for @callEmergencyServices.
  ///
  /// In en, this message translates to:
  /// **'Call emergency services'**
  String get callEmergencyServices;

  /// No description provided for @yourSafetyIsOurPriority.
  ///
  /// In en, this message translates to:
  /// **'Your safety is our priority'**
  String get yourSafetyIsOurPriority;

  /// No description provided for @rideCheck.
  ///
  /// In en, this message translates to:
  /// **'Ride Check'**
  String get rideCheck;

  /// No description provided for @shareYourRideStatusWithTrustedContacts.
  ///
  /// In en, this message translates to:
  /// **'Share your ride status with trusted contacts'**
  String get shareYourRideStatusWithTrustedContacts;

  /// No description provided for @audioRecordingDuringTrip.
  ///
  /// In en, this message translates to:
  /// **'Audio recording during trip'**
  String get audioRecordingDuringTrip;

  /// No description provided for @speedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Speed alerts'**
  String get speedAlerts;

  /// No description provided for @driverIdentityVerification.
  ///
  /// In en, this message translates to:
  /// **'Driver identity verification'**
  String get driverIdentityVerification;

  /// No description provided for @inappEmergencyButton.
  ///
  /// In en, this message translates to:
  /// **'In-app emergency button'**
  String get inappEmergencyButton;

  /// No description provided for @manageEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Manage emergency contacts'**
  String get manageEmergencyContacts;

  /// No description provided for @noEmergencyContactsAdded.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts added'**
  String get noEmergencyContactsAdded;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get addContact;

  /// No description provided for @removeContact.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get removeContact;

  /// No description provided for @areYouSureYouWantToRemoveThisEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this emergency contact?'**
  String get areYouSureYouWantToRemoveThisEmergencyContact;

  /// No description provided for @enterYourDestination.
  ///
  /// In en, this message translates to:
  /// **'Enter your destination'**
  String get enterYourDestination;

  /// No description provided for @chooseOnMap.
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// No description provided for @setPickupOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set pickup on map'**
  String get setPickupOnMap;

  /// No description provided for @setDropoffOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set dropoff on map'**
  String get setDropoffOnMap;

  /// No description provided for @pleaseSelectAPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a pickup location'**
  String get pleaseSelectAPickupLocation;

  /// No description provided for @pleaseSelectADropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a dropoff location'**
  String get pleaseSelectADropoffLocation;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @recentPlaces.
  ///
  /// In en, this message translates to:
  /// **'Recent places'**
  String get recentPlaces;

  /// No description provided for @savedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlaces;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @addAPlace.
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get addAPlace;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @gettingAddress.
  ///
  /// In en, this message translates to:
  /// **'Getting address...'**
  String get gettingAddress;

  /// No description provided for @noRecentPlaces.
  ///
  /// In en, this message translates to:
  /// **'No recent places'**
  String get noRecentPlaces;

  /// No description provided for @setLocation.
  ///
  /// In en, this message translates to:
  /// **'Set location'**
  String get setLocation;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @searchResults2.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults2;

  /// No description provided for @dragTheMapToSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to set location'**
  String get dragTheMapToSetLocation;

  /// No description provided for @rideMap.
  ///
  /// In en, this message translates to:
  /// **'Ride map'**
  String get rideMap;

  /// No description provided for @loadingMap.
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get loadingMap;

  /// No description provided for @mapError.
  ///
  /// In en, this message translates to:
  /// **'Map error'**
  String get mapError;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @tripPreview.
  ///
  /// In en, this message translates to:
  /// **'Trip Preview'**
  String get tripPreview;

  /// No description provided for @distance2.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String distance2(String distance);

  /// No description provided for @duration2.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String duration2(String duration);

  /// No description provided for @fareEstimate.
  ///
  /// In en, this message translates to:
  /// **'Fare estimate: {fare}'**
  String fareEstimate(String fare);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @dropoff.
  ///
  /// In en, this message translates to:
  /// **'Dropoff'**
  String get dropoff;

  /// No description provided for @rider2.
  ///
  /// In en, this message translates to:
  /// **'Rider: {name}'**
  String rider2(String name);

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating}'**
  String rating(String rating);

  /// No description provided for @yourRides.
  ///
  /// In en, this message translates to:
  /// **'Your Rides'**
  String get yourRides;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @noPastRides.
  ///
  /// In en, this message translates to:
  /// **'No past rides'**
  String get noPastRides;

  /// No description provided for @noUpcomingRides.
  ///
  /// In en, this message translates to:
  /// **'No upcoming rides'**
  String get noUpcomingRides;

  /// No description provided for @noScheduledRides.
  ///
  /// In en, this message translates to:
  /// **'No scheduled rides'**
  String get noScheduledRides;

  /// No description provided for @fromTo.
  ///
  /// In en, this message translates to:
  /// **'From {pickup} to {dropoff}'**
  String fromTo(String pickup, String dropoff);

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @scheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {date}'**
  String scheduledFor(String date);

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @passengers.
  ///
  /// In en, this message translates to:
  /// **'{count} passengers'**
  String passengers(String count);

  /// No description provided for @rideOn.
  ///
  /// In en, this message translates to:
  /// **'Ride on {date}'**
  String rideOn(String date);

  /// No description provided for @redirecting.
  ///
  /// In en, this message translates to:
  /// **'Redirecting...'**
  String get redirecting;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @continueAsRider.
  ///
  /// In en, this message translates to:
  /// **'Continue as Rider'**
  String get continueAsRider;

  /// No description provided for @continueAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Continue as Driver'**
  String get continueAsDriver;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// No description provided for @debugLogs.
  ///
  /// In en, this message translates to:
  /// **'Debug Logs'**
  String get debugLogs;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @copyLogs.
  ///
  /// In en, this message translates to:
  /// **'Copy logs'**
  String get copyLogs;

  /// No description provided for @logsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logsCopiedToClipboard;

  /// No description provided for @logsCleared.
  ///
  /// In en, this message translates to:
  /// **'Logs cleared'**
  String get logsCleared;

  /// No description provided for @noLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get noLogs;

  /// No description provided for @shareLogs.
  ///
  /// In en, this message translates to:
  /// **'Share logs'**
  String get shareLogs;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @toggleServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Toggle server URL'**
  String get toggleServerUrl;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @enterServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter server URL'**
  String get enterServerUrl;

  /// No description provided for @showDebugBanner.
  ///
  /// In en, this message translates to:
  /// **'Show debug banner'**
  String get showDebugBanner;

  /// No description provided for @hideDebugBanner.
  ///
  /// In en, this message translates to:
  /// **'Hide debug banner'**
  String get hideDebugBanner;

  /// No description provided for @simulateRideEvents.
  ///
  /// In en, this message translates to:
  /// **'Simulate ride events'**
  String get simulateRideEvents;

  /// No description provided for @exportLogs.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogs;

  /// No description provided for @downloadingLogs.
  ///
  /// In en, this message translates to:
  /// **'Downloading logs...'**
  String get downloadingLogs;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip History'**
  String get tripHistory;

  /// No description provided for @noTripsYet.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get noTripsYet;

  /// No description provided for @yourCompletedTripsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your completed trips will appear here'**
  String get yourCompletedTripsWillAppearHere;

  /// No description provided for @completedOn.
  ///
  /// In en, this message translates to:
  /// **'Completed on {date}'**
  String completedOn(String date);

  /// No description provided for @fare2.
  ///
  /// In en, this message translates to:
  /// **'Fare: {amount}'**
  String fare2(String amount);

  /// No description provided for @viewTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get viewTrip;

  /// No description provided for @driver2.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String driver2(String name);

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @searchTrips.
  ///
  /// In en, this message translates to:
  /// **'Search trips...'**
  String get searchTrips;

  /// No description provided for @noTripsFound.
  ///
  /// In en, this message translates to:
  /// **'No trips found'**
  String get noTripsFound;

  /// No description provided for @failedToLoadTrips.
  ///
  /// In en, this message translates to:
  /// **'Failed to load trips'**
  String get failedToLoadTrips;

  /// No description provided for @tripBehaviour.
  ///
  /// In en, this message translates to:
  /// **'Trip Behaviour'**
  String get tripBehaviour;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @recordingStarted.
  ///
  /// In en, this message translates to:
  /// **'Recording started'**
  String get recordingStarted;

  /// No description provided for @recordingStopped.
  ///
  /// In en, this message translates to:
  /// **'Recording stopped'**
  String get recordingStopped;

  /// No description provided for @recordedEvents.
  ///
  /// In en, this message translates to:
  /// **'Recorded events: {count}'**
  String recordedEvents(String count);

  /// No description provided for @clearEvents.
  ///
  /// In en, this message translates to:
  /// **'Clear events'**
  String get clearEvents;

  /// No description provided for @exportEvents.
  ///
  /// In en, this message translates to:
  /// **'Export events'**
  String get exportEvents;

  /// No description provided for @eventsExported.
  ///
  /// In en, this message translates to:
  /// **'Events exported'**
  String get eventsExported;

  /// No description provided for @noEventsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No events recorded'**
  String get noEventsRecorded;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get timestamp;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replay;

  /// No description provided for @eventLog.
  ///
  /// In en, this message translates to:
  /// **'Event log'**
  String get eventLog;

  /// No description provided for @recordingSaved.
  ///
  /// In en, this message translates to:
  /// **'Recording saved'**
  String get recordingSaved;

  /// No description provided for @failedToSaveRecording.
  ///
  /// In en, this message translates to:
  /// **'Failed to save recording'**
  String get failedToSaveRecording;

  /// No description provided for @tripReplay.
  ///
  /// In en, this message translates to:
  /// **'Trip Replay'**
  String get tripReplay;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @speedX.
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed}x'**
  String speedX(String speed);

  /// No description provided for @replaySpeed.
  ///
  /// In en, this message translates to:
  /// **'Replay speed'**
  String get replaySpeed;

  /// No description provided for @tripTimeline.
  ///
  /// In en, this message translates to:
  /// **'Trip timeline'**
  String get tripTimeline;

  /// No description provided for @noTripDataToReplay.
  ///
  /// In en, this message translates to:
  /// **'No trip data to replay'**
  String get noTripDataToReplay;

  /// No description provided for @loadingReplay.
  ///
  /// In en, this message translates to:
  /// **'Loading replay...'**
  String get loadingReplay;

  /// No description provided for @replayComplete.
  ///
  /// In en, this message translates to:
  /// **'Replay complete'**
  String get replayComplete;

  /// No description provided for @tripDuration.
  ///
  /// In en, this message translates to:
  /// **'Trip duration: {duration}'**
  String tripDuration(String duration);

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get mapView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get listView;

  /// No description provided for @eventAt.
  ///
  /// In en, this message translates to:
  /// **'Event: {type} at {time}'**
  String eventAt(String type, String time);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @scheduledRideIn30Min.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride in 30 min'**
  String get scheduledRideIn30Min;

  /// No description provided for @scheduledRideWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride was cancelled'**
  String get scheduledRideWasCancelled;

  /// No description provided for @aScheduledRideWasCancelledByTheRider.
  ///
  /// In en, this message translates to:
  /// **'A scheduled ride was cancelled by the rider'**
  String get aScheduledRideWasCancelledByTheRider;

  /// No description provided for @aScheduledRideHasExpired.
  ///
  /// In en, this message translates to:
  /// **'A scheduled ride has expired'**
  String get aScheduledRideHasExpired;

  /// No description provided for @rideHasBeenCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride has been cancelled'**
  String get rideHasBeenCancelled;

  /// No description provided for @pleaseEnableGpslocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS/Location services'**
  String get pleaseEnableGpslocationServices;

  /// No description provided for @locationPermissionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionIsRequired;

  /// No description provided for @locationPermissionDeniedPleaseEnableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please enable in settings.'**
  String get locationPermissionDeniedPleaseEnableInSettings;

  /// No description provided for @recenterMap.
  ///
  /// In en, this message translates to:
  /// **'Recenter map'**
  String get recenterMap;

  /// No description provided for @activeRide.
  ///
  /// In en, this message translates to:
  /// **'Active Ride'**
  String get activeRide;

  /// No description provided for @pickupEtaMin.
  ///
  /// In en, this message translates to:
  /// **'Pickup ETA: -- min'**
  String get pickupEtaMin;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @toggleOnlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Toggle online status'**
  String get toggleOnlineStatus;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go Offline'**
  String get goOffline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @noNearbyRides.
  ///
  /// In en, this message translates to:
  /// **'No nearby rides'**
  String get noNearbyRides;

  /// No description provided for @rideNearby.
  ///
  /// In en, this message translates to:
  /// **'{count} ride nearby'**
  String rideNearby(String count);

  /// No description provided for @ridesNearby.
  ///
  /// In en, this message translates to:
  /// **'{count} rides nearby'**
  String ridesNearby(String count);

  /// No description provided for @availableRides.
  ///
  /// In en, this message translates to:
  /// **'Available Rides'**
  String get availableRides;

  /// No description provided for @noRidesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No rides available'**
  String get noRidesAvailable;

  /// No description provided for @newRideRequestsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'New ride requests will appear here'**
  String get newRideRequestsWillAppearHere;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Now'**
  String get availableNow;

  /// No description provided for @scheduledRides.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Rides'**
  String get scheduledRides;

  /// No description provided for @myUpcoming.
  ///
  /// In en, this message translates to:
  /// **'My Upcoming'**
  String get myUpcoming;

  /// No description provided for @todaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s earnings'**
  String get todaysEarnings;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @lifetimeEarnings.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Earnings'**
  String get lifetimeEarnings;

  /// No description provided for @platformFees15.
  ///
  /// In en, this message translates to:
  /// **'Platform Fees (15%)'**
  String get platformFees15;

  /// No description provided for @amountSettled.
  ///
  /// In en, this message translates to:
  /// **'Amount Settled'**
  String get amountSettled;

  /// No description provided for @outstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get outstandingBalance;

  /// No description provided for @lastSettlement.
  ///
  /// In en, this message translates to:
  /// **'Last Settlement: {date}'**
  String lastSettlement(String date);

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @rating2.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating2;

  /// No description provided for @totalRides.
  ///
  /// In en, this message translates to:
  /// **'Total Rides'**
  String get totalRides;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @na.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get na;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get arrived;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @acceptScheduledRide.
  ///
  /// In en, this message translates to:
  /// **'Accept Scheduled Ride'**
  String get acceptScheduledRide;

  /// No description provided for @acceptRideScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Accept ride scheduled for {date}?'**
  String acceptRideScheduledFor(String date);

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @scheduledRideAccepted.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride accepted'**
  String get scheduledRideAccepted;

  /// No description provided for @cancelScheduledRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel Scheduled Ride'**
  String get cancelScheduledRide;

  /// No description provided for @releaseThisRideSoOtherDriversCanAcceptIt.
  ///
  /// In en, this message translates to:
  /// **'Release this ride so other drivers can accept it?'**
  String get releaseThisRideSoOtherDriversCanAcceptIt;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @release.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get release;

  /// No description provided for @scheduledRideReleased.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride released'**
  String get scheduledRideReleased;

  /// No description provided for @markedAsArrivedAskRiderForPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Marked as arrived — ask rider for pickup code'**
  String get markedAsArrivedAskRiderForPickupCode;

  /// No description provided for @enterPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Pickup Code'**
  String get enterPickupCode;

  /// No description provided for @askTheRiderForThe6digitPickupCode.
  ///
  /// In en, this message translates to:
  /// **'Ask the rider for the 6-digit pickup code'**
  String get askTheRiderForThe6digitPickupCode;

  /// No description provided for @verifyStart.
  ///
  /// In en, this message translates to:
  /// **'Verify & Start'**
  String get verifyStart;

  /// No description provided for @invalidCodePleaseTryAgain2.
  ///
  /// In en, this message translates to:
  /// **'Invalid code — please try again'**
  String get invalidCodePleaseTryAgain2;

  /// No description provided for @rideStartedNavigatingToTrip.
  ///
  /// In en, this message translates to:
  /// **'Ride started — navigating to trip'**
  String get rideStartedNavigatingToTrip;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start'**
  String get readyToStart;

  /// No description provided for @chatWithRider.
  ///
  /// In en, this message translates to:
  /// **'Chat with rider'**
  String get chatWithRider;

  /// No description provided for @chatWithRider2.
  ///
  /// In en, this message translates to:
  /// **'Chat with Rider'**
  String get chatWithRider2;

  /// No description provided for @toggleDriverMarker.
  ///
  /// In en, this message translates to:
  /// **'Toggle driver marker'**
  String get toggleDriverMarker;

  /// No description provided for @rideStarted2.
  ///
  /// In en, this message translates to:
  /// **'Ride started!'**
  String get rideStarted2;

  /// No description provided for @theRiderCancelledTheRide.
  ///
  /// In en, this message translates to:
  /// **'The rider cancelled the ride.'**
  String get theRiderCancelledTheRide;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reason(String reason);

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION'**
  String get destination;

  /// No description provided for @didTheCustomerPayInCash.
  ///
  /// In en, this message translates to:
  /// **'Did the customer pay in cash?'**
  String get didTheCustomerPayInCash;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash Received'**
  String get cashReceived;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @didNotPay.
  ///
  /// In en, this message translates to:
  /// **'Did Not Pay'**
  String get didNotPay;

  /// No description provided for @completeRide.
  ///
  /// In en, this message translates to:
  /// **'Complete Ride'**
  String get completeRide;

  /// No description provided for @completing.
  ///
  /// In en, this message translates to:
  /// **'Completing...'**
  String get completing;

  /// No description provided for @startRide.
  ///
  /// In en, this message translates to:
  /// **'Start Ride'**
  String get startRide;

  /// No description provided for @navigateToDestination.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Destination'**
  String get navigateToDestination;

  /// No description provided for @couldNotOpenMapsLinkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Could not open Maps — link copied to clipboard'**
  String get couldNotOpenMapsLinkCopiedToClipboard;

  /// No description provided for @rideInProgress.
  ///
  /// In en, this message translates to:
  /// **'Ride in progress'**
  String get rideInProgress;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @navigateToRider.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Rider'**
  String get navigateToRider;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your Location'**
  String get yourLocation;

  /// No description provided for @pickup2.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {address}'**
  String pickup2(String address);

  /// No description provided for @riderNotified.
  ///
  /// In en, this message translates to:
  /// **'Rider notified!'**
  String get riderNotified;

  /// No description provided for @rideWasCancelled.
  ///
  /// In en, this message translates to:
  /// **'Ride was cancelled'**
  String get rideWasCancelled;

  /// No description provided for @pickup3.
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get pickup3;

  /// No description provided for @iveArrived.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Arrived'**
  String get iveArrived;

  /// No description provided for @notifying.
  ///
  /// In en, this message translates to:
  /// **'Notifying...'**
  String get notifying;

  /// No description provided for @openGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Google Maps'**
  String get openGoogleMaps;

  /// No description provided for @cancelRide2.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride'**
  String get cancelRide2;

  /// No description provided for @youHaveArrived2.
  ///
  /// In en, this message translates to:
  /// **'You have arrived!'**
  String get youHaveArrived2;

  /// No description provided for @riderHasBeenNotified.
  ///
  /// In en, this message translates to:
  /// **'Rider has been notified'**
  String get riderHasBeenNotified;

  /// No description provided for @goBack2.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack2;

  /// No description provided for @registrationStepOf.
  ///
  /// In en, this message translates to:
  /// **'Registration step {current} of {total}'**
  String registrationStepOf(String current, String total);

  /// No description provided for @becomeADriver.
  ///
  /// In en, this message translates to:
  /// **'Become a Driver'**
  String get becomeADriver;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get reviewSubmit;

  /// No description provided for @enterYourDrivingLicenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your driving license details'**
  String get enterYourDrivingLicenseDetails;

  /// No description provided for @tellUsAboutYourVehicle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your vehicle'**
  String get tellUsAboutYourVehicle;

  /// No description provided for @verifyYourInformationBeforeSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Verify your information before submitting'**
  String get verifyYourInformationBeforeSubmitting;

  /// No description provided for @licenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License Number'**
  String get licenseNumber;

  /// No description provided for @egDl123456789.
  ///
  /// In en, this message translates to:
  /// **'e.g., DL123456789'**
  String get egDl123456789;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumber;

  /// No description provided for @egAbc1234.
  ///
  /// In en, this message translates to:
  /// **'e.g., ABC-1234'**
  String get egAbc1234;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @bike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// No description provided for @van.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get van;

  /// No description provided for @vehicleModel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Model'**
  String get vehicleModel;

  /// No description provided for @egToyotaCamry.
  ///
  /// In en, this message translates to:
  /// **'e.g., Toyota Camry'**
  String get egToyotaCamry;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Color'**
  String get vehicleColor;

  /// No description provided for @egWhite.
  ///
  /// In en, this message translates to:
  /// **'e.g., White'**
  String get egWhite;

  /// No description provided for @vehicleYear.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Year'**
  String get vehicleYear;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @submitRegistration.
  ///
  /// In en, this message translates to:
  /// **'Submit registration'**
  String get submitRegistration;

  /// No description provided for @submitRegistration2.
  ///
  /// In en, this message translates to:
  /// **'Submit Registration'**
  String get submitRegistration2;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get previousStep;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @driverProfileRegistered.
  ///
  /// In en, this message translates to:
  /// **'Driver profile registered!'**
  String get driverProfileRegistered;

  /// No description provided for @driverProfileRegistrationFailedYouMayAlreadyBeRegistered.
  ///
  /// In en, this message translates to:
  /// **'Driver profile registration failed. You may already be registered.'**
  String get driverProfileRegistrationFailedYouMayAlreadyBeRegistered;

  /// No description provided for @pleaseEnterYourLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your license number'**
  String get pleaseEnterYourLicenseNumber;

  /// No description provided for @pleaseFillAllVehicleFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all vehicle fields'**
  String get pleaseFillAllVehicleFields;

  /// No description provided for @reviewYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Review your details'**
  String get reviewYourDetails;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(String current, String total);

  /// No description provided for @rideSummary.
  ///
  /// In en, this message translates to:
  /// **'Ride Summary'**
  String get rideSummary;

  /// No description provided for @rideCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ride completed successfully'**
  String get rideCompletedSuccessfully;

  /// No description provided for @rideComplete.
  ///
  /// In en, this message translates to:
  /// **'Ride Complete!'**
  String get rideComplete;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{duration} minutes'**
  String minutes(String duration);

  /// No description provided for @totalFare3.
  ///
  /// In en, this message translates to:
  /// **'Total Fare'**
  String get totalFare3;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pending;

  /// No description provided for @yourEarnings.
  ///
  /// In en, this message translates to:
  /// **'Your Earnings'**
  String get yourEarnings;

  /// No description provided for @platformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get platformFee;

  /// No description provided for @rateYourRider.
  ///
  /// In en, this message translates to:
  /// **'Rate your rider'**
  String get rateYourRider;

  /// No description provided for @additionalFeedbackOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional feedback (optional)'**
  String get additionalFeedbackOptional;

  /// No description provided for @submitRating2.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating2;

  /// No description provided for @ratingSubmittedThankYou.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted — thank you!'**
  String get ratingSubmittedThankYou;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @pleaseSelectARating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectARating;

  /// No description provided for @adminTripInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Admin — Trip Investigation'**
  String get adminTripInvestigation;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @rideId.
  ///
  /// In en, this message translates to:
  /// **'Ride ID'**
  String get rideId;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @riderName.
  ///
  /// In en, this message translates to:
  /// **'Rider Name'**
  String get riderName;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @search2.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search2;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @failedToLoadDriverDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load driver details'**
  String get failedToLoadDriverDetails;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @onRide.
  ///
  /// In en, this message translates to:
  /// **'On Ride'**
  String get onRide;

  /// No description provided for @unverify.
  ///
  /// In en, this message translates to:
  /// **'Unverify'**
  String get unverify;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @plate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get plate;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @rides.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last Seen'**
  String get lastSeen;

  /// No description provided for @currentRide.
  ///
  /// In en, this message translates to:
  /// **'Current Ride'**
  String get currentRide;

  /// No description provided for @ride2.
  ///
  /// In en, this message translates to:
  /// **'Ride #'**
  String get ride2;

  /// No description provided for @recentRides.
  ///
  /// In en, this message translates to:
  /// **'Recent Rides'**
  String get recentRides;

  /// No description provided for @blockThisDriverTheyWillBeUnableToLoginOrAcceptRides.
  ///
  /// In en, this message translates to:
  /// **'Block this driver? They will be unable to login or accept rides.'**
  String get blockThisDriverTheyWillBeUnableToLoginOrAcceptRides;

  /// No description provided for @unblockThisDriver.
  ///
  /// In en, this message translates to:
  /// **'Unblock this driver?'**
  String get unblockThisDriver;

  /// No description provided for @allDrivers.
  ///
  /// In en, this message translates to:
  /// **'All Drivers'**
  String get allDrivers;

  /// No description provided for @searchByNameVehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Search by name, vehicle, plate...'**
  String get searchByNameVehiclePlate;

  /// No description provided for @failedToLoadDrivers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load drivers'**
  String get failedToLoadDrivers;

  /// No description provided for @noDriversFound2.
  ///
  /// In en, this message translates to:
  /// **'No drivers found'**
  String get noDriversFound2;

  /// No description provided for @earningsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Earnings Dashboard'**
  String get earningsDashboard;

  /// No description provided for @settlementLedger.
  ///
  /// In en, this message translates to:
  /// **'Settlement Ledger'**
  String get settlementLedger;

  /// No description provided for @failedToLoadEarningsData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load earnings data'**
  String get failedToLoadEarningsData;

  /// No description provided for @topDrivers.
  ///
  /// In en, this message translates to:
  /// **'Top Drivers'**
  String get topDrivers;

  /// No description provided for @noEarningsDataYet.
  ///
  /// In en, this message translates to:
  /// **'No earnings data yet'**
  String get noEarningsDataYet;

  /// No description provided for @revenueOverview.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueOverview;

  /// No description provided for @grossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross Revenue'**
  String get grossRevenue;

  /// No description provided for @driverPayouts.
  ///
  /// In en, this message translates to:
  /// **'Driver Payouts'**
  String get driverPayouts;

  /// No description provided for @rides2.
  ///
  /// In en, this message translates to:
  /// **'{count} rides'**
  String rides2(String count);

  /// No description provided for @createSettlement.
  ///
  /// In en, this message translates to:
  /// **'Create Settlement'**
  String get createSettlement;

  /// No description provided for @noSettlementsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No settlements recorded'**
  String get noSettlementsRecorded;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'SETTLED'**
  String get settled;

  /// No description provided for @gross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get gross;

  /// No description provided for @fee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get fee;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @ref.
  ///
  /// In en, this message translates to:
  /// **'Ref: {ref}'**
  String ref(String ref);

  /// No description provided for @receipt2.
  ///
  /// In en, this message translates to:
  /// **'Receipt: {receipt}'**
  String receipt2(String receipt);

  /// No description provided for @driverId.
  ///
  /// In en, this message translates to:
  /// **'Driver ID'**
  String get driverId;

  /// No description provided for @enterDriverUserId.
  ///
  /// In en, this message translates to:
  /// **'Enter driver user ID'**
  String get enterDriverUserId;

  /// No description provided for @grossAmount.
  ///
  /// In en, this message translates to:
  /// **'Gross Amount'**
  String get grossAmount;

  /// No description provided for @appFee.
  ///
  /// In en, this message translates to:
  /// **'App Fee'**
  String get appFee;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmount;

  /// No description provided for @settlementReference.
  ///
  /// In en, this message translates to:
  /// **'Settlement Reference'**
  String get settlementReference;

  /// No description provided for @egStl001.
  ///
  /// In en, this message translates to:
  /// **'e.g. STL-001'**
  String get egStl001;

  /// No description provided for @receiptNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Receipt Number (optional)'**
  String get receiptNumberOptional;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @settlementDashboard.
  ///
  /// In en, this message translates to:
  /// **'Settlement Dashboard'**
  String get settlementDashboard;

  /// No description provided for @payToday.
  ///
  /// In en, this message translates to:
  /// **'Pay Today'**
  String get payToday;

  /// No description provided for @recommendedSettlement.
  ///
  /// In en, this message translates to:
  /// **'Recommended Settlement'**
  String get recommendedSettlement;

  /// No description provided for @waitingForPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Payment'**
  String get waitingForPayment;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get underReview;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payable;

  /// No description provided for @waitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waitingPayment;

  /// No description provided for @underReviewShort.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get underReviewShort;

  /// No description provided for @rejectedShort.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedShort;

  /// No description provided for @settlementRange.
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get settlementRange;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @noSettlementData.
  ///
  /// In en, this message translates to:
  /// **'No settlement data for the selected period'**
  String get noSettlementData;

  /// No description provided for @noDriversInRange.
  ///
  /// In en, this message translates to:
  /// **'No drivers found in this range'**
  String get noDriversInRange;

  /// No description provided for @driverSettlementDetails.
  ///
  /// In en, this message translates to:
  /// **'Driver Settlement Details'**
  String get driverSettlementDetails;

  /// No description provided for @settlementStatus.
  ///
  /// In en, this message translates to:
  /// **'Settlement Status'**
  String get settlementStatus;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @reasons.
  ///
  /// In en, this message translates to:
  /// **'Reasons'**
  String get reasons;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get sortDate;

  /// No description provided for @sortScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get sortScore;

  /// No description provided for @sortNet.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get sortNet;

  /// No description provided for @completedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed Trips'**
  String get completedTrips;

  /// No description provided for @reliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reliability;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @settlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get settlement;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @unverifiedRides.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverifiedRides;

  /// No description provided for @suspicious.
  ///
  /// In en, this message translates to:
  /// **'Suspicious'**
  String get suspicious;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @trips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get trips;

  /// No description provided for @trip.
  ///
  /// In en, this message translates to:
  /// **'Trip #{id}'**
  String trip(String id);

  /// No description provided for @enableRetention.
  ///
  /// In en, this message translates to:
  /// **'Enable retention'**
  String get enableRetention;

  /// No description provided for @disableRetention.
  ///
  /// In en, this message translates to:
  /// **'Disable retention'**
  String get disableRetention;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @tripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripNotFound;

  /// No description provided for @errorLoadingTrip.
  ///
  /// In en, this message translates to:
  /// **'Error loading trip'**
  String get errorLoadingTrip;

  /// No description provided for @failedToLoadEventsTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load events. Tap to retry.'**
  String get failedToLoadEventsTapToRetry;

  /// No description provided for @noTimelineEvents.
  ///
  /// In en, this message translates to:
  /// **'No timeline events'**
  String get noTimelineEvents;

  /// No description provided for @addAnInvestigationNote.
  ///
  /// In en, this message translates to:
  /// **'Add an investigation note...'**
  String get addAnInvestigationNote;

  /// No description provided for @failedToLoadRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load. Retry.'**
  String get failedToLoadRetry;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @adminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotes;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatMessages3.
  ///
  /// In en, this message translates to:
  /// **'Chat Messages ({count})'**
  String chatMessages3(String count);

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @reason2.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason2;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @rideInfo.
  ///
  /// In en, this message translates to:
  /// **'Ride Info'**
  String get rideInfo;

  /// No description provided for @pickupCoord.
  ///
  /// In en, this message translates to:
  /// **'Pickup Coord'**
  String get pickupCoord;

  /// No description provided for @dropoffCoord.
  ///
  /// In en, this message translates to:
  /// **'Dropoff Coord'**
  String get dropoffCoord;

  /// No description provided for @min2.
  ///
  /// In en, this message translates to:
  /// **'{duration} min'**
  String min2(String duration);

  /// No description provided for @estFare.
  ///
  /// In en, this message translates to:
  /// **'Est. Fare'**
  String get estFare;

  /// No description provided for @finalFare.
  ///
  /// In en, this message translates to:
  /// **'Final Fare'**
  String get finalFare;

  /// No description provided for @retentionEnabledForThisRide.
  ///
  /// In en, this message translates to:
  /// **'Retention enabled for this ride'**
  String get retentionEnabledForThisRide;

  /// No description provided for @retentionDisabledForThisRide.
  ///
  /// In en, this message translates to:
  /// **'Retention disabled for this ride'**
  String get retentionDisabledForThisRide;

  /// No description provided for @failedToUpdateRetention.
  ///
  /// In en, this message translates to:
  /// **'Failed to update retention'**
  String get failedToUpdateRetention;

  /// No description provided for @noteAdded.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteAdded;

  /// No description provided for @failedToAddNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to add note'**
  String get failedToAddNote;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @typing.
  ///
  /// In en, this message translates to:
  /// **'typing'**
  String get typing;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @sendAMessageToStartChatting.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start chatting'**
  String get sendAMessageToStartChatting;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @isTyping.
  ///
  /// In en, this message translates to:
  /// **'{name} is typing...'**
  String isTyping(String name);

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @onMyWay.
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get onMyWay;

  /// No description provided for @beThereSoon.
  ///
  /// In en, this message translates to:
  /// **'Be there soon'**
  String get beThereSoon;

  /// No description provided for @thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks!'**
  String get thanks;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @rideDetails.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetails;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @pickupCode.
  ///
  /// In en, this message translates to:
  /// **'Pickup Code'**
  String get pickupCode;

  /// No description provided for @shareThisCodeWithYourDriverToStartTheRide.
  ///
  /// In en, this message translates to:
  /// **'Share this code with your driver to start the ride'**
  String get shareThisCodeWithYourDriverToStartTheRide;

  /// No description provided for @cancelRide3.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride?'**
  String get cancelRide3;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @riderCancelledRide.
  ///
  /// In en, this message translates to:
  /// **'Rider cancelled ride'**
  String get riderCancelledRide;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @turnOnLocationItWillHelpUsFindYourRider.
  ///
  /// In en, this message translates to:
  /// **'Turn on location — it will help us find your rider.'**
  String get turnOnLocationItWillHelpUsFindYourRider;

  /// No description provided for @turnOnLocationItWillHelpUsFindYourDriver.
  ///
  /// In en, this message translates to:
  /// **'Turn on location — it will help us find your driver.'**
  String get turnOnLocationItWillHelpUsFindYourDriver;

  /// No description provided for @allowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get allowLocation;

  /// No description provided for @allowLocation2.
  ///
  /// In en, this message translates to:
  /// **'Allow Location'**
  String get allowLocation2;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @setDropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Set drop-off location'**
  String get setDropoffLocation;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address...'**
  String get findingAddress;

  /// No description provided for @moveTheMapToSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Move the map to select location'**
  String get moveTheMapToSelectLocation;

  /// No description provided for @moveTheMap.
  ///
  /// In en, this message translates to:
  /// **'Move the map'**
  String get moveTheMap;

  /// No description provided for @confirmLocation2.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation2;

  /// No description provided for @noPastRidesYet.
  ///
  /// In en, this message translates to:
  /// **'No past rides yet'**
  String get noPastRidesYet;

  /// No description provided for @yourTripHasBeenCompleted.
  ///
  /// In en, this message translates to:
  /// **'Your trip has been completed.'**
  String get yourTripHasBeenCompleted;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received?'**
  String get paymentReceived;

  /// No description provided for @didYouReceiveThisPayment.
  ///
  /// In en, this message translates to:
  /// **'Did you receive this payment?'**
  String get didYouReceiveThisPayment;

  /// No description provided for @reasonRequiredIfNo.
  ///
  /// In en, this message translates to:
  /// **'Reason (required if No)'**
  String get reasonRequiredIfNo;

  /// No description provided for @pleaseProvideAReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason'**
  String get pleaseProvideAReason;

  /// No description provided for @noIDidnt.
  ///
  /// In en, this message translates to:
  /// **'No, I didn\'t'**
  String get noIDidnt;

  /// No description provided for @yesReceived.
  ///
  /// In en, this message translates to:
  /// **'Yes, Received'**
  String get yesReceived;

  /// No description provided for @scheduleYourLaterRide.
  ///
  /// In en, this message translates to:
  /// **'Schedule your later ride'**
  String get scheduleYourLaterRide;

  /// No description provided for @scheduleRideAt.
  ///
  /// In en, this message translates to:
  /// **'Schedule Ride — {date} at {time}'**
  String scheduleRideAt(String date, String time);

  /// No description provided for @pleaseSelectAFutureDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select a future date and time'**
  String get pleaseSelectAFutureDateAndTime;

  /// No description provided for @rideScheduledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Ride scheduled successfully!'**
  String get rideScheduledSuccessfully;

  /// No description provided for @failedToScheduleRide.
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule ride'**
  String get failedToScheduleRide;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get anUnexpectedErrorOccurred;

  /// No description provided for @noLocationsFound.
  ///
  /// In en, this message translates to:
  /// **'No locations found'**
  String get noLocationsFound;

  /// No description provided for @startTypingToSearchLocations.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search locations'**
  String get startTypingToSearchLocations;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @pending2.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending2;

  /// No description provided for @arriving.
  ///
  /// In en, this message translates to:
  /// **'Arriving'**
  String get arriving;

  /// No description provided for @laterRide.
  ///
  /// In en, this message translates to:
  /// **'Later Ride'**
  String get laterRide;

  /// No description provided for @scheduleARideUsingTheButtonAbove.
  ///
  /// In en, this message translates to:
  /// **'Schedule a ride using the button above'**
  String get scheduleARideUsingTheButtonAbove;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @invalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get invalidEmailFormat;

  /// No description provided for @countryCodeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Country code is required'**
  String get countryCodeIsRequired;

  /// No description provided for @phoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get emailAlreadyRegistered;

  /// No description provided for @phoneNumberAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Phone number already registered'**
  String get phoneNumberAlreadyRegistered;

  /// No description provided for @registrationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Registration successful!'**
  String get registrationSuccessful;

  /// No description provided for @emailAndPasswordAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required'**
  String get emailAndPasswordAreRequired;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @accountIsBlockedContactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Account is blocked. Contact admin.'**
  String get accountIsBlockedContactAdmin;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized'**
  String get unauthorized;

  /// No description provided for @deviceTokenUpdated.
  ///
  /// In en, this message translates to:
  /// **'Device token updated'**
  String get deviceTokenUpdated;

  /// No description provided for @error2.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error2(String error);

  /// No description provided for @noAccountFoundWithThatEmail.
  ///
  /// In en, this message translates to:
  /// **'No account found with that email'**
  String get noAccountFoundWithThatEmail;

  /// No description provided for @tooManyRequestsPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequestsPleaseTryAgainLater;

  /// No description provided for @failedToSendOtpPleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get failedToSendOtpPleaseTryAgain;

  /// No description provided for @otpSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// No description provided for @emailAndCodeAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and code are required'**
  String get emailAndCodeAreRequired;

  /// No description provided for @invalidOrExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired OTP'**
  String get invalidOrExpiredOtp;

  /// No description provided for @otpHasExpired.
  ///
  /// In en, this message translates to:
  /// **'OTP has expired'**
  String get otpHasExpired;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @tooManyAttemptsPleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get tooManyAttemptsPleaseTryAgainLater;

  /// No description provided for @ifAnAccountWithThatEmailExistsAnOtpHasBeenSent.
  ///
  /// In en, this message translates to:
  /// **'If an account with that email exists, an OTP has been sent.'**
  String get ifAnAccountWithThatEmailExistsAnOtpHasBeenSent;

  /// No description provided for @emailCodeAndNewPasswordAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Email, code, and new password are required'**
  String get emailCodeAndNewPasswordAreRequired;

  /// No description provided for @passwordHasBeenResetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully'**
  String get passwordHasBeenResetSuccessfully;

  /// No description provided for @otpIsValid.
  ///
  /// In en, this message translates to:
  /// **'OTP is valid'**
  String get otpIsValid;

  /// No description provided for @yourLoginCode.
  ///
  /// In en, this message translates to:
  /// **'Your Login Code'**
  String get yourLoginCode;

  /// No description provided for @passwordResetYourOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Password Reset - Your OTP Code'**
  String get passwordResetYourOtpCode;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get hello;

  /// No description provided for @yourVerificationCodeIs.
  ///
  /// In en, this message translates to:
  /// **'Your verification code is: {otp}'**
  String yourVerificationCodeIs(String otp);

  /// No description provided for @thisCodeWillExpireIn10Minutes.
  ///
  /// In en, this message translates to:
  /// **'This code will expire in 10 minutes.'**
  String get thisCodeWillExpireIn10Minutes;

  /// No description provided for @ifYouDidntRequestThisCodePleaseIgnoreThisEmail.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t request this code, please ignore this email.'**
  String get ifYouDidntRequestThisCodePleaseIgnoreThisEmail;

  /// No description provided for @bestRegards.
  ///
  /// In en, this message translates to:
  /// **'Best regards,'**
  String get bestRegards;

  /// No description provided for @ridenowTeam.
  ///
  /// In en, this message translates to:
  /// **'RideNow Team'**
  String get ridenowTeam;

  /// No description provided for @yourPasswordResetCodeIs.
  ///
  /// In en, this message translates to:
  /// **'Your password reset code is: {otp}'**
  String yourPasswordResetCodeIs(String otp);

  /// No description provided for @ifYouDidntRequestAPasswordResetPleaseIgnoreThisEmail.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t request a password reset, please ignore this email.'**
  String get ifYouDidntRequestAPasswordResetPleaseIgnoreThisEmail;

  /// No description provided for @ridetypeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'rideType is required'**
  String get ridetypeIsRequired;

  /// No description provided for @latitudeAndLongitudeRequired.
  ///
  /// In en, this message translates to:
  /// **'latitude and longitude required'**
  String get latitudeAndLongitudeRequired;

  /// No description provided for @noActiveRide.
  ///
  /// In en, this message translates to:
  /// **'No active ride'**
  String get noActiveRide;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get locationUpdated;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminAccessRequired;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get emailAlreadyInUse;

  /// No description provided for @logoutSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccessful;

  /// No description provided for @alreadyRegisteredAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Already registered as driver'**
  String get alreadyRegisteredAsDriver;

  /// No description provided for @driverProfileCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Driver profile created successfully.'**
  String get driverProfileCreatedSuccessfully;

  /// No description provided for @driverProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver profile not found'**
  String get driverProfileNotFound;

  /// No description provided for @onlineStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Online status updated'**
  String get onlineStatusUpdated;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @invalidStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid status value: {status}'**
  String invalidStatusValue(String status);

  /// No description provided for @retentionEnabledForRide.
  ///
  /// In en, this message translates to:
  /// **'Retention enabled for ride {id}'**
  String retentionEnabledForRide(String id);

  /// No description provided for @retentionDisabledForRide.
  ///
  /// In en, this message translates to:
  /// **'Retention disabled for ride {id}'**
  String retentionDisabledForRide(String id);

  /// No description provided for @noteAddedToRide.
  ///
  /// In en, this message translates to:
  /// **'Note added to ride {id}'**
  String noteAddedToRide(String id);

  /// No description provided for @settlementCreated.
  ///
  /// In en, this message translates to:
  /// **'Settlement created'**
  String get settlementCreated;

  /// No description provided for @paymentConfirmed2.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed2;

  /// No description provided for @paymentReceived2.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived2;

  /// No description provided for @cashPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Cash payment confirmed'**
  String get cashPaymentConfirmed;

  /// No description provided for @markedAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as unpaid'**
  String get markedAsUnpaid;

  /// No description provided for @paymentDisputedAmountRefundedToRider.
  ///
  /// In en, this message translates to:
  /// **'Payment disputed, amount refunded to rider'**
  String get paymentDisputedAmountRefundedToRider;

  /// No description provided for @ratingMustBeBetween1And5.
  ///
  /// In en, this message translates to:
  /// **'Rating must be between 1 and 5'**
  String get ratingMustBeBetween1And5;

  /// No description provided for @youHaveAlreadyRatedThisRide.
  ///
  /// In en, this message translates to:
  /// **'You have already rated this ride'**
  String get youHaveAlreadyRatedThisRide;

  /// No description provided for @invalidRideOrUser.
  ///
  /// In en, this message translates to:
  /// **'Invalid ride or user'**
  String get invalidRideOrUser;

  /// No description provided for @youWereNotPartOfThisRide.
  ///
  /// In en, this message translates to:
  /// **'You were not part of this ride'**
  String get youWereNotPartOfThisRide;

  /// No description provided for @noDriverToRateOnThisRide.
  ///
  /// In en, this message translates to:
  /// **'No driver to rate on this ride'**
  String get noDriverToRateOnThisRide;

  /// No description provided for @rateeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ratee not found'**
  String get rateeNotFound;

  /// No description provided for @ratingSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted successfully'**
  String get ratingSubmittedSuccessfully;

  /// No description provided for @fileIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'File is empty'**
  String get fileIsEmpty;

  /// No description provided for @missingAuthorizationHeader.
  ///
  /// In en, this message translates to:
  /// **'Missing authorization header'**
  String get missingAuthorizationHeader;

  /// No description provided for @invalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid token'**
  String get invalidToken;

  /// No description provided for @notificationMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'Notification marked as read'**
  String get notificationMarkedAsRead;

  /// No description provided for @allNotificationsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedAsRead;

  /// No description provided for @allNotificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get allNotificationsDeleted;

  /// No description provided for @messageContentCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Message content cannot be empty'**
  String get messageContentCannotBeEmpty;

  /// No description provided for @messageIsTooLongMax10000Characters.
  ///
  /// In en, this message translates to:
  /// **'Message is too long (max 10000 characters)'**
  String get messageIsTooLongMax10000Characters;

  /// No description provided for @senderOrReceiverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Sender or receiver not found'**
  String get senderOrReceiverNotFound;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @newMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'New message from {username}'**
  String newMessageFrom(String username);

  /// No description provided for @codeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeIsRequired;

  /// No description provided for @eventtypeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'eventType is required'**
  String get eventtypeIsRequired;

  /// No description provided for @youAlreadyHaveAnActiveRide.
  ///
  /// In en, this message translates to:
  /// **'You already have an active ride'**
  String get youAlreadyHaveAnActiveRide;

  /// No description provided for @rideNotFound.
  ///
  /// In en, this message translates to:
  /// **'Ride not found'**
  String get rideNotFound;

  /// No description provided for @rideIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Ride is no longer available'**
  String get rideIsNoLongerAvailable;

  /// No description provided for @rideAlreadyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Ride already accepted'**
  String get rideAlreadyAccepted;

  /// No description provided for @driverNotFound.
  ///
  /// In en, this message translates to:
  /// **'Driver not found'**
  String get driverNotFound;

  /// No description provided for @onlyDriversCanAcceptRides.
  ///
  /// In en, this message translates to:
  /// **'Only drivers can accept rides'**
  String get onlyDriversCanAcceptRides;

  /// No description provided for @cannotTransitionFromTo.
  ///
  /// In en, this message translates to:
  /// **'Cannot transition from {current} to {next}'**
  String cannotTransitionFromTo(String current, String next);

  /// No description provided for @rideNotInRequestedStatus.
  ///
  /// In en, this message translates to:
  /// **'Ride not in REQUESTED status'**
  String get rideNotInRequestedStatus;

  /// No description provided for @onlyTheDriverCanUpdateRideLocation.
  ///
  /// In en, this message translates to:
  /// **'Only the driver can update ride location'**
  String get onlyTheDriverCanUpdateRideLocation;

  /// No description provided for @rideIsNotActive.
  ///
  /// In en, this message translates to:
  /// **'Ride is not active'**
  String get rideIsNotActive;

  /// No description provided for @youHaveAcceptedARideNavigateToPickupLocation.
  ///
  /// In en, this message translates to:
  /// **'You have accepted a ride. Navigate to pickup location.'**
  String get youHaveAcceptedARideNavigateToPickupLocation;

  /// No description provided for @noDriversAvailableYetContinueSearching.
  ///
  /// In en, this message translates to:
  /// **'No drivers available yet. Continue searching?'**
  String get noDriversAvailableYetContinueSearching;

  /// No description provided for @noWomenDriversFoundSwitchToAnotherRideType.
  ///
  /// In en, this message translates to:
  /// **'No women drivers found. Switch to another ride type?'**
  String get noWomenDriversFoundSwitchToAnotherRideType;

  /// No description provided for @yourScheduledRideIsIn30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled ride is in 30 minutes'**
  String get yourScheduledRideIsIn30Minutes;

  /// No description provided for @scheduledRideHasExpired.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride has expired'**
  String get scheduledRideHasExpired;

  /// No description provided for @driverHasCancelledTheScheduledRide.
  ///
  /// In en, this message translates to:
  /// **'Driver has cancelled the scheduled ride'**
  String get driverHasCancelledTheScheduledRide;

  /// No description provided for @xxx1234.
  ///
  /// In en, this message translates to:
  /// **'XXX-1234'**
  String get xxx1234;

  /// No description provided for @rideAcceptedADriverIsOnTheWayToPickYouUp.
  ///
  /// In en, this message translates to:
  /// **'Ride Accepted - A driver is on the way to pick you up'**
  String get rideAcceptedADriverIsOnTheWayToPickYouUp;

  /// No description provided for @rideConfirmedYouHaveAcceptedARideNavigateToPickup.
  ///
  /// In en, this message translates to:
  /// **'Ride Confirmed - You have accepted a ride. Navigate to pickup.'**
  String get rideConfirmedYouHaveAcceptedARideNavigateToPickup;

  /// No description provided for @driverArrivedYourDriverHasArrivedAtThePickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Driver Arrived - Your driver has arrived at the pickup location'**
  String get driverArrivedYourDriverHasArrivedAtThePickupLocation;

  /// No description provided for @rideStartedYourRideHasStartedEnjoyTheTrip.
  ///
  /// In en, this message translates to:
  /// **'Ride Started - Your ride has started. Enjoy the trip!'**
  String get rideStartedYourRideHasStartedEnjoyTheTrip;

  /// No description provided for @rideCompletedYouHaveReachedYourDestination.
  ///
  /// In en, this message translates to:
  /// **'Ride Completed - You have reached your destination'**
  String get rideCompletedYouHaveReachedYourDestination;

  /// No description provided for @rideCancelled3.
  ///
  /// In en, this message translates to:
  /// **'Ride Cancelled - {reason}'**
  String rideCancelled3(String reason);

  /// No description provided for @noWomenDriversFoundNoWomenDriversAvailableSwitchRideType.
  ///
  /// In en, this message translates to:
  /// **'No Women Drivers Found - No women drivers available. Switch ride type?'**
  String get noWomenDriversFoundNoWomenDriversAvailableSwitchRideType;

  /// No description provided for @noDriversFoundNoDriversAvailableYetContinueSearching.
  ///
  /// In en, this message translates to:
  /// **'No Drivers Found - No drivers available yet. Continue searching?'**
  String get noDriversFoundNoDriversAvailableYetContinueSearching;

  /// No description provided for @paymentConfirmedPaymentHasBeenConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed - Payment has been confirmed'**
  String get paymentConfirmedPaymentHasBeenConfirmed;

  /// No description provided for @paymentFinalizedYourPaymentHasBeenFinalized.
  ///
  /// In en, this message translates to:
  /// **'Payment Finalized - Your payment has been finalized'**
  String get paymentFinalizedYourPaymentHasBeenFinalized;

  /// No description provided for @paymentRefundedYourPaymentHasBeenRefunded.
  ///
  /// In en, this message translates to:
  /// **'Payment Refunded - Your payment has been refunded'**
  String get paymentRefundedYourPaymentHasBeenRefunded;

  /// No description provided for @driverAssignedADriverHasAcceptedYourScheduledRide.
  ///
  /// In en, this message translates to:
  /// **'Driver Assigned - A driver has accepted your scheduled ride'**
  String get driverAssignedADriverHasAcceptedYourScheduledRide;

  /// No description provided for @driverArrivedYourDriverHasArrivedForYourScheduledRide.
  ///
  /// In en, this message translates to:
  /// **'Driver Arrived - Your driver has arrived for your scheduled ride'**
  String get driverArrivedYourDriverHasArrivedForYourScheduledRide;

  /// No description provided for @rideStartedYourScheduledRideHasStarted.
  ///
  /// In en, this message translates to:
  /// **'Ride Started - Your scheduled ride has started'**
  String get rideStartedYourScheduledRideHasStarted;

  /// No description provided for @rideReminderYourScheduledRideIsIn30Minutes.
  ///
  /// In en, this message translates to:
  /// **'Ride Reminder - Your scheduled ride is in 30 minutes'**
  String get rideReminderYourScheduledRideIsIn30Minutes;

  /// No description provided for @scheduledRideCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Ride Cancelled - {reason}'**
  String scheduledRideCancelled(String reason);

  /// No description provided for @paymentNotFoundForRide.
  ///
  /// In en, this message translates to:
  /// **'Payment not found for ride: {rideId}'**
  String paymentNotFoundForRide(String rideId);

  /// No description provided for @onlyTheRiderCanConfirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Only the rider can confirm payment'**
  String get onlyTheRiderCanConfirmPayment;

  /// No description provided for @paymentCannotBeConfirmedInStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment cannot be confirmed in status: {status}'**
  String paymentCannotBeConfirmedInStatus(String status);

  /// No description provided for @insufficientWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient wallet balance'**
  String get insufficientWalletBalance;

  /// No description provided for @tripFareForRide.
  ///
  /// In en, this message translates to:
  /// **'Trip fare for ride #{rideId}'**
  String tripFareForRide(String rideId);

  /// No description provided for @onlyTheDriverCanConfirmCashReceipt.
  ///
  /// In en, this message translates to:
  /// **'Only the driver can confirm cash receipt'**
  String get onlyTheDriverCanConfirmCashReceipt;

  /// No description provided for @thisEndpointIsOnlyForCashPayments.
  ///
  /// In en, this message translates to:
  /// **'This endpoint is only for CASH payments'**
  String get thisEndpointIsOnlyForCashPayments;

  /// No description provided for @onlyTheDriverCanReportCashUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Only the driver can report cash unpaid'**
  String get onlyTheDriverCanReportCashUnpaid;

  /// No description provided for @customerDidNotPayCash.
  ///
  /// In en, this message translates to:
  /// **'Customer did not pay cash'**
  String get customerDidNotPayCash;

  /// No description provided for @onlyTheDriverCanConfirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Only the driver can confirm receipt'**
  String get onlyTheDriverCanConfirmReceipt;

  /// No description provided for @onlyTheDriverCanDisputePayment.
  ///
  /// In en, this message translates to:
  /// **'Only the driver can dispute payment'**
  String get onlyTheDriverCanDisputePayment;

  /// No description provided for @refundForRide.
  ///
  /// In en, this message translates to:
  /// **'Refund for ride #{rideId} - {reason}'**
  String refundForRide(String rideId, String reason);

  /// No description provided for @onlyTheRiderOrDriverCanViewPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Only the rider or driver can view payment status'**
  String get onlyTheRiderOrDriverCanViewPaymentStatus;

  /// No description provided for @scheduledTimeMustBeInTheFuture.
  ///
  /// In en, this message translates to:
  /// **'Scheduled time must be in the future'**
  String get scheduledTimeMustBeInTheFuture;

  /// No description provided for @scheduledRideNotFound.
  ///
  /// In en, this message translates to:
  /// **'Scheduled ride not found'**
  String get scheduledRideNotFound;

  /// No description provided for @canOnlyCancelScheduledOrAssignedScheduledRides.
  ///
  /// In en, this message translates to:
  /// **'Can only cancel scheduled or assigned scheduled rides'**
  String get canOnlyCancelScheduledOrAssignedScheduledRides;

  /// No description provided for @cancelledByUser.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by user'**
  String get cancelledByUser;

  /// No description provided for @cancelledByRider.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by rider'**
  String get cancelledByRider;

  /// No description provided for @canOnlyCompleteStartedScheduledRides.
  ///
  /// In en, this message translates to:
  /// **'Can only complete started scheduled rides'**
  String get canOnlyCompleteStartedScheduledRides;

  /// No description provided for @latitudeAndLongitudeAreRequired.
  ///
  /// In en, this message translates to:
  /// **'Latitude and longitude are required'**
  String get latitudeAndLongitudeAreRequired;

  /// No description provided for @thisRideIsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This ride is no longer available'**
  String get thisRideIsNoLongerAvailable;

  /// No description provided for @thisRideIsNotAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'This ride is not assigned to you'**
  String get thisRideIsNotAssignedToYou;

  /// No description provided for @canOnlyUnassignARideThatIsInAssignedStatus.
  ///
  /// In en, this message translates to:
  /// **'Can only unassign a ride that is in ASSIGNED status'**
  String get canOnlyUnassignARideThatIsInAssignedStatus;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @rideMustBeAssignedBeforeArriving.
  ///
  /// In en, this message translates to:
  /// **'Ride must be assigned before arriving'**
  String get rideMustBeAssignedBeforeArriving;

  /// No description provided for @onlyTheAssignedDriverCanVerifyThePickupCode.
  ///
  /// In en, this message translates to:
  /// **'Only the assigned driver can verify the pickup code'**
  String get onlyTheAssignedDriverCanVerifyThePickupCode;

  /// No description provided for @pickupCodeCanOnlyBeVerifiedAfterTheDriverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Pickup code can only be verified after the driver has arrived'**
  String get pickupCodeCanOnlyBeVerifiedAfterTheDriverHasArrived;

  /// No description provided for @driverMustArriveBeforeStartingTheRide.
  ///
  /// In en, this message translates to:
  /// **'Driver must arrive before starting the ride'**
  String get driverMustArriveBeforeStartingTheRide;

  /// No description provided for @pickupCodeMustBeVerifiedBeforeStartingTheRide.
  ///
  /// In en, this message translates to:
  /// **'Pickup code must be verified before starting the ride'**
  String get pickupCodeMustBeVerifiedBeforeStartingTheRide;

  /// No description provided for @pickupCodeVerificationHasExpiredPleaseVerifyAgain.
  ///
  /// In en, this message translates to:
  /// **'Pickup code verification has expired. Please verify again.'**
  String get pickupCodeVerificationHasExpiredPleaseVerifyAgain;

  /// No description provided for @paymentStartedButNeverCompleted.
  ///
  /// In en, this message translates to:
  /// **'Payment started but never completed'**
  String get paymentStartedButNeverCompleted;

  /// No description provided for @rideCompletedButPaymentStillPending.
  ///
  /// In en, this message translates to:
  /// **'Ride completed but payment still pending'**
  String get rideCompletedButPaymentStillPending;

  /// No description provided for @eventOccurredTimes.
  ///
  /// In en, this message translates to:
  /// **'Event \'{name}\' occurred {count} times'**
  String eventOccurredTimes(String name, String count);

  /// No description provided for @retryLoopDetectedRetries.
  ///
  /// In en, this message translates to:
  /// **'Retry loop detected: {count} retries'**
  String retryLoopDetectedRetries(String count);

  /// No description provided for @apiTimeoutOccurred.
  ///
  /// In en, this message translates to:
  /// **'API timeout occurred'**
  String get apiTimeoutOccurred;

  /// No description provided for @serverException.
  ///
  /// In en, this message translates to:
  /// **'Server exception: {message}'**
  String serverException(String message);

  /// No description provided for @websocketDisconnectedTimes.
  ///
  /// In en, this message translates to:
  /// **'WebSocket disconnected {count} times'**
  String websocketDisconnectedTimes(String count);

  /// No description provided for @driverAcceptedButPassengerMayNotHaveReceivedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Driver accepted but passenger may not have received update'**
  String get driverAcceptedButPassengerMayNotHaveReceivedUpdate;

  /// No description provided for @tripRemainedInForS.
  ///
  /// In en, this message translates to:
  /// **'Trip remained in \'{state}\' for {seconds}s'**
  String tripRemainedInForS(String state, String seconds);

  /// No description provided for @gpsUpdatingForS.
  ///
  /// In en, this message translates to:
  /// **'GPS updating for {seconds}s'**
  String gpsUpdatingForS(String seconds);

  /// No description provided for @coordinatesCannotBeNull.
  ///
  /// In en, this message translates to:
  /// **'Coordinates cannot be null'**
  String get coordinatesCannotBeNull;

  /// No description provided for @geocodingFailed.
  ///
  /// In en, this message translates to:
  /// **'Geocoding failed: {status}'**
  String geocodingFailed(String status);

  /// No description provided for @usingEstimatedRouteActualRouteMayDiffer.
  ///
  /// In en, this message translates to:
  /// **'Using estimated route - actual route may differ'**
  String get usingEstimatedRouteActualRouteMayDiffer;

  /// No description provided for @noDriversAvailableAutoCancelled.
  ///
  /// In en, this message translates to:
  /// **'No drivers available - auto cancelled'**
  String get noDriversAvailableAutoCancelled;

  /// No description provided for @autocancelledDriverNeverMovedToPickupFor2Hours.
  ///
  /// In en, this message translates to:
  /// **'Auto-cancelled - driver never moved to pickup for 2+ hours'**
  String get autocancelledDriverNeverMovedToPickupFor2Hours;

  /// No description provided for @autocancelledDriverNeverStartedRideFor2Hours.
  ///
  /// In en, this message translates to:
  /// **'Auto-cancelled - driver never started ride for 2+ hours'**
  String get autocancelledDriverNeverStartedRideFor2Hours;

  /// No description provided for @noDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drivers available'**
  String get noDriversAvailable;

  /// No description provided for @urlCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'URL cannot be empty'**
  String get urlCannotBeEmpty;

  /// No description provided for @serverUrlUpdated.
  ///
  /// In en, this message translates to:
  /// **'Server URL updated'**
  String get serverUrlUpdated;

  /// No description provided for @rideUpdatesAndOffers.
  ///
  /// In en, this message translates to:
  /// **'Receive ride updates and offers'**
  String get rideUpdatesAndOffers;

  /// No description provided for @receiveTextMessagesForRides.
  ///
  /// In en, this message translates to:
  /// **'Receive text messages for rides'**
  String get receiveTextMessagesForRides;

  /// No description provided for @receivePromotionalEmails.
  ///
  /// In en, this message translates to:
  /// **'Receive promotional emails'**
  String get receivePromotionalEmails;

  /// No description provided for @displayCurrency.
  ///
  /// In en, this message translates to:
  /// **'Display Currency'**
  String get displayCurrency;

  /// No description provided for @saveServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Save Server URL'**
  String get saveServerUrl;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @premiumRideSharing.
  ///
  /// In en, this message translates to:
  /// **'Premium ride sharing'**
  String get premiumRideSharing;

  /// No description provided for @grantLocationAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Location Access'**
  String get grantLocationAccess;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin note'**
  String get adminNote;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get approvedBy;

  /// No description provided for @approveDocument.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveDocument;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @documentReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Review'**
  String get documentReviewTitle;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresOn;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get issueDate;

  /// No description provided for @documentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get documentNumber;

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed by'**
  String get reviewedBy;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded'**
  String get noDocuments;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteHint;

  /// No description provided for @rejectDocument.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectDocument;

  /// No description provided for @requestReupload.
  ///
  /// In en, this message translates to:
  /// **'Request re-upload'**
  String get requestReupload;

  /// No description provided for @reviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewedAt;

  /// No description provided for @tapToViewDocument.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get tapToViewDocument;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadedOn;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @totalDrivers.
  ///
  /// In en, this message translates to:
  /// **'Total Drivers'**
  String get totalDrivers;

  /// No description provided for @pendingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Pending Documents'**
  String get pendingDocuments;

  /// No description provided for @noPendingDocuments.
  ///
  /// In en, this message translates to:
  /// **'No pending documents'**
  String get noPendingDocuments;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @documentExpiry.
  ///
  /// In en, this message translates to:
  /// **'Document Expiry'**
  String get documentExpiry;

  /// No description provided for @expiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredDocuments;

  /// No description provided for @expiringWithin7Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring within 7 days'**
  String get expiringWithin7Days;

  /// No description provided for @expiringWithin30Days.
  ///
  /// In en, this message translates to:
  /// **'Expiring within 30 days'**
  String get expiringWithin30Days;

  /// No description provided for @noExpiringDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents in this window'**
  String get noExpiringDocuments;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
