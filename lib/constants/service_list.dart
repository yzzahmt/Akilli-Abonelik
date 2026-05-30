class PresetSubscription {
  final String name;
  final double price;
  final String emoji;
  final String category;
  final bool isUsdBased;
  final double? usdAmount;
  final String currency;
  final String? domain;

  const PresetSubscription({
    required this.name,
    required this.price,
    required this.emoji,
    required this.category,
    this.isUsdBased = false,
    this.usdAmount,
    this.currency = 'TRY',
    this.domain,
  });
}

class AppConstants {
  static const List<PresetSubscription> presetSubscriptions = [
    // Video
    PresetSubscription(name: 'Netflix Temel', price: 99.00, emoji: '🎬', category: 'Video', domain: 'netflix.com'),
    PresetSubscription(name: 'Netflix Standart', price: 229.00, emoji: '🎬', category: 'Video', domain: 'netflix.com'),
    PresetSubscription(name: 'Netflix Özel (4K)', price: 329.00, emoji: '🎬', category: 'Video', domain: 'netflix.com'),
    PresetSubscription(name: 'Disney+', price: 149.00, emoji: '🏰', category: 'Video', domain: 'disneyplus.com'),
    PresetSubscription(name: 'BluTV', price: 149.00, emoji: '📺', category: 'Video', domain: 'blutv.com'),
    PresetSubscription(name: 'exxen Reklamlı', price: 99.00, emoji: '🎭', category: 'Video', domain: 'exxen.com'),
    PresetSubscription(name: 'exxen Reklamsız', price: 169.00, emoji: '🎭', category: 'Video', domain: 'exxen.com'),
    PresetSubscription(name: 'Amazon Prime Video', price: 39.00, emoji: '📦', category: 'Video', domain: 'amazon.com.tr'),
    PresetSubscription(name: 'GAIN', price: 129.00, emoji: '🎬', category: 'Video', domain: 'gain.tv'),
    PresetSubscription(name: 'MUBI', price: 129.00, emoji: '🎞️', category: 'Video', domain: 'mubi.com'),
    PresetSubscription(name: 'Apple TV+', price: 169.00, emoji: '🍎', category: 'Video', domain: 'tv.apple.com'),
    PresetSubscription(name: 'YouTube Premium', price: 109.00, emoji: '▶️', category: 'Video', domain: 'youtube.com'),
    PresetSubscription(name: 'Bein Connect', price: 149.00, emoji: '⚽', category: 'Video', domain: 'beinconnect.com.tr'),

    // Müzik
    PresetSubscription(name: 'Spotify Bireysel', price: 109.00, emoji: '🎵', category: 'Müzik', domain: 'spotify.com'),
    PresetSubscription(name: 'Spotify Duo', price: 149.00, emoji: '🎵', category: 'Müzik', domain: 'spotify.com'),
    PresetSubscription(name: 'Spotify Aile', price: 179.00, emoji: '🎵', category: 'Müzik', domain: 'spotify.com'),
    PresetSubscription(name: 'Apple Music Bireysel', price: 109.00, emoji: '🎧', category: 'Müzik', domain: 'music.apple.com'),
    PresetSubscription(name: 'Apple Music Aile', price: 179.00, emoji: '🎧', category: 'Müzik', domain: 'music.apple.com'),
    PresetSubscription(name: 'YouTube Music', price: 109.00, emoji: '🎵', category: 'Müzik', domain: 'music.youtube.com'),
    PresetSubscription(name: 'Deezer Premium', price: 89.00, emoji: '🎧', category: 'Müzik', domain: 'deezer.com'),
    PresetSubscription(name: 'Tidal HiFi', price: 149.00, emoji: '🌊', category: 'Müzik', domain: 'tidal.com'),

    // Yapay Zeka
    PresetSubscription(name: 'ChatGPT Plus', price: 929.00, emoji: '🤖', category: 'Yapay Zeka', domain: 'openai.com'),
    PresetSubscription(name: 'Claude Pro', price: 918.00, emoji: '🤖', category: 'Yapay Zeka', domain: 'anthropic.com'),
    PresetSubscription(name: 'Gemini Advanced', price: 549.00, emoji: '✨', category: 'Yapay Zeka', domain: 'deepmind.google'),
    PresetSubscription(name: 'Copilot Pro', price: 649.00, emoji: '🤖', category: 'Yapay Zeka', domain: 'microsoft.com'),
    PresetSubscription(name: 'Midjourney Basic', price: 329.00, emoji: '🖼️', category: 'Yapay Zeka', domain: 'midjourney.com'),
    PresetSubscription(name: 'Adobe Firefly', price: 449.00, emoji: '✨', category: 'Yapay Zeka', domain: 'adobe.com'),
    PresetSubscription(name: 'Perplexity Pro', price: 549.00, emoji: '🔍', category: 'Yapay Zeka', domain: 'perplexity.ai'),

    // Bulut Depolama
    PresetSubscription(name: 'iCloud+ 50GB', price: 39.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'icloud.com'),
    PresetSubscription(name: 'iCloud+ 200GB', price: 109.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'icloud.com'),
    PresetSubscription(name: 'iCloud+ 2TB', price: 379.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'icloud.com'),
    PresetSubscription(name: 'Google One 100GB', price: 39.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'one.google.com'),
    PresetSubscription(name: 'Google One 200GB', price: 69.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'one.google.com'),
    PresetSubscription(name: 'Google One 2TB', price: 349.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'one.google.com'),
    PresetSubscription(name: 'Dropbox Plus', price: 849.00, emoji: '📦', category: 'Bulut Depolama', domain: 'dropbox.com'),
    PresetSubscription(name: 'OneDrive 100GB', price: 39.00, emoji: '☁️', category: 'Bulut Depolama', domain: 'onedrive.live.com'),

    // Yazılım / Araçlar
    PresetSubscription(name: 'Microsoft 365 Bireysel', price: 399.00, emoji: '💼', category: 'Yazılım/Araçlar', domain: 'microsoft365.com'),
    PresetSubscription(name: 'Microsoft 365 Aile', price: 549.00, emoji: '💼', category: 'Yazılım/Araçlar', domain: 'microsoft365.com'),
    PresetSubscription(name: 'Adobe Creative Cloud', price: 1499.00, emoji: '🖌️', category: 'Yazılım/Araçlar', domain: 'adobe.com'),
    PresetSubscription(name: 'Figma Pro', price: 699.00, emoji: '🎨', category: 'Yazılım/Araçlar', domain: 'figma.com'),
    PresetSubscription(name: 'Notion Plus', price: 549.00, emoji: '📝', category: 'Yazılım/Araçlar', domain: 'notion.so'),
    PresetSubscription(name: '1Password', price: 379.00, emoji: '🔐', category: 'Yazılım/Araçlar', domain: '1password.com'),
    PresetSubscription(name: 'NordVPN', price: 329.00, emoji: '🔒', category: 'Yazılım/Araçlar', domain: 'nordvpn.com'),
    PresetSubscription(name: 'ExpressVPN', price: 449.00, emoji: '🔒', category: 'Yazılım/Araçlar', domain: 'expressvpn.com'),
    PresetSubscription(name: 'LastPass Premium', price: 279.00, emoji: '🔑', category: 'Yazılım/Araçlar', domain: 'lastpass.com'),
    PresetSubscription(name: 'Canva Pro', price: 549.00, emoji: '🎨', category: 'Yazılım/Araçlar', domain: 'canva.com'),

    // Oyun
    PresetSubscription(name: 'Xbox Game Pass Ultimate', price: 349.00, emoji: '🎮', category: 'Oyun', domain: 'xbox.com'),
    PresetSubscription(name: 'PlayStation Plus Essential', price: 249.00, emoji: '🎮', category: 'Oyun', domain: 'playstation.com'),
    PresetSubscription(name: 'PlayStation Plus Extra', price: 349.00, emoji: '🎮', category: 'Oyun', domain: 'playstation.com'),
    PresetSubscription(name: 'Nintendo Online', price: 199.00, emoji: '🎮', category: 'Oyun', domain: 'nintendo.com'),
    PresetSubscription(name: 'EA Play', price: 149.00, emoji: '🕹️', category: 'Oyun', domain: 'ea.com'),

    // Eğitim
    PresetSubscription(name: 'Udemy (abonelik)', price: 299.00, emoji: '📚', category: 'Eğitim', domain: 'udemy.com'),
    PresetSubscription(name: 'Coursera Plus', price: 1099.00, emoji: '🎓', category: 'Eğitim', domain: 'coursera.org'),
    PresetSubscription(name: 'Duolingo Plus', price: 279.00, emoji: '🦉', category: 'Eğitim', domain: 'duolingo.com'),
    PresetSubscription(name: 'MasterClass', price: 899.00, emoji: '🎓', category: 'Eğitim', domain: 'masterclass.com'),
    
    // Haber / Dergi
    PresetSubscription(name: 'Medium', price: 159.00, emoji: '📰', category: 'Haber/Dergi', domain: 'medium.com'),

    // Custom
    PresetSubscription(name: 'Diğer', price: 0.0, emoji: '➕', category: 'Diğer'),
  ];
}
