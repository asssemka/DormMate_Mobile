import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('kk'),
    Locale('ru')
  ];

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @edit_application.
  ///
  /// In en, this message translates to:
  /// **'Edit Application'**
  String get edit_application;

  /// No description provided for @ent_result.
  ///
  /// In en, this message translates to:
  /// **'ENT Result'**
  String get ent_result;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// No description provided for @password_change.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get password_change;

  /// No description provided for @psychological_test.
  ///
  /// In en, this message translates to:
  /// **'Psychological Test'**
  String get psychological_test;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Application Status:'**
  String get status;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @useful_info.
  ///
  /// In en, this message translates to:
  /// **'Useful Info'**
  String get useful_info;

  /// No description provided for @dorm_price_10_months.
  ///
  /// In en, this message translates to:
  /// **'Price for 10 months'**
  String get dorm_price_10_months;

  /// No description provided for @parent_phone.
  ///
  /// In en, this message translates to:
  /// **'Parent\'s phone'**
  String get parent_phone;

  /// No description provided for @delete_avatar.
  ///
  /// In en, this message translates to:
  /// **'Delete avatar'**
  String get delete_avatar;

  /// No description provided for @dorm_canteen.
  ///
  /// In en, this message translates to:
  /// **'Canteen'**
  String get dorm_canteen;

  /// No description provided for @dorm_laundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get dorm_laundry;

  /// No description provided for @dorm_bed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get dorm_bed;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @not_found.
  ///
  /// In en, this message translates to:
  /// **'Questions not found'**
  String get not_found;

  /// No description provided for @submit_message.
  ///
  /// In en, this message translates to:
  /// **'Enter message'**
  String get submit_message;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get exit;

  /// No description provided for @student_id.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get student_id;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @application_status.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get application_status;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @logout_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logout_confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @apply_now.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get apply_now;

  /// No description provided for @no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get no_notifications;

  /// No description provided for @dormitories.
  ///
  /// In en, this message translates to:
  /// **'Our Dormitories'**
  String get dormitories;

  /// No description provided for @application_approved.
  ///
  /// In en, this message translates to:
  /// **'Your application is approved. Please pay and attach a screenshot here.'**
  String get application_approved;

  /// No description provided for @attach_payment_screenshot.
  ///
  /// In en, this message translates to:
  /// **'Attach Payment Screenshot'**
  String get attach_payment_screenshot;

  /// No description provided for @upload_success.
  ///
  /// In en, this message translates to:
  /// **'Screenshot uploaded successfully.'**
  String get upload_success;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faq;

  /// No description provided for @useful_info_students.
  ///
  /// In en, this message translates to:
  /// **'Useful for students'**
  String get useful_info_students;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @status_no_application.
  ///
  /// In en, this message translates to:
  /// **'You have not applied yet.'**
  String get status_no_application;

  /// No description provided for @go_to_application.
  ///
  /// In en, this message translates to:
  /// **'Go to Application'**
  String get go_to_application;

  /// No description provided for @passwords.
  ///
  /// In en, this message translates to:
  /// **'Passwords'**
  String get passwords;

  /// No description provided for @devices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get devices;

  /// No description provided for @my_address.
  ///
  /// In en, this message translates to:
  /// **'My Address'**
  String get my_address;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @field_required.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get field_required;

  /// No description provided for @passwords_dont_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwords_dont_match;

  /// No description provided for @password_changed.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get password_changed;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get try_again;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get choose_from_gallery;

  /// No description provided for @mark_as_read.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get mark_as_read;

  /// No description provided for @open_chat.
  ///
  /// In en, this message translates to:
  /// **'Open chat'**
  String get open_chat;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @upload_ent_certificate.
  ///
  /// In en, this message translates to:
  /// **'Please upload the Unified National Testing certificate in the \'Upload Documents\' section. Without this certificate your result will not be counted.'**
  String get upload_ent_certificate;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @file_attached.
  ///
  /// In en, this message translates to:
  /// **'File attached'**
  String get file_attached;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get markAsRead;

  /// No description provided for @dorm_info.
  ///
  /// In en, this message translates to:
  /// **'Dormitory Information'**
  String get dorm_info;

  /// No description provided for @name_not_found.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get name_not_found;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @description_not_found.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get description_not_found;

  /// No description provided for @total_places.
  ///
  /// In en, this message translates to:
  /// **'Number of places'**
  String get total_places;

  /// No description provided for @address_not_specified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get address_not_specified;

  /// No description provided for @location_map.
  ///
  /// In en, this message translates to:
  /// **'Location map'**
  String get location_map;

  /// No description provided for @open_map.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get open_map;

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'ChatBot'**
  String get chatbot;

  /// No description provided for @send_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter message'**
  String get send_message_hint;

  /// No description provided for @end_chat.
  ///
  /// In en, this message translates to:
  /// **'End Chat'**
  String get end_chat;

  /// No description provided for @question_not_found.
  ///
  /// In en, this message translates to:
  /// **'Questions not found'**
  String get question_not_found;

  /// No description provided for @question_progress.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String question_progress(Object current, Object total);

  /// No description provided for @submit_test.
  ///
  /// In en, this message translates to:
  /// **'Submit Test'**
  String get submit_test;

  /// No description provided for @please_answer_all.
  ///
  /// In en, this message translates to:
  /// **'Please answer all questions'**
  String get please_answer_all;

  /// No description provided for @test_success.
  ///
  /// In en, this message translates to:
  /// **'Test submitted successfully!'**
  String get test_success;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get main;

  /// No description provided for @confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirm_logout;

  /// No description provided for @our_dormitories.
  ///
  /// In en, this message translates to:
  /// **'Our dormitories'**
  String get our_dormitories;

  /// No description provided for @faq_q1.
  ///
  /// In en, this message translates to:
  /// **'What is included in the cost of accommodation?'**
  String get faq_q1;

  /// No description provided for @faq_a1.
  ///
  /// In en, this message translates to:
  /// **'Accommodation, utilities, use of kitchen and shower.'**
  String get faq_a1;

  /// No description provided for @faq_q2.
  ///
  /// In en, this message translates to:
  /// **'How long can you stay in the Students\' House?'**
  String get faq_q2;

  /// No description provided for @faq_a2.
  ///
  /// In en, this message translates to:
  /// **'For the entire period of study, subject to the rules.'**
  String get faq_a2;

  /// No description provided for @faq_q3.
  ///
  /// In en, this message translates to:
  /// **'Who can get a dormitory place?'**
  String get faq_q3;

  /// No description provided for @faq_a3.
  ///
  /// In en, this message translates to:
  /// **'Students who have applied and passed the selection.'**
  String get faq_a3;

  /// No description provided for @faq_q4.
  ///
  /// In en, this message translates to:
  /// **'How is the settlement process?'**
  String get faq_q4;

  /// No description provided for @faq_a4.
  ///
  /// In en, this message translates to:
  /// **'An order is issued and a rental agreement is concluded. Registration is done through the dean\'s office. Unauthorized settlement is prohibited.'**
  String get faq_a4;

  /// No description provided for @faq_q5.
  ///
  /// In en, this message translates to:
  /// **'How can I pay for accommodation?'**
  String get faq_q5;

  /// No description provided for @faq_a5.
  ///
  /// In en, this message translates to:
  /// **'Payment is made through the university payment system or bank.'**
  String get faq_a5;

  /// No description provided for @faq_q6.
  ///
  /// In en, this message translates to:
  /// **'What rules must I follow?'**
  String get faq_q6;

  /// No description provided for @faq_a6.
  ///
  /// In en, this message translates to:
  /// **'Observe silence, cleanliness, respect for neighbors and property.'**
  String get faq_a6;

  /// No description provided for @faq_q7.
  ///
  /// In en, this message translates to:
  /// **'What happens if the rules are violated?'**
  String get faq_q7;

  /// No description provided for @faq_a7.
  ///
  /// In en, this message translates to:
  /// **'Warning, fine, or eviction depending on the severity.'**
  String get faq_a7;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
