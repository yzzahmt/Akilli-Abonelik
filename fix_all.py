import re
import os

def fix_export_utils():
    filepath = 'lib/utils/export_utils.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We currently have:
    # await SharePlus.instance.share(
    #   [XFile(path, mimeType: 'text/csv')],
    #   text: 'SubsTrack Aboneliklerim',
    # );
    content = re.sub(
        r'SharePlus\.instance\.share\(\s*\[(.*?)\]\s*,\s*text:\s*(.*?)\s*\);',
        r'SharePlus.instance.share(ShareParams(files: [\1], text: \2));',
        content,
        flags=re.DOTALL
    )
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_home_screen():
    filepath = 'lib/screens/home_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove swipe fields
    content = re.sub(r'\s*double _swipeStartX = 0;\n', '\n', content)
    content = re.sub(r'\s*double _swipeStartY = 0;\n', '\n', content)

    # Wrap if in braces
    content = re.sub(r"(if \([^{]*\)|\n\s+return true;\n)", lambda m: m.group(0) if 'return true;' not in m.group(0) else " { return true; }\n", content)
    content = content.replace("if (selectedCategory == 'Tümü' || selectedCategory == 'All')\n        return true;", "if (selectedCategory == 'Tümü' || selectedCategory == 'All') { return true; }")
    
    # context.mounted check
    # await DBService.instance.toggleFavorite(sub.id!, true);
    # ScaffoldMessenger.of(context).showSnackBar(
    content = content.replace('await DBService.instance\n                                .toggleFavorite(sub.id!, true);', 'await DBService.instance\n                                .toggleFavorite(sub.id!, true);\n                            if (!context.mounted) return;')
    content = content.replace('await DBService.instance.toggleFavorite(sub.id!, true);\n                            ScaffoldMessenger', 'await DBService.instance.toggleFavorite(sub.id!, true);\n                            if (!context.mounted) return;\n                            ScaffoldMessenger')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_add_subscription():
    filepath = 'lib/screens/add_subscription_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove duplicate imports inside function
    content = re.sub(r"^\s*import 'dart:convert';\n", "", content, flags=re.MULTILINE)
    content = re.sub(r"^\s*import 'package:http/http\.dart' as http;\n", "", content, flags=re.MULTILINE)

    # Add to top
    if "import 'package:http/http.dart'" not in content:
        content = "import 'dart:convert';\nimport 'package:http/http.dart' as http;\n" + content
    
    # 2. activeColor -> activeThumbColor
    content = content.replace('activeColor: AppColors.accentPurple', 'activeThumbColor: AppColors.accentPurple')
    
    # 3. Curly braces for if-else
    content = re.sub(r"if \(_billingCycle == 'Haftalık'\) monthly = price \* 52 / 12;", "if (_billingCycle == 'Haftalık') { monthly = price * 52 / 12; }", content)
    content = re.sub(r"else if \(_billingCycle == '2 Haftada Bir'\) monthly = price \* 26 / 12;", "else if (_billingCycle == '2 Haftada Bir') { monthly = price * 26 / 12; }", content)
    content = re.sub(r"else if \(_billingCycle == '3 Aylık'\) monthly = price / 3;", "else if (_billingCycle == '3 Aylık') { monthly = price / 3; }", content)
    content = re.sub(r"else if \(_billingCycle == '6 Aylık'\) monthly = price / 6;", "else if (_billingCycle == '6 Aylık') { monthly = price / 6; }", content)
    content = re.sub(r"else if \(_billingCycle == 'Yıllık'\) monthly = price / 12;", "else if (_billingCycle == 'Yıllık') { monthly = price / 12; }", content)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

def fix_insights():
    filepath = 'lib/screens/insights_screen.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove _currentUsdRate
    content = re.sub(r"\s*double _currentUsdRate = 32\.0;\n", "\n", content)
    # Remove _loadRate call
    content = re.sub(r"\s*_loadRate\(\);\n", "\n", content)
    # Remove _loadRate definition
    content = re.sub(r"\s*Future<void> _loadRate\(\) async \{.*?\n\s*\}\n", "\n", content, flags=re.DOTALL)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_export_utils()
fix_home_screen()
fix_add_subscription()
fix_insights()
