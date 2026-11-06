# 📁 AviDrive - Техническое задание

**ГЛОБАЛЬНОЕ ПРАВИЛО:** `0` для любой квоты = **"БЕЗ ЛИМИТА"**.
---

## 🎯 ОПИСАНИЕ
**AviDrive** — файловое хранилище (аналог Dropbox) с контролем доступа, общими папками, публичными ссылками. Автор: **Avizero**.

## 🛠️ СТЕК
- **Backend:** Java 17, Spring Boot 3, Spring Security, Spring Data JPA, SQLite, Lombok, Maven
- **Frontend:** React 18, Vite, React Router, Axios, Context API, react-toastify, Monaco Editor, PDF.js
- **Хранение:** SQLite (метаданные) + файловая система

---

## 👥 РОЛИ И МАТРИЦА ПРАВ

**Иерархия:** ADMIN > MODERATOR > USER

| Действие | ADMIN | MODERATOR | USER |
|----------|-------|-----------|------|
| Видеть пользователей | ✅ всех | ✅ всех | ❌ только себя |
| Редактировать ADMIN | ❌ только себя | ❌ серая | ❌ серая |
| Редактировать MODERATOR | ✅ | ❌ только себя | ❌ серая |
| Редактировать USER | ✅ | ✅ | ❌ только себя |
| Сменить свой пароль | ✅ | ✅ | ✅ |
| Сбросить пароль другому | ✅ MOD/USER | ✅ USER | ❌ |
| Хранилище ADMIN | ❌ только свое | ❌ | ❌ |
| Хранилище MODERATOR | ✅ | ❌ только свое | ❌ |
| Хранилище USER | ✅ | ✅ | ✅ только свое |

**Безграничный доступ:** ADMIN/MODERATOR имеют ПОЛНЫЕ права над файлами пользователей ниже по иерархии (загрузка, удаление, переименование, права, ссылки) — как будто они сам пользователь.

**Серые кнопки:** Недоступные действия — `disabled` + tooltip "Недостаточно прав".

### Роли
**ADMIN:** Создаётся через Start.sh/mode. Видит всех, управляет сервисом (глобальная квота), создаёт/удаляет (кроме других ADMIN), назначает MODERATOR/USER.

**MODERATOR:** Создаётся только ADMIN. Видит всех, но управляет только USER.

**USER:** Создаётся ADMIN/MODERATOR. Аутентификация по username (не email!). Валидация: латиница+цифры+_, 3-20 символов, не начинается с цифры.

---

## 📋 ФУНКЦИОНАЛЬНЫЕ ТРЕБОВАНИЯ

### A. Страница входа
- Форма: username + пароль
- Placeholder: `"Введите логин"` (без примеров)
- Название "AviDrive" + логотип по центру
- Тёмная/светлая тема
- НЕТ кнопки "Регистрация"

### B. Файловый менеджер

#### 📤 ЗАГРУЗКА
**Способы:**
- Drag & Drop из ОС в браузер
- Кнопка "Загрузить файлы"
- **Отдельная кнопка "Загрузить папку"** (`webkitdirectory`)

**Правила:**
1. ЛЮБЫЕ типы файлов (включая .exe, .bat)
2. Папки создаются в **текущей директории** файлового менеджера
3. **Структура папок сохраняется полностью** (все подкаталоги и файлы)
4. Кнопки загрузки **только у папок/корня**, у файлов — нет
5. Лимит размера файла отсутствует — только квота

**Проверка квоты ДО загрузки (фронт + бэк):**
- Квота пользователя: `used + размер <= quota` (0 = без лимита)
- Глобальная квота: `global_used + размер <= global_quota` (0 = без лимита)
- При превышении — Toast, загрузка не начинается

**Заголовки безопасности:** `Content-Type: application/octet-stream`, `X-Content-Type-Options: nosniff`, `Content-Disposition: attachment`

**Параллельная загрузка:** 3-5 файлов одновременно

**⚠️ Обработка незавершённых загрузок:**
- Файл, не загруженный на 100% = **битый** → **удаляется с сервера**
- Сценарии: разрыв соединения, отмена пользователем, таймаут, иные ошибки
- **Для одиночных файлов:** удаляется полностью
- **Для папок:** удаляются **только недогруженные файлы**, успешно загруженные **остаются**
- Квота пересчитывается после удаления

#### 📊 ПРОГРЕСС-БАР ЗАГРУЗКИ

**Для одного файла:**
```
┌────────────────────────────────────────────┐
│ 📄 report.pdf (4.1 MB)                     │
│ ████████████████░░░░░░░░░░░░░░  62%        │
│ Скорость: 3.4 MB/s | Осталось: ~2 сек     │
│                    [✕ Отменить]            │
└────────────────────────────────────────────┘
```

**Для папки:**
```
┌─────────────────────────────────────────────┐
│ 📁 Загрузка: "Project" (12 файлов, 45.3 MB) │
├─────────────────────────────────────────────┤
│ ████████████████░░░░░░░░░░░░░░  62%         │
│                                             │
│ Сейчас: Documents/report.pdf (2.3/4.1 MB)   │
│ ✓ Photos/vacation.jpg (1.2 MB)              │
│ ✓ Photos/beach.png (856 KB)                 │
│ ⏳ src/main.java (ожидание...)              │
│ ⏳ src/utils.js (ожидание...)               │
│                                             │
│ Скорость: 3.4 MB/s | Осталось: ~8 сек      │
│                                             │
│              [⏸ Пауза]  [✕ Отменить]       │
└─────────────────────────────────────────────┘
```

**Отображается:** имя папки, кол-во файлов, общий размер, общий прогресс %, текущий файл с прогрессом, загруженные файлы (✓), ожидающие (⏳), скорость MB/s, оставшееся время, кнопки "Пауза" и "Отменить".

**Технически:** `FormData` + `XMLHttpRequest` (для `upload.onprogress`) или `fetch` с `ReadableStream`.

#### 📥 СКАЧИВАНИЕ
1. **Файлы** скачиваются как есть (оригинальное имя)
2. **Папки** скачиваются как **ZIP-архив** (DEFLATE сжатие, структура сохраняется)
3. Имя ZIP: `{имя_папки}.zip`
4. Массовое скачивание — один ZIP с сохранением структуры

#### 🖱️ НАВИГАЦИЯ
- Breadcrumbs: `Главная / Документы / Работа`
- Создание/переименование/удаление папок и файлов
- **Удаление мгновенное** — без корзины, безвозвратно
- Сортировка: имя (A-Z/Z-A), дата создания/изменения, размер, тип
- Фильтрация: все/изображения/видео/аудио/документы/архивы/другие, только файлы/только папки
- Пагинация: 50-100 файлов (Backend: LIMIT/OFFSET)
- Массовые операции: чекбоксы + "Выбрать все" → панель (Скачать ZIP, Удалить, Переместить, Поделиться)
- Drag & Drop между папками
- Контекстное меню (правый клик): Открыть, Скачать, Переименовать, Поделиться, Удалить, Свойства
- Горячие клавиши: Delete, F2, Ctrl+A, Escape, Ctrl+F, F5, Стрелки, Enter, `?`
- Режимы: Список/Плитка/Крупные значки (localStorage)

#### 👁️ ПРОСМОТР ОНЛАЙН
- **Видео** (mp4, webm, avi, mov, mkv, flv): HTML5 `<video>`, скорость 0.5x-2x, полный экран, громкость, перемотка, preload. **Range requests** на бэке. БЕЗ транскодинга.
- **Аудио** (mp3, wav, flac, ogg, aac, m4a): HTML5 `<audio>`
- **Изображения** (jpg, jpeg, png, gif, svg, webp, bmp): модалка, zoom, скачивание
- **Текст** (txt, md, json, xml, js, css, html, py, java, c, cpp, sql, yml, log, csv): Monaco Editor/CodeMirror, редактирование (при правах), сохранение
- **PDF**: PDF.js viewer с масштабированием
- **Office** (docx, xlsx, pptx, doc, xls, ppt): **ПРОСМОТР НЕДОСТУПЕН**, только скачивание

#### 🖼️ ПРЕВЬЮ
- Изображения: миниатюры 100x100/200x200, lazy loading, кэш
- Видео: первый кадр + play + длительность
- PDF: первая страница + иконка
- Другие: иконка типа + цвет

#### 🔗 ПУБЛИЧНЫЕ ССЫЛКИ
- **Несколько ссылок** к одному файлу/папке, каждая со своими настройками
- Срок: календарь `datetime-local` (дата + время)
- Опциональный пароль
- Квоты (чекбоксы): Просмотр, Скачивание, Загрузка (папки), Удаление, Переименование
- **Лимиты** (видны только если `upload: true`):
  - `max_file_size_mb` (0 = без лимита)
  - `max_total_size_mb` (0 = без лимита)
- Редактирование существующих ссылок (кнопка "Редактировать" → модалка)
- Статистика: view_count, download_count, upload_count, last_accessed_at
- Права работают реально: проверка на фронте (скрытие кнопок) и бэке (отклонение)
- UI: список ссылок с кнопками "Копировать", "Редактировать", "Удалить", "Создать новую"

**Доступ для зарегистрированных:**
- Добавление по username
- Квоты (JSON): Просмотр, Скачивание, Загрузка, Удаление, Переименование, Создание папок, Предоставление доступа
- Наследование прав (папка → файлы)
- Приоритет: редактирование → просмотр

#### 📁 ОБЩИЕ ПАПКИ
- Создаёт ЛЮБОЙ пользователь
- Визуально выделены (иконка 👥), указан владелец: `"Название (владелец: username)"`
- Квота расходуется у **ВЛАДЕЛЬЦА**
- Индивидуальные лимиты участников (видны только если `upload: true`):
  - `max_file_size_mb` (0 = без лимита)
  - `max_user_space_mb` (0 = без лимита)
- Раздел "Общие папки" в боковой панели

#### 🔍 ПОИСК
- Глобальный поиск по имени файла/папки
- Фильтры: тип, дата
- Поисковая строка в Header, автодополнение (5-10 результатов)
- Backend: `LIKE`, индекс на `name`, пагинация по 50

#### 📊 УВЕДОМЛЕНИЯ О КВОТЕ
- 80% — Toast, 90% — модалка, 95% — модалка + блокировка, 100% — полная блокировка
- Индикатор в Header: прогресс-бар + текст "45.2 GB из 50 GB"
- Цвета: зелёный/жёлтый/оранжевый/красный

#### 👤 ПРОФИЛЬ
- Информация: username, роль, квота, использовано
- Смена пароля: "Текущий пароль", "Новый пароль" (мин. 8), "Повторите новый пароль"

### C. Админ-панель и модер-панель

**Главная:**
- "Управление сервисом" (только ADMIN): глобальная квота, прогресс-бар, статистика
- Поиск "Поиск по username..." (живой)
- Таблица: **Ник | Должность | Статус | Действия**
- Кнопка **"Управление"** у каждого пользователя

**Модальное окно "Управление пользователем":**
```
┌──────────────────────────────────────────────────────────┐
│  Управление: alex_ivanov (USER)                     [✕] │
├──────────────┬───────────────────────────────────────────┤
│              │ [Основная рабочая область]                │
│ 📁 Файлы     │                                           │
│ ✏️ Редакт.   │ Содержимое выбранного раздела:            │
│ 🔑 Пароль    │ - Файловый менеджер (полный доступ)       │
│ ❌ Удалить   │ - Форма редактирования                    │
│              │ - Форма смены пароля                      │
│ [◀ Свернуть] │                                           │
└──────────────┴───────────────────────────────────────────┘
         [↔ Масштабировать окно по верткали и горезонтали]
```

**Боковая панель (слева):** 
- Развёрнута: ~250px (иконка + текст)
- Свёрнута: ~60px (только иконки)
- Анимация: `transition: width 0.3s ease`
- Tooltip при наведении в свёрнутом режиме
- Кнопка "Свернуть/Развернуть"

**Основная область:**
- "Файлы" — полноценный файловый менеджер пользователя (загрузка, удаление, права, ссылки — как от его лица)
- "Редактировать" — форма (квота, роль, блокировка)
- "Пароль" — форма смены пароля
- "Удалить" — подтверждение + удаление всех файлов

**Масштабирование:** за углы/края. Мин: 800x600px, Макс: 95% экрана.

---

## 🗄️ СТРУКТУРА БД (SQLite)

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    quota_mb BIGINT NOT NULL,
    used_space_mb BIGINT DEFAULT 0,
    is_blocked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE files (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    path VARCHAR(1000) NOT NULL,
    is_directory BOOLEAN NOT NULL,
    size_bytes BIGINT DEFAULT 0,
    parent_id BIGINT,
    owner_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE file_permissions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    file_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    permissions TEXT NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(file_id, user_id)
);

CREATE TABLE share_links (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    token VARCHAR(255) UNIQUE NOT NULL,
    file_id BIGINT NOT NULL,
    password_hash VARCHAR(255),
    permissions TEXT NOT NULL,
    expires_at TIMESTAMP,
    max_file_size_mb BIGINT DEFAULT 0,
    max_total_size_mb BIGINT DEFAULT 0,
    view_count BIGINT DEFAULT 0,
    download_count BIGINT DEFAULT 0,
    upload_count BIGINT DEFAULT 0,
    last_accessed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE shared_folders (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    owner_id BIGINT NOT NULL,
    quota_mb BIGINT NOT NULL DEFAULT 0,
    used_space_mb BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE shared_folder_members (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    folder_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    permissions TEXT NOT NULL,
    max_file_size_mb BIGINT DEFAULT 0,
    max_user_space_mb BIGINT DEFAULT 0,
    used_space_mb BIGINT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (folder_id) REFERENCES shared_folders(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(folder_id, user_id)
);

CREATE TABLE settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL
);
```

**Хранение файлов:**
```
/storage/
├── user_1/
│   ├── Documents/report.pdf
│   ├── im.pdf
│   └── Photos/vacation.jpg
├── user_2/
└── shared/
    └── folder_1/
```
Путь в `config.txt`. В БД — относительно корня пользователя.

---

## 🔌 REST API

**Auth:** `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me`, `PUT /api/auth/password`

**Files:** `GET /api/files`, `GET /api/files/{folderId}`, `POST /api/files/upload`, `POST /api/files/folder`, `PUT /api/files/{id}/rename`, `DELETE /api/files/{id}`, `GET /api/files/{id}/download`, `GET /api/files/{id}/view`, `PUT /api/files/{id}/content`, `GET /api/files/stats`

**Permissions:** `POST /api/permissions`, `GET /api/permissions/{fileId}`, `PUT /api/permissions/{id}`, `DELETE /api/permissions/{id}`

**Sharing:** `POST /api/share/link`, `GET /api/share/link/{fileId}`, `PUT /api/share/link/{id}`, `DELETE /api/share/link/{id}`, `GET /api/public/{token}`, `POST /api/public/{token}/download`, `POST /api/public/{token}/upload`

**Shared Folders:** `POST /api/shared/folders`, `GET /api/shared/folders`, `GET /api/shared/folders/{id}`, `POST /api/shared/folders/{id}/members`, `PUT /api/shared/folders/{id}/members/{userId}`, `DELETE /api/shared/folders/{id}/members/{userId}`

**Search:** `GET /api/search?q={query}&type={type}&date={date}`

**User Management:** `GET /api/users`, `POST /api/users`, `PUT /api/users/{id}`, `PUT /api/users/{id}/role`, `PUT /api/users/{id}/password`, `DELETE /api/users/{id}`

**Admin Files:** `GET /api/admin/users/{userId}/files`, `POST /api/admin/users/{userId}/files/upload`, `POST /api/admin/users/{userId}/files/folder`, `PUT /api/admin/users/{userId}/files/{fileId}/rename`, `DELETE /api/admin/users/{userId}/files/{fileId}`, `GET /api/admin/stats`, `PUT /api/admin/settings/global-quota`

---

## 🎨 FRONTEND СТРУКТУРА
```
src/
├── components/
│   ├── Auth/ (LoginForm.jsx, ProtectedRoute.jsx)
│   ├── FileManager/ (FileList.jsx, FileItem.jsx, Breadcrumb.jsx, UploadModal.jsx, CreateFolderModal.jsx, ContextMenu.jsx, MassActionsBar.jsx, SearchBar.jsx, SortFilter.jsx, Pagination.jsx, UploadProgress.jsx)
│   ├── Viewer/ (TextViewer.jsx, ImageViewer.jsx, VideoPlayer.jsx, AudioPlayer.jsx, PdfViewer.jsx)
│   ├── Sharing/ (ShareModal.jsx, ShareLinksList.jsx, ShareLinkItem.jsx, PermissionsModal.jsx, PublicAccess.jsx)
│   ├── SharedFolders/ (SharedFoldersList.jsx, CreateSharedFolderModal.jsx)
│   ├── Profile/ (ProfileInfo.jsx, ChangePassword.jsx)
│   ├── Admin/ (UsersTable.jsx, UserForm.jsx, AdminStats.jsx, UserManagementModal.jsx, ServiceSettings.jsx)
│   └── common/ (Header.jsx, ThemeToggle.jsx, Sidebar.jsx, LoadingSpinner.jsx, ErrorBoundary.jsx, Toast.jsx)
├── pages/ (LoginPage.jsx, DashboardPage.jsx, PublicAccessPage.jsx, ProfilePage.jsx, AdminPage.jsx, SearchResultsPage.jsx)
├── context/ (AuthContext.jsx, ThemeContext.jsx)
├── services/ (api.js)
├── utils/ (formatters.js, validators.js, permissions.js, hotkeys.js)
└── App.jsx
```

## 🎨 БРЕНДИРОВАНИЕ
- **Название:** AviDrive, **Автор:** Avizero
- Отображается: вход, header, title, favicon, footer ("© 2026 AviDrive by Avizero")
- **Темы:** Тёмная (по умолчанию) + светлая. Переключатель в Header. localStorage. Плавный переход (CSS transition)
- **Анимации:** модалки fade-in/fade-out 200-300ms + scale 0.95→1 + backdrop blur, skeleton loaders (shimmer), переходы страниц fade/slide

---

## 🔐 БЕЗОПАСНОСТЬ
1. Пароли: BCrypt, мин. 8 символов
2. JWT: 24 часа, localStorage, секрет мин. 32 символа
3. Права: проверка на каждом endpoint, матрица прав
4. SQL: только Spring Data JPA, без конкатенации
5. Path Traversal: `Path.normalize()` + `startsWith(userRoot)`, санитизация имён
6. Zip Slip: проверка entry на `..`
7. XSS: запрет `dangerouslySetInnerHTML`, экранирование HTML
8. Command Injection: валидация username `^[a-zA-Z0-9_]{3,20}$`, экранирование кавычек
9. Rate Limiting: 10 попыток входа за 5 минут на username
10. Файлы: заголовки `X-Content-Type-Options: nosniff`, `application/octet-stream`
11. Транзакции: `@Transactional` для квот
12. Валидация квот: дублируется на backend
13. SSL/TLS: HTTP/HTTPS, настройка через `config.txt`

---
## 📱 АДАПТИВНОСТЬ (Mobile + Tablet)

**Breakpoints:**
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

### Правила адаптации

**Sidebar:**
- Desktop: постоянная, сворачивается до иконок
- Tablet/Mobile: **выдвижной drawer** (overlay) по кнопке ☰, закрывается свайпом/кликом вне

**Файловый менеджер:**
- Desktop: режимы Список/Плитка/Крупные значки
- Tablet: Плитка по умолчанию (2-3 колонки)
- Mobile: Плитка (2 колонки), переключатель в Header

**Таблицы (админка, пользователи):**
- Desktop: полноценная таблица
- Tablet/Mobile: **карточки** (каждый элемент — отдельная карточка с кнопкой действия)

**Модальные окна:**
- Desktop: по центру, масштабируемые
- Tablet: почти на весь экран
- Mobile: **full-screen** (на весь экран), свайп вниз для закрытия

**Контекстное меню:**
- Desktop: правый клик
- Mobile/Tablet: **долгое нажатие (long press)** → bottom sheet с действиями

**Свайпы по файлам (Mobile/Tablet):**
- Свайп влево → действия (Удалить, Поделиться)
- Свайп вправо → Выбрать (чекбокс)

**Header:**
- Mobile: поиск сворачивается в иконку 🔍
- **Квота показывается в Header** на всех устройствах (компактный прогресс-бар)

**Прогресс-бар загрузки:**
- Mobile: компактный (только % и текущий файл, без скорости)

**Touch-жесты:**
- Pinch-to-zoom для изображений в просмотрщике
- Pull-to-refresh для обновления списка файлов

**Кнопки и элементы:**
- Минимальный размер touch-цели: 44x44px
- Увеличенные отступы между кликабельными элементами на Mobile

**Шрифты:**
- Mobile: базовый 14px
- Tablet: 15px
- Desktop: 16px

**Модальное окно "Управление пользователем":**
- Desktop: модальное окно с боковой панелью
- Tablet: модальное окно на 90% экрана
- Mobile: **полноэкранный режим**, боковая панель превращается в нижнее меню навигации (tabs: Файлы | Редакт. | Пароль)

---

## 📦 ПЛАН РЕАЛИЗАЦИИ

**Шаг 0:** Git. `git init`, `git config user.name "Avizero"`, `git config user.email "avizero@example.com"`, `.gitignore`, первый коммит и push.

**Шаг 1:** Spring Boot, `application.yml`, `config.txt`, структура пакетов.

**Шаг 2:** БД: Entity, Repository, Auto-DDL, скрипты `mode.bat`/`mode.sh`.
- mode скрипты: НАПРЯМУЮ с SQLite через `sqlite3`, НЕ через HTTP API
- Кодировка bat: UTF-8
- Валидация username, экранирование кавычек
- Проверка зависимостей в начале

**Шаг 3:** Аутентификация: JWT, AuthService/Controller (по username), Spring Security, Rate Limiting.

**Шаг 4:** Файловый менеджер (Backend): FileService/Controller, multipart, проверка квоты, онлайн-просмотр, защита от Path Traversal/Zip Slip, Range requests.

**Шаг 5:** Права и шаринг (Backend): PermissionService/Controller (JSON), ShareLinkService/Controller (несколько ссылок, статистика, лимиты).

**Шаг 6:** Общие папки (Backend): SharedFolderService/Controller, индивидуальные лимиты.

**Шаг 7:** Управление пользователями (Backend): UserService/Controller, матрица прав, глобальная квота.

**Шаг 8:** Поиск (Backend): SearchService/Controller.

**Шаг 9:** Frontend: React+Vite, роутинг, контексты, Axios, брендирование, тёмная тема, Error Boundary, react-toastify.

**Шаг 10:** Frontend авторизация: LoginPage, ProtectedRoute, смена пароля.

**Шаг 11:** Frontend файловый менеджер: Dashboard, FileList, FileItem, **загрузка с информативным прогресс-баром** (текущий файл, общий прогресс, скорость, пауза/отмена), просмотр онлайн, Breadcrumbs, сортировка/фильтрация, пагинация, массовые операции, Drag & Drop, превью, контекстное меню, горячие клавиши, поиск.

**Шаг 12:** Frontend права и шаринг: ShareModal, ShareLinksList, ShareLinkItem (редактирование, статистика, календарь, лимиты), PermissionsModal, PublicAccessPage.

**Шаг 13:** Frontend общие папки: SharedFoldersList, CreateSharedFolderModal, управление участниками.

**Шаг 14:** Frontend админка: AdminPage, ServiceSettings, UsersTable с поиском, UserManagementModal (боковая панель слева, сворачивание, масштабирование).

**Шаг 15:** Уведомления о квоте: индикатор в Header, пороги 80/90/95/100%.

**Шаг 16:** Анимации и UX: плавные переходы, skeleton loaders, оптимистичные обновления, кэширование.

**Шаг 17:** Отладочные скрипты Windows (`run-backend.bat`, `run-frontend.bat`).
- Только для отладки на Windows (НЕ продакшен)
- Два отдельных процесса: backend и frontend
- Кодировка: **UTF-8**
- Проверка зависимостей, цветной вывод

**Шаг 18:** Деплой-скрипт `Start.sh` для Linux (Debian/Ubuntu).
- Только root (проверка `id -u`), БЕЗ sudo
- Идемпотентность
- Мастер настройки (9 шагов):
  1. Определение системы
  2. Проверка/установка зависимостей (openjdk-17-jdk, maven, nodejs, npm, sqlite3, curl, git, nginx, certbot, python3-certbot-nginx, ufw, unzip)
  3. Порты (backend 8080, frontend 3000)
  4. Домен + SSL (certbot --nginx) или HTTP
  5. **UFW:** настройка правил (SSH, HTTP, HTTPS, backend, frontend), но **НЕ включать автоматически** — только вручную `sudo ufw enable`
  6. Расположение хранилища (по умолчанию /var/lib/avidrive/storage)
  7. Создание администратора
  8. Сборка (mvn clean package, npm install && build)
  9. Systemd сервисы + автозапуск
- SSL: certbot + Nginx reverse proxy + автообновление cron
- Systemd: `avidrive-backend.service`, `avidrive-frontend.service`
- Проверки после установки: backend, frontend, SSL, БД, хранилище
- Логирование в `setup.log`

**Шаг 19:** Исправление и тестирование mode.* и Start.* скриптов.

**Шаг 20:** Обновление README.md с командой установки.

**Шаг 21:** Финальное тестирование.

---

## ⚙️ КОНФИГУРАЦИЯ

**application.yml:**
```yaml
spring:
  datasource:
    url: jdbc:sqlite:./data/filestorage.db
    driver-class-name: org.sqlite.JDBC
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
  servlet:
    multipart:
      max-file-size: -1
      max-request-size: -1
app:
  name: AviDrive
  jwt:
    secret: your-secret-key-change-in-production-min-32-chars
    expiration: 86400000
server:
  port: 8080
```

**config.txt:**
```
storage_path=./storage
backend_port=8080
frontend_port=3000
ssl_enabled=false
ssl_cert_path=
ssl_key_path=
global_quota_mb=0
```

---

## 📝 ПРАВИЛА ДЛЯ AI-АГЕНТА

1. **📜 ИСТОРИЯ:** Создай `docs/history.md`. Обновляй после каждого шага (Дата, Шаг, Что сделано, Файлы, Статус ✅/🔄/❌).

2. **🔄 КОММИТЫ:** После каждого шага:
   ```bash
   git add .
   git commit -m "feat: Шаг X - [название]\n\n- [описание 1]\n- [описание 2]"
   git push
   ```
   От имени **Avizero**. НЕ ПРОПУСКАЙ.

3. **⚠️ ПОШАГОВАЯ РАБОТА:** Делай ОДИН шаг за раз. Жди подтверждения. НЕ пиши весь код сразу.

4. **КАЧЕСТВО:** Чистый код, комментарии, обработка ошибок, SOLID, DRY. DTO вместо Entity в контроллерах, `@ControllerAdvice`.

5. **FRONTEND:** Адаптивный, современный CSS, переиспользуемые компоненты, HTTP+HTTPS.

6. **ОТЛАДОЧНЫЕ BAT (run-backend.bat, run-frontend.bat):** Только для отладки на Windows. Два отдельных процесса. Кодировка UTF-8. Проверка зависимостей.

7. **START.SH — ПОЛНОЦЕННЫЙ ДЕПЛОЙ:** Только root, БЕЗ sudo. Автоустановка зависимостей. Мастер 9 шагов. UFW настраивается с правилами, но **НЕ включается автоматически** — только вручную. SSL через certbot. Systemd сервисы. Проверки после установки.

8. **MODE СКРИПТЫ:** НАПРЯМУЮ с SQLite через `sqlite3`. ЗАПРЕЩЕНО обращаться к HTTP API. Валидация username `^[a-zA-Z0-9_]{3,20}$`. Экранирование кавычек `'` → `''`.

9. **ЗАЩИТА:** SQL (только JPA), Path Traversal (normalize+startsWith), Zip Slip (проверка entry), XSS (нет dangerouslySetInnerHTML), Command Injection (валидация username), Rate Limiting (10/5мин), JWT (секрет 32+ символа).

10. **АУТЕНТИФИКАЦИЯ ПО USERNAME:** латиница+цифры+_, 3-20 символов, не начинается с цифры.

11. **МАТРИЦА ПРАВ:** ADMIN > MODERATOR > USER. Серые кнопки с tooltip.

12. **БЕЗГРАНИЧНЫЙ ДОСТУП:** ADMIN/MODERATOR имеют полные права над файлами подчиненных.

13. **ПРАВА В JSON** с наследованием и приоритетом (редактирование → просмотр).

14. **ПУБЛИЧНЫЕ ССЫЛКИ — НЕСКОЛЬКО К ОДНОМУ ФАЙЛУ** с независимыми квотами, редактированием, статистикой, лимитами.

15. **ЗАГРУЗКА БЕЗ ЛИМИТА РАЗМЕРА** — только квота.

16. **СМЕНА ПАРОЛЯ:** все пользователи через профиль. ADMIN/MODERATOR сбрасывают подчиненным.

17. **ГЛОБАЛЬНАЯ КВОТА:** `0` = без лимита. При достижении — блокировка + сообщение.

18. **ОБЩИЕ ПАПКИ:** квота у владельца, индивидуальные лимиты участников.

19. **УДАЛЕНИЕ МГНОВЕННОЕ** — без корзины.

20. **НЕЗАВЕРШЁННЫЕ ЗАГРУЗКИ:** битые файлы удаляются с сервера. Для папок — только недогруженные, успешные остаются.

21. **ПРОГРЕСС-БАР:** текущий файл, общий прогресс, скорость, оставшееся время, пауза/отмена.

22. **ЗАГРУЗКА ПАПОК:** структура сохраняется, папки в текущей директории, параллельно 3-5 файлов.

23. **СКАЧИВАНИЕ:** файлы как файлы, папки как ZIP (DEFLATE).

24. **UFW:** правила добавляются, но НЕ включается автоматически.

---

## ✅ КРИТЕРИИ ГОТОВНОСТИ

- [ ] Название "AviDrive" на всех страницах
- [ ] Тёмная/светлая тема с переключателем и сохранением
- [ ] Аутентификация по username (латиница+цифры+_, 3-20 символов)
- [ ] Placeholder "Введите логин" на странице входа
- [ ] Три роли: ADMIN, MODERATOR, USER
- [ ] Матрица прав работает (ADMIN/MOD/USER)
- [ ] Серые кнопки с tooltip "Недостаточно прав"
- [ ] Безграничный доступ ADMIN/MODERATOR к файлам подчиненных
- [ ] Sidebar сворачивается
- [ ] Загрузка ЛЮБЫХ файлов с заголовками безопасности
- [ ] Отдельная кнопка "Загрузить папку", скрыта у файлов
- [ ] При загрузке папки структура сохраняется полностью
- [ ] Папки создаются в текущей директории
- [ ] Информативный прогресс-бар (текущий файл, прогресс %, скорость, оставшееся время)
- [ ] Кнопки "Пауза" и "Отменить" во время загрузки
- [ ] Параллельная загрузка 3-5 файлов
- [ ] Незавершённые загрузки удаляются с сервера (только битые файлы)
- [ ] Проверка квоты (пользователя + глобальной) ДО загрузки
- [ ] Глобальная квота + прогресс-бар в панелях
- [ ] Блокировка при превышении + сообщение "На сервере закончилось пространство, пожалуйста обратитесь к Администратору"
- [ ] Файлы скачиваются как файлы, папки как ZIP (DEFLATE)
- [ ] Структура папок внутри ZIP сохраняется
- [ ] Удаление мгновенное — без корзины
- [ ] Медиаплеер: скорость, полный экран, Range requests, БЕЗ транскодинга
- [ ] Office файлы — только скачивание
- [ ] Срок ссылки через календарь (дата+время)
- [ ] Редактирование ссылок после создания
- [ ] Права ссылок работают реально
- [ ] Лимиты для ссылок (max_file_size, max_total_size)
- [ ] Несколько ссылок к одному файлу
- [ ] Статистика ссылок (view/download/upload count)
- [ ] Общие папки: создание любым пользователем
- [ ] Визуальное выделение общих папок + владелец
- [ ] Квота общих папок у владельца
- [ ] Индивидуальные лимиты участников (видны только при upload:true)
- [ ] Админ-панель: управление сервисом + список пользователей
- [ ] Поиск пользователей по нику (живой)
- [ ] Таблица: Ник | Должность | Статус | кнопка "Управление"
- [ ] Модальное окно управления пользователем
- [ ] Боковая панель слева в модальном окне (Файлы, Редакт., Пароль, Удалить)
- [ ] Сворачивание боковой панели до иконок с tooltip
- [ ] Масштабирование модального окна
- [ ] Поиск по файлам с фильтрами
- [ ] Массовые операции (чекбоксы, ZIP, перемещение)
- [ ] Уведомления о квоте (80/90/95/100%)
- [ ] Сортировка и фильтрация файлов
- [ ] Drag & Drop между папками и из ОС
- [ ] Превью/миниатюры (изображения, видео, PDF)
- [ ] Горячие клавиши (Delete, F2, Ctrl+A, Escape, Ctrl+F)
- [ ] Анимации (модалки, загрузка, skeleton)
- [ ] Контекстное меню (правый клик)
- [ ] Breadcrumbs навигация
- [ ] Пагинация (50-100 файлов)
- [ ] Кэширование + оптимистичные обновления
- [ ] Обработка ошибок (Error Boundary, понятные сообщения, retry)
- [ ] Безопасность (SQL, Path Traversal, Zip Slip, XSS, Rate Limiting, JWT)
- [ ] Все API защищены с проверкой ролей и матрицы прав
- [ ] `docs/history.md` содержит полную историю
- [ ] Каждый шаг закоммичен в GitHub от имени Avizero
- [ ] `mode.bat` и `mode.sh` работают (прямое редактирование SQLite, смена паролей ЛЮБЫМ пользователям)
- [ ] `run-backend.bat` и `run-frontend.bat` работают (отдельный запуск backend и frontend на Windows, UTF-8)
- [ ] `Start.sh` работает (проверка зависимостей, автоустановка, мастер настройки, UFW с правилами но без включения, SSL, systemd, проверки)
- [ ] Start.sh работает от root без sudo
- [ ] UFW настроен с правилами, но НЕ включён автоматически
- [ ] SSL сертификат получен автоматически через Let's Encrypt при наличии домена
- [ ] Start.sh обновляет README.md с командой установки
- [ ] Система работает по HTTP и HTTPS
- [ ] Везде `0` = без лимита
- [ ] Адаптивность: Sidebar → drawer на Mobile/Tablet
- [ ] Адаптивность: таблицы → карточки на Mobile/Tablet
- [ ] Адаптивность: модальные окна → full-screen на Mobile
- [ ] Адаптивность: контекстное меню → long press + bottom sheet на Mobile
- [ ] Адаптивность: свайпы по файлам (влево/вправо) на Mobile/Tablet
- [ ] Адаптивность: квота показывается в Header на всех устройствах
- [ ] Адаптивность: поиск сворачивается в иконку на Mobile
- [ ] Адаптивность: pinch-to-zoom для изображений
- [ ] Адаптивность: pull-to-refresh для списка файлов
- [ ] Адаптивность: touch-цели мин. 44x44px
- [ ] Адаптивность: модальное "Управление пользователем" → fullscreen + tabs на Mobile
---