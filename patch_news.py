import re

# 1. Update flutter provider
with open('goathlete_workspace/apps/customer_app/lib/providers/sports_news_provider.dart', 'r') as f:
    content = f.read()

content = content.replace(
    'final sportsNewsProvider = FutureProvider<List<dynamic>>((ref) async {',
    'final sportsNewsProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {'
)
content = content.replace(
    "Uri.parse('http://127.0.0.1:8000/api/dashboard/sports-news/')",
    "Uri.parse('http://127.0.0.1:8000/api/dashboard/sports-news/?q=$query')"
)
with open('goathlete_workspace/apps/customer_app/lib/providers/sports_news_provider.dart', 'w') as f:
    f.write(content)

# 2. Update home screen to pass user's sport
with open('goathlete_workspace/apps/customer_app/lib/screens/dashboard/home_screen.dart', 'r') as f:
    home_content = f.read()

# We need to get the user's primary sport from authProvider.
# Let's replace _buildSportsNewsAds signature.
home_content = home_content.replace(
    'Widget _buildSportsNewsAds(BuildContext context, WidgetRef ref) {',
    'Widget _buildSportsNewsAds(BuildContext context, WidgetRef ref, String query) {'
)
home_content = home_content.replace(
    'ref.watch(sportsNewsProvider)',
    'ref.watch(sportsNewsProvider(query))'
)
# And replace the call
home_content = home_content.replace(
    '_buildSportsNewsAds(context, ref),',
    "_buildSportsNewsAds(context, ref, userProfile?['primary_sport'] ?? 'sports'),"
)
with open('goathlete_workspace/apps/customer_app/lib/screens/dashboard/home_screen.dart', 'w') as f:
    f.write(home_content)

# 3. Update Django backend
with open('goathlete_backend/dashboard/views.py', 'r') as f:
    py_content = f.read()

import re
py_content = re.sub(
    r'url = "https://news.google.com/rss/search\?q=sports&hl=en-IN&gl=IN&ceid=IN:en"',
    r'''query = request.GET.get('q', 'sports')
        url = f"https://news.google.com/rss/search?q={query}&hl=en-IN&gl=IN&ceid=IN:en"''',
    py_content
)
with open('goathlete_backend/dashboard/views.py', 'w') as f:
    f.write(py_content)
