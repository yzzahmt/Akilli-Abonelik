import re

def fix_sub():
    with open('lib/models/subscription.dart', 'r') as f:
        content = f.read()
    
    # Fix constructor id
    content = content.replace('\n    id,\n    required this.name,', '\n    this.id,\n    required this.name,')
    # Fix copyWith id
    content = content.replace('id: id ?? id,', 'id: id ?? this.id,')
    # Fix copyWith createdAt
    content = content.replace('createdAt: createdAt ?? createdAt,', 'createdAt: createdAt ?? this.createdAt,')
    # Remove unnecessary this.
    content = content.replace('this._billingCycle', '_billingCycle')
    content = content.replace('this._currency', '_currency')

    with open('lib/models/subscription.dart', 'w') as f:
        f.write(content)

def fix_home():
    with open('lib/screens/home_screen.dart', 'r') as f:
        content = f.read()
    
    # The broken where block:
    #     final filteredSubs = state.subscriptions.where((sub) {
    #        { return true; }
    # ;
    bad_code = """    final filteredSubs = state.subscriptions.where((sub) {
       { return true; }
;"""
    good_code = """    final filteredSubs = state.subscriptions.where((sub) {
      if (selectedCategory == 'Tümü' || selectedCategory == 'All') return true;
      return sub.category == selectedCategory;
    }).toList();"""
    content = content.replace(bad_code, good_code)

    # Bring back the swipe variables inside _HomeTabBodyState
    # class _HomeTabBodyState extends ConsumerState<_HomeTabBody> {
    # 
    #   String _formatCurrency(double value, String lang) {
    swipe_vars = """class _HomeTabBodyState extends ConsumerState<_HomeTabBody> {
  double _swipeStartX = 0;
  double _swipeStartY = 0;
"""
    content = content.replace("class _HomeTabBodyState extends ConsumerState<_HomeTabBody> {\n\n  String _formatCurrency", swipe_vars + "\n  String _formatCurrency")

    with open('lib/screens/home_screen.dart', 'w') as f:
        f.write(content)

def fix_add_sub():
    with open('lib/screens/add_subscription_screen.dart', 'r') as f:
        content = f.read()
    content = content.replace("import 'package:fl_chart/fl_chart.dart';\n", "")
    with open('lib/screens/add_subscription_screen.dart', 'w') as f:
        f.write(content)

fix_sub()
fix_home()
fix_add_sub()
