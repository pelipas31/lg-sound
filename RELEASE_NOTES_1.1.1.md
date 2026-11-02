# LG Sound 1.1.1

## English

Fix volume keys and knobs failing to resume after switching audio outputs or sleep.

- Observe default-output changes through CoreAudio, with a polling fallback, and recreate the event tap on route changes and wake.
- Check actual tap validity/enabled state every second; resume disabled taps or replace unresponsive ports.
- Keep CoreAudio and permission queries out of the media-event callback.
- Show real keyboard permission/connection state in the controls window. Add a manual Reconnect volume keys action.
- Sign this release with Developer ID and Hardened Runtime instead of a build-specific ad-hoc identity. This release is **not notarized**.

Verified on the development Mac: a real LG → MOONDROP Dawn Pro → LG switch reconnected the event tap without restarting the app; the user confirmed the physical Keychron knob worked afterwards. Seven automated recovery scenarios also pass. The original failure additionally showed an Accessibility code-requirement mismatch, so the signing migration addresses a separate cause from route recovery.

**One-time migration:** remove the old LG Sound Accessibility entry, add `/Applications/LG Sound.app`, and enable it. This is needed when moving from the old ad-hoc signature to Developer ID. Later updates using the same Developer ID and bundle identifier can retain the grant. Source and CI builds remain ad-hoc unless a signing identity is configured.

## Русский

Исправлено восстановление клавиш и крутилки после смены аудиовыхода и сна.

- Добавлен наблюдатель смены выхода CoreAudio с резервной проверкой таймером. При смене устройства и пробуждении перехват создаётся заново.
- Каждую секунду проверяется реальная работоспособность перехвата: отключённый включается, неработающий заменяется.
- Из обработки медиакоманд убраны синхронные запросы к CoreAudio и разрешениям.
- В окне отображается фактическое состояние доступа и подключения; добавлена команда «Переподключить клавиши».
- Релиз подписан постоянным Developer ID с Hardened Runtime вместо временной ad-hoc подписи. **Нотарификации пока нет.**

На реальном Mac проверен переход LG → MOONDROP Dawn Pro → LG: перехват восстановился без перезапуска приложения, пользователь подтвердил работу физической крутилки Keychron после возврата на монитор. Семь автоматических сценариев восстановления также прошли. Исходная диагностика дополнительно обнаружила несовпадение подписи в разрешении «Универсального доступа» — переход на Developer ID устраняет отдельную причину отказа.

**Разовый переход:** удали старую запись LG Sound из «Универсального доступа», добавь `/Applications/LG Sound.app` и включи доступ. Это нужно для замены временной подписи на Developer ID. Следующие обновления с тем же Developer ID и идентификатором приложения позволяют сохранять разрешение. Сборки из исходников и CI остаются ad-hoc, если сертификат не настроен.
