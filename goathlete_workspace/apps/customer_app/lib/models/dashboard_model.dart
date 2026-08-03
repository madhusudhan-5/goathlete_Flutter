class HighlightBanner {
  final int id;
  final String title;
  final String imageUrl;
  final String discountText;
  final String? redirectUrl;

  HighlightBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.discountText,
    this.redirectUrl,
  });

  factory HighlightBanner.fromJson(Map<String, dynamic> json) {
    return HighlightBanner(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      discountText: json['discount_text'],
      redirectUrl: json['redirect_url'],
    );
  }
}

class SportCategory {
  final int id;
  final String name;
  final String iconName;

  SportCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  factory SportCategory.fromJson(Map<String, dynamic> json) {
    return SportCategory(
      id: json['id'],
      name: json['name'],
      iconName: json['icon_name'],
    );
  }
}

class QuickAction {
  final int id;
  final String title;
  final String iconName;
  final String route;

  QuickAction({
    required this.id,
    required this.title,
    required this.iconName,
    required this.route,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'],
      title: json['title'],
      iconName: json['icon_name'],
      route: json['route'],
    );
  }
}

class DashboardConfig {
  final List<HighlightBanner> banners;
  final List<SportCategory> sports;
  final List<QuickAction> quickActions;

  DashboardConfig({
    required this.banners,
    required this.sports,
    required this.quickActions,
  });

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    return DashboardConfig(
      banners: (json['banners'] as List)
          .map((e) => HighlightBanner.fromJson(e))
          .toList(),
      sports: (json['sports'] as List)
          .map((e) => SportCategory.fromJson(e))
          .toList(),
      quickActions: (json['quick_actions'] as List)
          .map((e) => QuickAction.fromJson(e))
          .toList(),
    );
  }
}
