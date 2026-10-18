with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'r') as f:
    content = f.read()

import re

# We will just replace everything between `return [` and `];` or `return {` and `};` inside catch blocks.
def replace_catch_blocks(text):
    # Find all catch blocks
    pattern = re.compile(r'catch\s*\([^)]*\)\s*\{([\s\S]*?)\}')
    
    def replacer(match):
        inner = match.group(1)
        if 'return [' in inner:
            return 'catch (e) {\n    return [];\n  }'
        elif 'return {' in inner:
            return 'catch (e) {\n    return {};\n  }'
        else:
            return match.group(0)

    return pattern.sub(replacer, text)

new_content = replace_catch_blocks(content)
# Restore the optimistic fallbacks for update/approve/reject because they return booleans!
# Oh wait, my replacer ONLY touches blocks that have `return [` or `return {`.
# So booleans will be untouched! Let's check!

with open('goathlete_workspace/apps/admin_console/lib/providers/admin_provider.dart', 'w') as f:
    f.write(new_content)
