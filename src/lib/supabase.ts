/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 *
 * Supabase деректер қабаты — бұрынғы lib/firebase.ts файлының орнына келді.
 * Функция аттары мен қолтаңбалары бірдей сақталды, сондықтан App.tsx-те
 * тек импорт жолын ауыстыру жеткілікті болды.
 *
 * Бұл клиент Juma-ның басқа жобаларымен (mebel-crm, Telegram CRM) БІРДЕЙ
 * Supabase жобасын қолданады: udaijfkqxrafadhxktzl.supabase.co
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  // eslint-disable-next-line no-console
  console.error(
    '[supabase] VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY орнатылмаған. .env файлын тексеріңіз (.env.example қараңыз).'
  );
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Кестелер атауы Firestore коллекцияларымен бірдей қалдырылды:
 * orders, clients, inventory, employees, measurements, users
 */

/**
 * Толық жинақты (массивті) Supabase-ке сақтау — upsert.
 * (Firestore-дегі batch.set(..., {merge:true}) баламасы)
 */
export async function saveCollectionToFirestore<T extends { id: string }>(
  collectionName: string,
  items: T[]
): Promise<void> {
  if (items.length === 0) return;
  try {
    const rows = items.map((item) => toRow(item));
    const { error } = await supabase.from(collectionName).upsert(rows, { onConflict: 'id' });
    if (error) throw error;
  } catch (error) {
    console.error(`Error saving collection ${collectionName} to Supabase:`, error);
    throw error;
  }
}

/**
 * Коллекцияны толық жүктеу.
 */
export async function loadCollectionFromFirestore<T>(collectionName: string): Promise<T[]> {
  try {
    const { data, error } = await supabase.from(collectionName).select('*');
    if (error) throw error;
    return (data ?? []).map((row) => fromRow<T>(row));
  } catch (error) {
    console.error(`Error loading collection ${collectionName} from Supabase:`, error);
    throw error;
  }
}

/**
 * Бір жазбаны сақтау (insert немесе update — upsert).
 */
export async function saveDocToFirestore<T extends { id: string }>(
  collectionName: string,
  item: T
): Promise<void> {
  try {
    const { error } = await supabase.from(collectionName).upsert(toRow(item), { onConflict: 'id' });
    if (error) throw error;
  } catch (error) {
    console.error(`Error saving document in ${collectionName}:`, error);
    throw error;
  }
}

/**
 * Бір жазбаны өшіру.
 */
export async function deleteDocFromFirestore(collectionName: string, id: string): Promise<void> {
  try {
    const { error } = await supabase.from(collectionName).delete().eq('id', id);
    if (error) throw error;
  } catch (error) {
    console.error(`Error deleting document ${id} from ${collectionName}:`, error);
    throw error;
  }
}

/**
 * Supabase Realtime арқылы кестеге жазылу — өзгеріс болғанда callback шақырылады.
 * (Firebase-де болмаған, жаңа мүмкіндік — CRM-дер арасында лайв синхрондау үшін)
 */
export function subscribeToCollection<T>(
  collectionName: string,
  onChange: (items: T[]) => void
): () => void {
  loadCollectionFromFirestore<T>(collectionName).then(onChange).catch(console.error);

  const channel = supabase
    .channel(`realtime:${collectionName}`)
    .on('postgres_changes', { event: '*', schema: 'public', table: collectionName }, () => {
      loadCollectionFromFirestore<T>(collectionName).then(onChange).catch(console.error);
    })
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}

// --- Көмекші функциялар: JS обьект <-> Postgres жолы ---
// Біздің типтеріміздегі кейбір өрістер (costBreakdown, obstacles, т.б.) объект/массив
// болғандықтан, оларды jsonb баганаларға сол қалпында сақтаймыз — supabase-js
// бұл түрлендіруді автоматты орындайды, сондықтан қосымша сериализация қажет емес.
function toRow<T extends Record<string, unknown>>(item: T): Record<string, unknown> {
  return { ...item };
}

function fromRow<T>(row: Record<string, unknown>): T {
  return row as T;
}
