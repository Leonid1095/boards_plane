const BASE_URL =
  process.env.PLG_BASE_URL?.replace(/\/+$/, '') || 'http://localhost:3000';

const SUPPORT_EMAIL = process.env.PLG_SUPPORT_EMAIL || 'support@localhost';

export const BRAND = {
  productName: 'PLGames',
  companyName: 'PLGames',
  aiName: 'PLGames AI',
  cloudName: 'PLGames Cloud',
  tagline: 'Collaborative planning hub for builders and players',
  urls: {
    marketing: BASE_URL,
    app: `${BASE_URL}/app`,
    blog: `${BASE_URL}/blog`,
    docs: `${BASE_URL}/docs`,
    download: `${BASE_URL}/download`,
    changelog: `${BASE_URL}/what-is-new`,
    pricing: `${BASE_URL}/contact`,
    requestLicense: `${BASE_URL}/contact`,
    discord: `${BASE_URL}/community`,
    github: 'https://github.com/PLGamesHQ/plgames',
    terms: `${BASE_URL}/terms`,
    privacy: `${BASE_URL}/privacy`,
    support: `${BASE_URL}/support`,
    status: `${BASE_URL}/status`,
  },
  contact: {
    supportEmail: SUPPORT_EMAIL,
  },
} as const;

type ReplacementRule = [pattern: RegExp, replacement: string];

const replacementRules: ReplacementRule[] = [
  [/https?:\/\/docs\.plgames\.pro/gi, BRAND.urls.docs],
  [/https?:\/\/plgames\.pro\/blog/gi, BRAND.urls.blog],
  [/https?:\/\/plgames\.pro\/download/gi, BRAND.urls.download],
  [/https?:\/\/plgames\.pro\/what-is-new/gi, BRAND.urls.changelog],
  [/https?:\/\/plgames\.pro\/pricing/gi, BRAND.urls.pricing],
  [/https?:\/\/plgames\.pro\/redirect\/discord/gi, BRAND.urls.discord],
  [/https?:\/\/plgames\.pro\/redirect\/license/gi, BRAND.urls.requestLicense],
  [/https?:\/\/plgames\.pro\/?(\b|$)/gi, `${BRAND.urls.marketing}$1`],
  [/community\.plgames\.pro/gi, BRAND.urls.discord],
  [/app\.plgames\.pro/gi, BRAND.urls.app],
  [/github\.com\/PLGamesHQ\/plgames/gi, BRAND.urls.github],
  [/support@plgames\.pro/gi, BRAND.contact.supportEmail],
  [/AFFiNE Cloud/g, BRAND.cloudName],
  [/AFFiNE AI/g, BRAND.aiName],
  [/AFFiNE\.pro/gi, BRAND.urls.marketing],
  [/AFFiNE/gi, BRAND.productName],
  [/Affine/gi, BRAND.productName],
  [/affine/gi, BRAND.productName.toLowerCase()],
];

export const applyBranding = (input: unknown): unknown => {
  if (typeof input !== 'string') {
    return input;
  }

  return replacementRules.reduce(
    (acc, [pattern, replacement]) => acc.replace(pattern, replacement),
    input
  );
};
