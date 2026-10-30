# LG Sound 1.0.0

## English

First public release: a small macOS menu bar utility for LG ULTRAGEAR+ speaker volume over USB-C / DisplayPort.

- Volume slider and percentage, mute/restore, standard media keys and compatible keyboard knobs.
- Keys target LG only when it is the default audio output.
- Optional launch at login, connection checks, English/Russian interface.
- Custom monitor-and-speaker app icon.
- MIT licensed; includes m1ddc and its license.

**Download:** `LG-Sound-1.0.0-arm64.zip`. Apple Silicon only; macOS 13+ build target. Tested hardware: LG 52G930B, M3 Pro, USB-C / DisplayPort, Keychron knob. Other monitors/connections are unverified. The core volume/knob behavior was verified before this packaging and localization update; the release package was built and its signature checked.

This build is ad-hoc signed, not Apple-notarized. See the README for installation. Media keys need Accessibility access. After replacing/rebuilding the app, remove the old Accessibility entry and add the current application again if the switch is on but keys do nothing.

`SHA256SUMS.txt` contains the archive checksum. The native macOS volume slider remains unavailable; use LG Sound’s slider or media keys.

## Русский

Первый публичный релиз: небольшая утилита в строке меню macOS для громкости LG ULTRAGEAR+ по USB-C / DisplayPort.

- Ползунок и процент громкости, mute и восстановление уровня, медиаклавиши и совместимые крутилки.
- Клавиши управляют LG, только когда он выбран аудиовыходом.
- Необязательный автозапуск, проверки подключения, русский и английский интерфейс.
- Иконка монитора с динамиком.
- Лицензия MIT, m1ddc включён вместе с его лицензией.

**Скачать:** `LG-Sound-1.0.0-arm64.zip`. Только Apple Silicon; целевая версия macOS — 13+. Проверенная связка: LG 52G930B, M3 Pro, USB-C / DisplayPort, крутилка Keychron. Другие мониторы и подключения не проверены. Управление громкостью и крутилкой проверено до обновления оформления и локализации; у релизного пакета проверены сборка и подпись.

Сборка имеет локальную ad-hoc подпись и не нотарифицирована Apple. Установка описана в README. Для медиаклавиш нужен «Универсальный доступ». Если после замены/пересборки приложения переключатель включён, а клавиши не работают, удали старую запись и добавь актуальное приложение заново.

Контрольная сумма архива — в `SHA256SUMS.txt`. Штатный ползунок macOS остаётся недоступным; используй ползунок LG Sound или медиаклавиши.
