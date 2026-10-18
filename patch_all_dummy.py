import re

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'r') as f:
    content = f.read()

# adminAnalyticsProvider
content = re.sub(
    r"catch \(e\) \{\s*// Return fallback sample analytics if endpoint isn't seeded yet\s*return \{.*?\};\s*\}",
    "catch (e) {\n    return {};\n  }",
    content,
    flags=re.DOTALL
)

# pendingVenuesProvider (might already be fixed, but let's be safe)
content = re.sub(
    r"catch \(e\) \{\s*return \[\s*\{.*?'id': 101.*?\].*?\};\s*\}",
    "catch (e) {\n    return [];\n  }",
    content,
    flags=re.DOTALL
)

# globalConfigProvider
content = re.sub(
    r"catch \(e\) \{\s*return \{.*?'commission_percentage': 10\.0,.*?\};\s*\}",
    "catch (e) {\n    return {};\n  }",
    content,
    flags=re.DOTALL
)

# promotionalOffersProvider
content = re.sub(
    r"catch \(e\) \{\s*return \[\s*\{.*?'id': 1, 'code': 'GOATH50'.*?\].*?\};\s*\}",
    "catch (e) {\n    return [];\n  }",
    content,
    flags=re.DOTALL
)

# partnerVenuesProvider
content = re.sub(
    r"catch \(e\) \{\s*return \[\s*\{.*?'id': 1,.*?'Greenfield Sports Complex & AstroTurf'.*?\].*?\};\s*\}",
    "catch (e) {\n    return [];\n  }",
    content,
    flags=re.DOTALL
)

# partnerBookingsProvider
content = re.sub(
    r"catch \(e\) \{\s*return \[\s*\{.*?'id': 201,.*?'Rohan Sharma'.*?\].*?\};\s*\}",
    "catch (e) {\n    return [];\n  }",
    content,
    flags=re.DOTALL
)

# partnerAnalyticsProvider
content = re.sub(
    r"catch \(e\) \{\s*return \{.*?'total_revenue': 78400,.*?\};\s*\}",
    "catch (e) {\n    return {};\n  }",
    content,
    flags=re.DOTALL
)

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'w') as f:
    f.write(content)
