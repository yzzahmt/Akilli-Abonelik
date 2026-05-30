import re

with open("lib/screens/settings_screen.dart", "r") as f:
    content = f.read()

broken_block = """                      leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.expensiveRed),
                      title: Text(
                        AppTranslations.translate(lang, 'clear_all_data'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      if (_showSplashAnimation)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: AppColors.background,
              child: Center(
                child: const Icon(Icons.settings_rounded, color: AppColors.accentPurple, size: 60)
                    .animate()
                    .rotate(begin: 0, end: 2.0, duration: 1000.ms, curve: Curves.easeInOutCubic)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(30, 30), duration: 1000.ms, curve: Curves.easeInQuint)
                    .fade(end: 0, duration: 300.ms, delay: 700.ms),
              ),
            ).animate().fade(end: 0, duration: 400.ms, delay: 800.ms),
          ),
        ),
      ],
    ),
  );
}
AlertDialog("""

fixed_block = """                      leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.expensiveRed),
                      title: Text(
                        AppTranslations.translate(lang, 'clear_all_data'),
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog("""

if broken_block in content:
    content = content.replace(broken_block, fixed_block)
    
    # Now find the correct place to insert the Stack end and animation
    # The end of the build method is right before `Widget _buildSectionTitle` or similar, but the end of ListView is `const SizedBox(height: 40),`
    # Let's find `const SizedBox(height: 40),` and the `], ), ), ), ); }`
    
    # We will just find:
    end_pattern = """              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }"""
    
    stack_replacement = """              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      if (_showSplashAnimation)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: AppColors.background,
              child: Center(
                child: const Icon(Icons.settings_rounded, color: AppColors.accentPurple, size: 60)
                    .animate()
                    .rotate(begin: 0, end: 2.0, duration: 1000.ms, curve: Curves.easeInOutCubic)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(30, 30), duration: 1000.ms, curve: Curves.easeInQuint)
                    .fade(end: 0, duration: 300.ms, delay: 700.ms),
              ),
            ).animate().fade(end: 0, duration: 400.ms, delay: 800.ms),
          ),
        ),
      ],
    ),
  );
}"""
    content = content.replace(end_pattern, stack_replacement)
    
    with open("lib/screens/settings_screen.dart", "w") as f:
        f.write(content)
    print("Fixed settings_screen.dart")
else:
    print("Broken block not found")

