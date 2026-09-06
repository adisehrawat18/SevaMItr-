import 'package:flutter/widgets.dart';
import 'location_language_service.dart';

/// Makes the selected application language available to every route and dialog.
///
/// Widgets that use [BuildContext.tr] automatically rebuild after a language
/// change because they depend on this [InheritedNotifier].
class AppLanguageScope extends InheritedNotifier<LocationLanguageService> {
  const AppLanguageScope({
    super.key,
    required LocationLanguageService languageService,
    required super.child,
  }) : super(notifier: languageService);

  static LocationLanguageService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    return scope?.notifier ?? LocationLanguageService();
  }
}

extension AppLocalizationContext on BuildContext {
  String tr(String key, {Map<String, String> values = const {}}) {
    var text = AppLanguageScope.of(this).tr(key);
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value);
    }
    return text;
  }
}
