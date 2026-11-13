# История шагов AviDrive

| Дата | Шаг | Что сделано | Файлы | Статус |
|---|---|---|---|---|
| 2026-11-13 | Подготовка проекта | Создан файл истории шагов; реализация шагов ТЗ ещё не начиналась. | `docs/history.md` | ✅ Готово |
| 2026-11-13 | 1. Каркас и layout | Создан Spring Boot backend с публичным `/api/health`, CORS allowlist и отключённой заглушкой security; создан React/Vite frontend с маршрутами, тёмной темой, App/Public/Auth layout, базовыми компонентами, login и 404. `mvn test` и `npm run build` успешны; ручной HTTP-запрос health не проверен. | `pom.xml`, `src/`, `frontend/`, `docs/history.md` | ✅ Готово (ограничение: API smoke-test не выполнен) |
