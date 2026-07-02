/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 *
 * Telegram Mini App (WebApp) SDK жеңіл орамасы.
 * @Juma_ui_bot ботының мәзір батырмасы арқылы ашылғанда бұл модуль іске қосылады.
 * Егер қосымша қарапайым браузерде ашылса (Telegram сыртында), барлық функциялар
 * "тыныш" түрде ештеңе істемей өтеді — қолданба бұрынғыдай жұмыс істей береді.
 */

export interface TelegramUser {
  id: number;
  first_name: string;
  last_name?: string;
  username?: string;
  language_code?: string;
  photo_url?: string;
}

interface TelegramWebApp {
  ready: () => void;
  expand: () => void;
  close: () => void;
  enableClosingConfirmation: () => void;
  setHeaderColor: (color: string) => void;
  setBackgroundColor: (color: string) => void;
  initData: string;
  initDataUnsafe: {
    user?: TelegramUser;
    start_param?: string;
  };
  colorScheme: 'light' | 'dark';
  themeParams: Record<string, string>;
  viewportHeight: number;
  isExpanded: boolean;
  HapticFeedback?: {
    impactOccurred: (style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft') => void;
    notificationOccurred: (type: 'error' | 'success' | 'warning') => void;
    selectionChanged: () => void;
  };
  MainButton: {
    text: string;
    show: () => void;
    hide: () => void;
    setText: (text: string) => void;
    onClick: (cb: () => void) => void;
    offClick: (cb: () => void) => void;
  };
  BackButton: {
    show: () => void;
    hide: () => void;
    onClick: (cb: () => void) => void;
    offClick: (cb: () => void) => void;
  };
  onEvent: (eventType: string, cb: () => void) => void;
}

declare global {
  interface Window {
    Telegram?: {
      WebApp: TelegramWebApp;
    };
  }
}

export function getTelegramWebApp(): TelegramWebApp | null {
  if (typeof window === 'undefined') return null;
  return window.Telegram?.WebApp ?? null;
}

/** Қолданба Telegram Mini App ретінде ашылған-ашылмағанын анықтайды. */
export function isTelegramMiniApp(): boolean {
  const wa = getTelegramWebApp();
  return !!wa && !!wa.initData;
}

/**
 * Telegram WebApp-ты іске қосу: толық экранға жаю, жабуды растауды қосу,
 * қараңғы/ақшыл тақырыпты Juma CRM-нің dark_mode параметрімен үйлестіру.
 * main.tsx немесе App.tsx-те бір рет шақырылады.
 */
export function initTelegramWebApp(onThemeChange?: (isDark: boolean) => void): void {
  const wa = getTelegramWebApp();
  if (!wa) return;

  wa.ready();
  wa.expand();
  try {
    wa.enableClosingConfirmation();
  } catch {
    /* кейбір нұсқаларда жоқ болуы мүмкін */
  }

  const applyTheme = () => onThemeChange?.(wa.colorScheme === 'dark');
  applyTheme();
  wa.onEvent('themeChanged', applyTheme);
}

/** Ботты ашқан Telegram пайдаланушысының деректері (аты, username, id). */
export function getTelegramUser(): TelegramUser | null {
  return getTelegramWebApp()?.initDataUnsafe?.user ?? null;
}

/** Қате/сәттілік кезінде жеңіл дірілдеу — түймелерде қолдану үшін. */
export function hapticFeedback(type: 'light' | 'medium' | 'heavy' | 'success' | 'error' | 'warning' = 'light'): void {
  const haptic = getTelegramWebApp()?.HapticFeedback;
  if (!haptic) return;
  if (type === 'success' || type === 'error' || type === 'warning') {
    haptic.notificationOccurred(type);
  } else {
    haptic.impactOccurred(type);
  }
}

/**
 * Серверде (Supabase Edge Function) initData қолтаңбасын тексеру үшін жіберілетін
 * шикі жол. Осы жобаны mebel-crm-дегідей @Juma_ui_bot ботына қосқанда,
 * бэкендте BOT_TOKEN арқылы HMAC тексеруін іске асыру керек — құпия сөзді
 * клиент жағында ешқашан тексермеңіз.
 */
export function getTelegramInitData(): string | null {
  return getTelegramWebApp()?.initData || null;
}
