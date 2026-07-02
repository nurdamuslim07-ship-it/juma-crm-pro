# JUMA UI — Мебель CRM Pro

Жиһаз өндірісіне арналған CRM: Тапсырыстар, Клиенттер, Қойма, Қызметкерлер,
Өлшеулер, Есептер және 3D визуализатор. Бұл нұсқа **Supabase** (mebel-crm-мен
бірдей жоба) мен **Telegram Mini App** (`@Juma_ui_bot`) арқылы жұмыс істейтін
етіп бейімделген.

## 1. Supabase дайындау

1. https://supabase.com → жобаңызды ашыңыз: `udaijfkqxrafadhxktzl`.
2. **SQL Editor** бөліміне өтіп, осы жобадағы `supabase_schema.sql` файлының
   толық мазмұнын қойып, іске қосыңыз (кестелерді жасайды: `orders`,
   `clients`, `inventory`, `employees`, `measurements`, `users`).
3. **Project Settings → API** бөлімінен `Project URL` және `anon public`
   кілтін көшіріп алыңыз.
4. Егер `mebel-crm` жобасында осы кестелер басқа атпен/құрылыммен бұрыннан
   бар болса — `supabase_schema.sql`-дағы баған атауларын сол кестелерге
   сай өзгертіп алыңыз (бұл жоба camelCase баған атауларын қолданады, мыс.
   `"clientName"`, себебі `src/lib/supabase.ts` еш түрлендіру жасамайды).

## 2. Жергілікті баптау

```bash
npm install
cp .env.example .env
# .env файлында VITE_SUPABASE_URL және VITE_SUPABASE_ANON_KEY толтырыңыз
npm run dev
```

## 3. GitHub Pages-ке деплой ету

1. Егер репозиторий әлі жоқ болса — GitHub-та жаңа репо ашыңыз, мыс.
   `juma-crm-pro` (nurdamuslim07-ship-it аккаунтыңызда).
2. `vite.config.ts`-тегі `base: '/juma-crm-pro/'` жолын **нақты репо атыңызға**
   сай өзгертіңіз (сызықшалармен, мыс. репо аты `mebel-crm-pro` болса —
   `base: '/mebel-crm-pro/'`).
3. Жобаны сол репозиторийге жүктеңіз:
   ```bash
   git init
   git remote add origin https://github.com/nurdamuslim07-ship-it/juma-crm-pro.git
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git push -u origin main
   ```
4. Тәуелділіктерді орнатып, деплой жасаңыз:
   ```bash
   npm install
   npm run deploy
   ```
   Бұл `dist/` папкасын құрып, оны автоматты түрде `gh-pages` бранчына
   жібереді.
5. GitHub репозиторийде: **Settings → Pages → Source** бөлімінде
   `gh-pages` бранчын таңдаңыз (алғашқы `npm run deploy`-дан кейін
   автоматты пайда болады).
6. Бірнеше минуттан соң сайтыңыз мына сілтемеде тұрады:
   `https://nurdamuslim07-ship-it.github.io/juma-crm-pro/`
7. **Маңызды:** `.env` файлындағы Supabase кілттері `npm run build`
   кезінде жобаға "күйдіріліп" кіреді (Vite build-time env), сондықтан
   деплой жасамас бұрын жергілікті `.env` файлыңыздың толтырылғанына
   көз жеткізіңіз.

## 4. Telegram Mini App ретінде қосу (`@Juma_ui_bot`)

1. Жоғарыдағы 3-қадамда деплой еткен GitHub Pages сілтемеңіз дайын болу керек.
2. Telegram-да **@BotFather** → `@Juma_ui_bot` → **Bot Settings → Menu Button**
   → сол деплой сілтемесін (`https://.../`) қойыңыз.
3. Ботты ашқанда қолданба Telegram ішінде автоматты түрде толық экранға
   жайылады, пайдаланушының Telegram атын анықтап, бұрын тіркелген болса —
   құпия сөзсіз кіргізеді (`src/lib/telegram.ts`).
4. Директор/қызметкер тіркелу формасында Telegram арқылы ашылса, аты-жөні
   алдын ала толтырылады және аккаунтқа `telegramId` тіркеледі.

## 5. Деректер қабаты қалай өзгерді

- `src/lib/firebase.ts` → **`src/lib/supabase.ts`** болды. Функция аттары
  (`saveDocToFirestore`, `loadCollectionFromFirestore`, т.б.) бұрынғыдай
  қалдырылды — App.tsx мен модульдерде тек импорт жолы ауысты, басқа
  логика өзгерген жоқ.
- Firebase/Gemini тәуелділіктері (`firebase`, `@google/genai`, `express`,
  `dotenv`) `package.json`-нан алынды, себебі нақты кодта қолданылмаған еді.
- Жаңа мүмкіндік: `subscribeToCollection()` — Supabase Realtime арқылы
  кестеге лайв жазылу (мыс. екі CRM бір деректі бір мезгілде көру үшін).

## Іске қосу

**Талаптар:** Node.js

1. `npm install`
2. `.env` файлын толтырыңыз (жоғарыдан қараңыз)
3. `npm run dev`
