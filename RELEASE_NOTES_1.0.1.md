# LG Sound 1.0.1

## English

- Add a volume window that opens on first launch and when the app is reopened from Finder. A hidden menu icon no longer leaves the slider unreachable.
- Give the menu item a stable autosave name and request visibility on launch/reopen.
- Adopt the public bundle identifier `io.github.pelipas31.LGSound` and complete application metadata.
- Add menu icon state to local diagnostics.

Validated on the development Mac: the icon returned after installing the new identity in `/Applications`; the window slider changed real LG volume from 12 to 7 and back to 12. The exact cause of the old macOS visibility block remains uncertain. Build and signature checks pass.

**Update:** quit the old app and install this copy in `/Applications`. Remove the old Accessibility entry and add the new app to restore media keys/knob access. Re-enable optional launch at login if necessary. The community build remains ad-hoc signed and not notarized.

## Русский

- Добавлено окно громкости: открывается при первом запуске и повторном открытии приложения из Finder. Ползунок доступен даже при скрытом значке.
- Элемент строки меню получил постоянное имя; при запуске и повторном открытии запрашивается его показ.
- Публичный идентификатор приложения: `io.github.pelipas31.LGSound`; дополнены метаданные приложения.
- В локальную диагностику добавлено состояние значка.

На Mac разработчика значок вернулся после установки новой записи приложения в `/Applications`. Проверено управление реальной громкостью LG ползунком: 12 → 7 → 12. Точная причина старой блокировки со стороны macOS не установлена. Сборка и подпись проверены.

**Обновление:** выйди из старой копии и установи новую в `/Applications`. Удали старую запись «Универсального доступа» и добавь актуальное приложение для клавиш и крутилки. При необходимости заново включи автозапуск. Сборка по-прежнему с локальной ad-hoc подписью, без нотарификации Apple.
