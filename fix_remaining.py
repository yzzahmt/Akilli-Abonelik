import re

def fix_home():
    with open('lib/screens/home_screen.dart', 'r') as f:
        content = f.read()
    # Remove declarations
    content = re.sub(r"\s*double _swipeStartX = 0;\n", "\n", content)
    content = re.sub(r"\s*double _swipeStartY = 0;\n", "\n", content)
    # Remove assignments
    content = re.sub(r"\s*_swipeStartX = details.globalPosition.dx;\n", "\n", content)
    content = re.sub(r"\s*_swipeStartY = details.globalPosition.dy;\n", "\n", content)
    with open('lib/screens/home_screen.dart', 'w') as f:
        f.write(content)

def fix_insights():
    with open('lib/screens/insights_screen.dart', 'r') as f:
        content = f.read()
    content = content.replace("import '../services/currency_service.dart';\n", "")
    with open('lib/screens/insights_screen.dart', 'w') as f:
        f.write(content)

def fix_investment():
    with open('lib/screens/investment_screen.dart', 'r') as f:
        content = f.read()
    content = re.sub(r"\s*String\? _selectedSymbol;\n", "\n", content)
    with open('lib/screens/investment_screen.dart', 'w') as f:
        f.write(content)

def fix_spending():
    with open('lib/screens/spending_chart_screen.dart', 'r') as f:
        content = f.read()
    content = re.sub(r"\s*int year = int\.parse.*?;\n", "\n", content)
    content = re.sub(r"\s*int adjustedMonth = .*?;\n", "\n", content)
    with open('lib/screens/spending_chart_screen.dart', 'w') as f:
        f.write(content)

fix_home()
fix_insights()
fix_investment()
fix_spending()
