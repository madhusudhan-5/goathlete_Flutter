with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'r') as f:
    content = f.read()

content = content.replace("dio.get('pre-register-venues/')", "dio.get('venues/pre-register-venues/')")
content = content.replace("dio.post('pre-register-venues/", "dio.post('venues/pre-register-venues/")
content = content.replace("dio.get('executives/')", "dio.get('users/executives/')")

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'w') as f:
    f.write(content)
