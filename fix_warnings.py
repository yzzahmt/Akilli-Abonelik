import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Fix withOpacity
    # Using regex to find .withOpacity(val) and replace with .withValues(alpha: val)
    # Be careful not to replace things inside strings or multiline. Simple regex should be fine.
    content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
    
    # 2. Fix Share.shareXFiles
    if 'export_utils.dart' in filepath:
        content = content.replace('Share.shareXFiles', 'SharePlus.instance.share')
        # Also fix the import if they used Share instead of SharePlus somewhere
    
    # 3. Fix spending_chart_screen.dart
    if 'spending_chart_screen.dart' in filepath:
        # Remove unused import
        content = re.sub(r"import '../providers/settings_provider.dart';\n", "", content)
        # Remove unused local variables
        content = re.sub(r"\s*int year = .*?;\n", "\n", content)
        content = re.sub(r"\s*int adjustedMonth = .*?;\n", "\n", content)
        
    # 4. Fix investment_screen.dart
    if 'investment_screen.dart' in filepath:
        # Remove unused _selectedSymbol field
        content = re.sub(r"\s*String\? _selectedSymbol;\n", "\n", content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

