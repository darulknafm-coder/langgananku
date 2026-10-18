/// Katalog layanan langganan populer di Indonesia.
/// Harga adalah PERKIRAAN paket umum (bisa berubah) — pengguna selalu bisa
/// menyesuaikan nominal saat menambahkan.
class CatalogItem {
  final String key;
  final String name;
  final String category;
  final double monthly;
  final double? yearly; // harga paket tahunan bila tersedia
  final String cancelUrl;
  final List<String> keywords; // dipakai untuk deteksi SMS/email
  final int color;
  final String currency; // 'IDR' / 'USD'

  const CatalogItem({
    required this.key,
    required this.name,
    required this.category,
    required this.monthly,
    this.yearly,
    required this.cancelUrl,
    required this.keywords,
    required this.color,
    this.currency = 'IDR',
  });

  /// Domain situs resmi (dipakai untuk mengambil logo/ikon resmi layanan).
  String get domain =>
      kDomainOverride[key] ??
      Uri.parse(cancelUrl).host.replaceFirst(RegExp(r'^(www|my|account|accounts|langganan)\.'), '');
}

/// Domain logo untuk layanan yang link pembatalannya bukan situs utamanya.
const Map<String, String> kDomainOverride = {
  'hbo': 'max.com',
  'capcut': 'capcut.com',
  'applemusic': 'music.apple.com',
  'icloud': 'icloud.com',
  'ytmusic': 'music.youtube.com',
  'chatgpt': 'chatgpt.com',
  'claude': 'claude.ai',
  'gemini': 'gemini.google.com',
  'm365': 'microsoft365.com',
  'copilot': 'copilot.microsoft.com',
  'gamepass': 'xbox.com',
  'nordvpn': 'nordvpn.com',
  'surfshark': 'surfshark.com',
  'expressvpn': 'expressvpn.com',
  'psplus': 'playstation.com',
  'nintendo': 'nintendo.com',
  'googleone': 'one.google.com',
  'disney': 'hotstar.com',
  'tempo': 'tempo.co',
  'gramedia': 'gramedia.com',
  'notion': 'notion.so',
  'dropbox': 'dropbox.com',
  'adobe': 'adobe.com',
  'zoom': 'zoom.us',
  'linkedin': 'linkedin.com',
  'strava': 'strava.com',
  'telkomsel': 'telkomsel.com',
  'viu': 'viu.com',
  'wetv': 'wetv.vip',
  'catchplay': 'catchplay.com',
  'joox': 'joox.com',
  'langit': 'langitmusik.co.id',
  'kompas': 'kompas.id',
  'perplexity': 'perplexity.ai',
  'midjourney': 'midjourney.com',
};

const String kGooglePlaySubs = 'https://play.google.com/store/account/subscriptions';
const String kAppleSubs = 'https://apps.apple.com/account/subscriptions';

const List<CatalogItem> kCatalog = [
  // Streaming video
  CatalogItem(key: 'netflix', name: 'Netflix', category: 'Streaming Video', monthly: 65000, cancelUrl: 'https://www.netflix.com/cancelplan', keywords: ['netflix'], color: 0xFFE50914),
  CatalogItem(key: 'disney', name: 'Disney+ Hotstar', category: 'Streaming Video', monthly: 65000, yearly: 450000, cancelUrl: 'https://www.hotstar.com/id/mysubscriptions', keywords: ['disney', 'hotstar'], color: 0xFF113CCF),
  CatalogItem(key: 'vidio', name: 'Vidio Platinum', category: 'Streaming Video', monthly: 39000, cancelUrl: 'https://www.vidio.com/dashboard/subscriptions', keywords: ['vidio'], color: 0xFFEE2B47),
  CatalogItem(key: 'prime', name: 'Prime Video', category: 'Streaming Video', monthly: 59000, cancelUrl: 'https://www.primevideo.com/settings', keywords: ['prime video', 'primevideo', 'amazon prime'], color: 0xFF00A8E1),
  CatalogItem(key: 'youtube', name: 'YouTube Premium', category: 'Streaming Video', monthly: 69000, cancelUrl: 'https://www.youtube.com/paid_memberships', keywords: ['youtube'], color: 0xFFFF0000),
  CatalogItem(key: 'viu', name: 'Viu Premium', category: 'Streaming Video', monthly: 33000, cancelUrl: 'https://www.viu.com/ott/id/', keywords: ['viu'], color: 0xFFF5B400),
  CatalogItem(key: 'wetv', name: 'WeTV VIP', category: 'Streaming Video', monthly: 39000, cancelUrl: 'https://wetv.vip/', keywords: ['wetv'], color: 0xFFFF6A00),
  CatalogItem(key: 'hbo', name: 'HBO GO / Max', category: 'Streaming Video', monthly: 50000, cancelUrl: kGooglePlaySubs, keywords: ['hbo'], color: 0xFF5822B4),
  CatalogItem(key: 'catchplay', name: 'CATCHPLAY+', category: 'Streaming Video', monthly: 49000, cancelUrl: 'https://www.catchplay.com/id/', keywords: ['catchplay'], color: 0xFF1F1F1F),
  // Musik
  CatalogItem(key: 'spotify', name: 'Spotify Premium', category: 'Musik', monthly: 59900, cancelUrl: 'https://www.spotify.com/account/subscription/', keywords: ['spotify'], color: 0xFF1DB954),
  CatalogItem(key: 'applemusic', name: 'Apple Music', category: 'Musik', monthly: 69000, cancelUrl: kAppleSubs, keywords: ['apple music'], color: 0xFFFA243C),
  CatalogItem(key: 'ytmusic', name: 'YouTube Music', category: 'Musik', monthly: 49000, cancelUrl: 'https://www.youtube.com/paid_memberships', keywords: ['youtube music'], color: 0xFFFF0033),
  CatalogItem(key: 'joox', name: 'JOOX VIP', category: 'Musik', monthly: 25000, cancelUrl: 'https://www.joox.com/', keywords: ['joox'], color: 0xFF00C26E),
  CatalogItem(key: 'langit', name: 'Langit Musik', category: 'Musik', monthly: 20000, cancelUrl: 'https://www.langitmusik.co.id/', keywords: ['langit musik'], color: 0xFFD7263D),
  // AI
  CatalogItem(key: 'chatgpt', name: 'ChatGPT Plus', category: 'AI', monthly: 349000, cancelUrl: 'https://chatgpt.com/#settings/Subscription', keywords: ['openai', 'chatgpt'], color: 0xFF10A37F),
  CatalogItem(key: 'claude', name: 'Claude Pro', category: 'AI', monthly: 20, yearly: 200, cancelUrl: 'https://claude.ai/settings/billing', keywords: ['anthropic', 'claude.ai', 'claude pro'], color: 0xFFD97757, currency: 'USD'),
  CatalogItem(key: 'gemini', name: 'Google AI Pro (Gemini)', category: 'AI', monthly: 309000, cancelUrl: 'https://one.google.com/settings', keywords: ['gemini', 'google ai pro'], color: 0xFF4285F4),
  CatalogItem(key: 'copilot', name: 'Microsoft Copilot Pro', category: 'AI', monthly: 330000, cancelUrl: 'https://account.microsoft.com/services', keywords: ['copilot'], color: 0xFF7B61FF),
  CatalogItem(key: 'perplexity', name: 'Perplexity Pro', category: 'AI', monthly: 330000, cancelUrl: 'https://www.perplexity.ai/settings/account', keywords: ['perplexity'], color: 0xFF20808D),
  CatalogItem(key: 'midjourney', name: 'Midjourney', category: 'AI', monthly: 165000, cancelUrl: 'https://www.midjourney.com/account', keywords: ['midjourney'], color: 0xFF222222),
  // Cloud
  CatalogItem(key: 'googleone', name: 'Google One', category: 'Cloud', monthly: 26900, yearly: 269000, cancelUrl: 'https://one.google.com/settings', keywords: ['google one', 'google storage'], color: 0xFF34A853),
  CatalogItem(key: 'icloud', name: 'iCloud+', category: 'Cloud', monthly: 15000, cancelUrl: kAppleSubs, keywords: ['icloud'], color: 0xFF3693F3),
  CatalogItem(key: 'dropbox', name: 'Dropbox Plus', category: 'Cloud', monthly: 190000, cancelUrl: 'https://www.dropbox.com/account/plan', keywords: ['dropbox'], color: 0xFF0061FF),
  // Produktivitas
  CatalogItem(key: 'canva', name: 'Canva Pro', category: 'Produktivitas', monthly: 95000, yearly: 995000, cancelUrl: 'https://www.canva.com/settings/billing-and-teams', keywords: ['canva'], color: 0xFF00C4CC),
  CatalogItem(key: 'm365', name: 'Microsoft 365', category: 'Produktivitas', monthly: 135999, cancelUrl: 'https://account.microsoft.com/services', keywords: ['microsoft 365', 'office 365', 'microsoft*'], color: 0xFFD83B01),
  CatalogItem(key: 'notion', name: 'Notion Plus', category: 'Produktivitas', monthly: 165000, cancelUrl: 'https://www.notion.so/', keywords: ['notion'], color: 0xFF2F2F2F),
  CatalogItem(key: 'adobe', name: 'Adobe Creative Cloud', category: 'Produktivitas', monthly: 300000, cancelUrl: 'https://account.adobe.com/plans', keywords: ['adobe'], color: 0xFFFA0F00),
  CatalogItem(key: 'capcut', name: 'CapCut Pro', category: 'Produktivitas', monthly: 99000, cancelUrl: kGooglePlaySubs, keywords: ['capcut'], color: 0xFF000000),
  CatalogItem(key: 'zoom', name: 'Zoom Pro', category: 'Produktivitas', monthly: 230000, cancelUrl: 'https://zoom.us/billing', keywords: ['zoom'], color: 0xFF2D8CFF),
  CatalogItem(key: 'linkedin', name: 'LinkedIn Premium', category: 'Produktivitas', monthly: 450000, cancelUrl: 'https://www.linkedin.com/premium/manage/', keywords: ['linkedin'], color: 0xFF0A66C2),
  // VPN
  CatalogItem(key: 'nordvpn', name: 'NordVPN', category: 'VPN', monthly: 200000, cancelUrl: 'https://my.nordaccount.com/billing/my-subscriptions/', keywords: ['nordvpn', 'nord vpn'], color: 0xFF4687FF),
  CatalogItem(key: 'expressvpn', name: 'ExpressVPN', category: 'VPN', monthly: 210000, cancelUrl: 'https://www.expressvpn.com/subscriptions', keywords: ['expressvpn'], color: 0xFFDA3940),
  CatalogItem(key: 'surfshark', name: 'Surfshark', category: 'VPN', monthly: 180000, cancelUrl: 'https://my.surfshark.com/', keywords: ['surfshark'], color: 0xFF1EBFBF),
  // Game
  CatalogItem(key: 'gamepass', name: 'Xbox Game Pass', category: 'Game', monthly: 160000, cancelUrl: 'https://account.microsoft.com/services', keywords: ['game pass', 'xbox'], color: 0xFF107C10),
  CatalogItem(key: 'psplus', name: 'PlayStation Plus', category: 'Game', monthly: 129000, cancelUrl: 'https://www.playstation.com/acct/management', keywords: ['playstation', 'psn'], color: 0xFF003791),
  CatalogItem(key: 'nintendo', name: 'Nintendo Switch Online', category: 'Game', monthly: 50000, cancelUrl: 'https://accounts.nintendo.com/', keywords: ['nintendo'], color: 0xFFE60012),
  // Berita & bacaan
  CatalogItem(key: 'kompas', name: 'Kompas.id', category: 'Berita & Bacaan', monthly: 50000, cancelUrl: 'https://www.kompas.id/', keywords: ['kompas'], color: 0xFF0C4DA2),
  CatalogItem(key: 'tempo', name: 'Tempo Digital', category: 'Berita & Bacaan', monthly: 55000, cancelUrl: 'https://langganan.tempo.co/', keywords: ['tempo.co', 'tempo digital'], color: 0xFFC8102E),
  CatalogItem(key: 'gramedia', name: 'Gramedia Digital', category: 'Berita & Bacaan', monthly: 89000, cancelUrl: 'https://ebooks.gramedia.com/', keywords: ['gramedia'], color: 0xFF0A4DA2),
  // Internet & pulsa
  CatalogItem(key: 'indihome', name: 'IndiHome', category: 'Internet & Pulsa', monthly: 300000, cancelUrl: 'https://indihome.co.id/', keywords: ['indihome'], color: 0xFFE4202C),
  CatalogItem(key: 'biznet', name: 'Biznet Home', category: 'Internet & Pulsa', monthly: 250000, cancelUrl: 'https://www.biznethome.net/', keywords: ['biznet'], color: 0xFF00539F),
  CatalogItem(key: 'firstmedia', name: 'First Media', category: 'Internet & Pulsa', monthly: 330000, cancelUrl: 'https://www.firstmedia.com/', keywords: ['first media', 'firstmedia'], color: 0xFFE30613),
  CatalogItem(key: 'myrepublic', name: 'MyRepublic', category: 'Internet & Pulsa', monthly: 280000, cancelUrl: 'https://myrepublic.co.id/', keywords: ['myrepublic'], color: 0xFF6A1B9A),
  CatalogItem(key: 'telkomsel', name: 'Telkomsel Halo', category: 'Internet & Pulsa', monthly: 100000, cancelUrl: 'https://www.telkomsel.com/', keywords: ['telkomsel', 'kartuhalo'], color: 0xFFED1C24),
  // Kebugaran
  CatalogItem(key: 'strava', name: 'Strava', category: 'Kebugaran', monthly: 89000, yearly: 699000, cancelUrl: 'https://www.strava.com/account', keywords: ['strava'], color: 0xFFFC4C02),
];

CatalogItem? catalogByKey(String? key) {
  if (key == null) return null;
  for (final c in kCatalog) {
    if (c.key == key) return c;
  }
  return null;
}

/// Cari item katalog yang namanya disebut di dalam teks.
/// Kata kunci yang lebih panjang dicek dulu (mis. "youtube music" sebelum "youtube").
CatalogItem? matchCatalog(String text) {
  final t = text.toLowerCase();
  final pairs = <(String, CatalogItem)>[
    for (final c in kCatalog)
      for (final k in c.keywords) (k, c)
  ]..sort((a, b) => b.$1.length.compareTo(a.$1.length));
  for (final p in pairs) {
    if (t.contains(p.$1)) return p.$2;
  }
  return null;
}
