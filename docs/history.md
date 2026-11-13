# История шагов AviDrive

| Дата | Шаг | Что сделано | Файлы | Статус |
|---|---|---|---|---|
| 2026-11-13 | Подготовка проекта | Создан файл истории шагов; реализация шагов ТЗ ещё не начиналась. | `docs/history.md` | ✅ Готово |
| 2026-11-13 | 1. Каркас и layout | Создан Spring Boot backend с публичным `/api/health`, CORS allowlist и отключённой заглушкой security; создан React/Vite frontend с маршрутами, тёмной темой, App/Public/Auth layout, базовыми компонентами, login и 404. `mvn test` и `npm run build` успешны; ручной HTTP-запрос health не проверен. | `pom.xml`, `src/`, `frontend/`, `docs/history.md` | ✅ Готово (ограничение: API smoke-test не выполнен) |
| 2026-11-13 | 2. БД и сущности | Добавлена SQLite-схема с идемпотентным применением, WAL/FK, UTC и дефолтами settings; добавлены JPA-сущности и репозитории всех таблиц; `/api/health` возвращает `db` и `schema_version`. `mvn test` ✅. | `pom.xml`, `src/main/resources/application.yml`, `src/main/resources/schema.sql`, `src/main/java/com/avizero/avidrive/domain/`, `src/main/java/com/avizero/avidrive/repository/`, `docs/history.md` | ✅ Готово |
