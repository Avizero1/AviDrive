# AviDrive

Файловое хранилище с контролем доступа, общими папками и публичными ссылками. Автор: **Avizero**.

## Стек

- Backend: Java 17, Spring Boot 3, Spring Security, Spring Data JPA, SQLite, Maven.
- Frontend: React 18, Vite, React Router, Axios.
- Хранилище: SQLite для метаданных и файловая система для содержимого.

## Быстрый запуск на Windows

Требования: Java 17+, Maven, Node.js/npm и `sqlite3` в `PATH`.

1. Запустите backend отдельным процессом:

   ```bat
   run-backend.bat
   ```

2. Запустите frontend в другом окне:

   ```bat
   run-frontend.bat
   ```

3. Откройте `http://localhost:3000`.

## Установка на Debian/Ubuntu

Установка выполняется от `root` без `sudo`:

```bash
chmod +x Start.sh mode.sh
./Start.sh
```

Мастер настройки запрашивает backend/frontend-порты, домен, SSL и путь хранилища. Скрипт устанавливает зависимости, собирает приложение, создаёт systemd-сервисы и добавляет правила UFW.

> UFW намеренно **не включается автоматически**. После проверки установки включите его вручную: `ufw enable`.

Лог установки: `/var/log` не используется — `Start.sh` сохраняет `setup.log` в каталоге проекта.

## Режимные SQLite-скрипты

Скрипты работают напрямую с SQLite, без HTTP API. Перед запуском требуется `sqlite3`.

```bash
./mode.sh init-schema
./mode.sh list-users
./mode.sh set-password username '<bcrypt-hash>'
./mode.sh block username
./mode.sh unblock username
./mode.sh delete-user username
```

Windows-аналог:

```bat
mode.bat init-schema
mode.bat list-users
mode.bat set-password username "<bcrypt-hash>"
```

Username: латинские буквы, цифры и `_`, 3–20 символов, первый символ не цифра. Значение квоты `0` означает отсутствие лимита.

## API

Основные группы endpoint-ов:

- `/api/auth` — вход, выход, профиль и смена пароля;
- `/api/files` — файловый менеджер;
- `/api/permissions` и `/api/share` — права и публичные ссылки;
- `/api/shared/folders` — общие папки;
- `/api/search` — поиск;
- `/api/users` — управление пользователями.

## Git

Каждый этап разработки фиксируется отдельным коммитом от имени Avizero и отправляется в `origin/main`. Полная история находится в [docs/history.md](docs/history.md).

© 2026 AviDrive by Avizero
