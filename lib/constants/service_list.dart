class PresetSubscription {
  final String name;
  final double price;
  final String emoji;
  final String category;
  final bool isUsdBased;
  final double? usdAmount;
  final String currency;

  const PresetSubscription({
    required this.name,
    required this.price,
    required this.emoji,
    required this.category,
    this.isUsdBased = false,
    this.usdAmount,
    this.currency = 'TRY',
  });
}

class AppConstants {
  static const List<PresetSubscription> presetSubscriptions = [
    // Video Streaming
    PresetSubscription(
      name: 'Netflix Temel',
      price: 189.99,
      emoji: '🎬',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Netflix Standart',
      price: 289.99,
      emoji: '🎬',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Netflix Özel (4K)',
      price: 379.99,
      emoji: '🎬',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Disney+',
      price: 134.99,
      emoji: '🏰',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'BluTV',
      price: 139.90,
      emoji: '📺',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'exxen (Reklamsız)',
      price: 137.90,
      emoji: '🎭',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Amazon Prime Video',
      price: 59.99,
      emoji: '📦',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'GAIN',
      price: 99.99,
      emoji: '🎬',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'MUBI',
      price: 99.99,
      emoji: '🎞️',
      category: 'Video',
    ),

    // Music
    PresetSubscription(
      name: 'Spotify Bireysel',
      price: 99.99,
      emoji: '🎵',
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Spotify Duo',
      price: 139.99,
      emoji: '🎵',
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Spotify Aile',
      price: 179.99,
      emoji: '🎵',
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Apple Music Bireysel',
      price: 79.99,
      emoji: '🎧',
      category: 'Müzik',
    ),

    // Productivity / AI
    PresetSubscription(
      name: 'ChatGPT Plus',
      price: 700.00,
      emoji: '🤖',
      category: 'Yapay Zeka',
      isUsdBased: true,
      usdAmount: 20.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'YouTube Premium Bireysel',
      price: 109.99,
      emoji: '▶️',
      category: 'Video',
    ),
    PresetSubscription(
      name: 'YouTube Premium Aile',
      price: 159.99,
      emoji: '▶️',
      category: 'Video',
    ),

    // Cloud / Apple
    PresetSubscription(
      name: 'iCloud+ 50GB',
      price: 39.99,
      emoji: '☁️',
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'iCloud+ 200GB',
      price: 129.99,
      emoji: '☁️',
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'iCloud+ 2TB',
      price: 399.99,
      emoji: '☁️',
      category: 'Bulut',
    ),

    // Gaming
    PresetSubscription(
      name: 'Xbox Game Pass Core',
      price: 149.99,
      emoji: '🎮',
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'Xbox Game Pass Ultimate',
      price: 249.99,
      emoji: '🎮',
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'PlayStation Plus Essential',
      price: 199.99,
      emoji: '🎮',
      category: 'Oyun',
    ),

    // --- YENİ EKLENENLER (BULUT DEPOLAMA) ---
    PresetSubscription(
      name: 'Google One 100GB',
      emoji: '☁️',
      price: 49.99,
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'Google One 200GB',
      emoji: '☁️',
      price: 99.99,
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'Google One 2TB',
      emoji: '☁️',
      price: 204.99,
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'Google One AI Pro',
      emoji: '🤖',
      price: 719.99,
      category: 'Bulut',
    ),
    PresetSubscription(
      name: 'Turkcell Lifebox 100GB',
      emoji: '📦',
      price: 29.99,
      category: 'Bulut',
    ),

    // --- YENİ EKLENENLER (VİDEO / SPOR) ---
    PresetSubscription(
      name: 'TOD TV (Eğlence)',
      emoji: '📺',
      price: 129.00,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'TOD TV (Spor + Eğlence)',
      emoji: '⚽',
      price: 350.00,
      category: 'Spor',
    ),
    PresetSubscription(
      name: 'TOD TV (Sezonluk Spor)',
      emoji: '⚽',
      price: 399.00,
      category: 'Spor',
    ),
    PresetSubscription(
      name: 'exxen Reklamlı',
      emoji: '🎭',
      price: 219.00,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'exxen Reklamsız',
      emoji: '🎭',
      price: 309.00,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'MUBI',
      emoji: '🎞️',
      price: 99.99,
      category: 'Video',
    ),

    // --- YENİ EKLENENLER (MÜZİK) ---
    PresetSubscription(
      name: 'Spotify Öğrenci',
      emoji: '🎵',
      price: 55.00,
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Apple Music Aile',
      emoji: '🎧',
      price: 129.99,
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'YouTube Music Bireysel',
      emoji: '🎵',
      price: 109.99,
      category: 'Müzik',
    ),

    // --- YENİ EKLENENLER (ÜRETKENLİK / OFİS) ---
    PresetSubscription(
      name: 'Microsoft 365 Bireysel',
      emoji: '💼',
      price: 341.67,
      category: 'Üretkenlik',
    ),
    PresetSubscription(
      name: 'Microsoft 365 Aile',
      emoji: '💼',
      price: 499.99,
      category: 'Üretkenlik',
    ),
    PresetSubscription(
      name: 'Notion Plus',
      emoji: '📝',
      price: 400.00,
      category: 'Üretkenlik',
      isUsdBased: true,
      usdAmount: 10.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Canva Pro',
      emoji: '🎨',
      price: 560.00,
      category: 'Üretkenlik',
      isUsdBased: true,
      usdAmount: 14.99,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Adobe Creative Cloud',
      emoji: '🖌️',
      price: 2299.99,
      category: 'Üretkenlik',
    ),
    PresetSubscription(
      name: 'LinkedIn Premium',
      emoji: '💼',
      price: 1400.00,
      category: 'Üretkenlik',
      isUsdBased: true,
      usdAmount: 39.99,
      currency: 'USD',
    ),

    // --- YENİ EKLENENLER (YAPAY ZEKA) ---
    PresetSubscription(
      name: 'Claude Pro',
      emoji: '🤖',
      price: 700.00,
      category: 'Yapay Zeka',
      isUsdBased: true,
      usdAmount: 20.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Gemini Advanced',
      emoji: '✨',
      price: 719.99,
      category: 'Yapay Zeka',
    ),
    PresetSubscription(
      name: 'Copilot Pro',
      emoji: '🤖',
      price: 800.00,
      category: 'Yapay Zeka',
      isUsdBased: true,
      usdAmount: 20.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Perplexity Pro',
      emoji: '🔍',
      price: 800.00,
      category: 'Yapay Zeka',
      isUsdBased: true,
      usdAmount: 20.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Midjourney Basic',
      emoji: '🖼️',
      price: 400.00,
      category: 'Yapay Zeka',
      isUsdBased: true,
      usdAmount: 10.0,
      currency: 'USD',
    ),

    // --- YENİ EKLENENLER (EĞİTİM) ---
    PresetSubscription(
      name: 'Duolingo Super',
      emoji: '🦉',
      price: 520.00,
      category: 'Eğitim',
      isUsdBased: true,
      usdAmount: 12.99,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Udemy Kişisel Plan',
      emoji: '📚',
      price: 440.00,
      category: 'Eğitim',
      isUsdBased: true,
      usdAmount: 10.99,
      currency: 'USD',
    ),

    // --- YENİ EKLENENLER (OYUN) ---
    PresetSubscription(
      name: 'PlayStation Plus Extra',
      emoji: '🎮',
      price: 299.99,
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'PlayStation Plus Premium',
      emoji: '🎮',
      price: 399.99,
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'EA Play',
      emoji: '🕹️',
      price: 89.99,
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'Apple Arcade',
      emoji: '🍎',
      price: 49.99,
      category: 'Oyun',
    ),
    PresetSubscription(
      name: 'Google Play Pass',
      emoji: '🎯',
      price: 49.99,
      category: 'Oyun',
    ),

    // --- YENİ EKLENENLER (DİĞER) ---
    PresetSubscription(
      name: 'Telegram Premium',
      emoji: '✈️',
      price: 160.00,
      category: 'Diğer',
      isUsdBased: true,
      usdAmount: 3.99,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'X Premium',
      emoji: '✖️',
      price: 360.00,
      category: 'Diğer',
      isUsdBased: true,
      usdAmount: 8.0,
      currency: 'USD',
    ),

    // --- YENİ EKLENENLER (YOUTUBE PREMIUM) ---
    PresetSubscription(
      name: 'YouTube Premium Bireysel',
      emoji: '▶️',
      price: 79.99,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'YouTube Premium Aile',
      emoji: '▶️',
      price: 159.99,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'YouTube Premium Öğrenci',
      emoji: '▶️',
      price: 52.99,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'YouTube Premium Lite',
      emoji: '▶️',
      price: 49.99,
      category: 'Video',
    ),

    // --- YENİ EKLENENLER (TÜRKİYE DİĞER) ---
    PresetSubscription(
      name: 'beIN Connect',
      emoji: '⚽',
      price: 279.99,
      category: 'Spor',
    ),
    PresetSubscription(
      name: 'Fizy Bireysel',
      emoji: '🎵',
      price: 59.99,
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Fizy Aile',
      emoji: '🎵',
      price: 99.99,
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'Deezer Premium',
      emoji: '🎧',
      price: 79.99,
      category: 'Müzik',
    ),
    PresetSubscription(
      name: 'TV+ Premium',
      emoji: '📺',
      price: 129.99,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Tabii',
      emoji: '📺',
      price: 99.99,
      category: 'Video',
    ),
    PresetSubscription(
      name: 'Dropbox Plus',
      emoji: '📦',
      price: 580.00,
      category: 'Bulut',
      isUsdBased: true,
      usdAmount: 11.99,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'NordVPN',
      emoji: '🔒',
      price: 400.00,
      category: 'Güvenlik',
      isUsdBased: true,
      usdAmount: 4.99,
      currency: 'USD',
    ),
    PresetSubscription(
      name: 'Lastpass Premium',
      emoji: '🔑',
      price: 120.00,
      category: 'Güvenlik',
      isUsdBased: true,
      usdAmount: 3.0,
      currency: 'USD',
    ),
    PresetSubscription(
      name: '1Password',
      emoji: '🔐',
      price: 140.00,
      category: 'Güvenlik',
      isUsdBased: true,
      usdAmount: 2.99,
      currency: 'USD',
    ),

    // Custom
    PresetSubscription(
      name: 'Diğer',
      price: 0.0,
      emoji: '➕',
      category: 'Diğer',
    ),
  ];
}
