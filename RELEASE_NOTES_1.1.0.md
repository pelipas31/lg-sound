# LG Sound 1.1.0

## English

- Add hardware display brightness sliders to the menu bar popover and controls window.
- Read back actual monitor brightness after each adjustment. Report unsupported brightness or limits imposed by monitor modes.
- Keep volume and brightness writes independently debounced on the same serial DDC queue.
- Poll brightness alongside volume and include it in local diagnostics.
- Add English and Russian labels and troubleshooting instructions.

Verified on LG 52G930B / M3 Pro over USB-C / DisplayPort: the new window slider changed brightness from 100 to 95 and back to 100; hardware reads confirmed it, while volume stayed at 21. Both sliders work without Accessibility access. This release does not intercept brightness keys.

**Updating:** replace the app in `/Applications`. If volume keys or the knob stop responding, remove LG Sound from Accessibility, add the current `/Applications/LG Sound.app` again, and enable it. Ad-hoc signed builds may lose the old grant after an update. The app is not notarized by Apple.

## Русский

- Добавлен ползунок аппаратной яркости в меню и отдельном окне управления.
- После изменения считывается фактическая яркость монитора. При неподдерживаемой яркости или ограничениях режима показывается сообщение.
- Громкость и яркость отправляются независимо, с ограничением частоты команд и общей последовательной очередью DDC.
- Яркость считывается вместе с громкостью и включается в локальную диагностику.
- Добавлены русские и английские подписи и инструкции.

Проверено на LG 52G930B / M3 Pro по USB-C / DisplayPort: новый ползунок изменил яркость 100 → 95 → 100, значения подтверждены чтением из монитора. Громкость оставалась 21. Для обоих ползунков «Универсальный доступ» не нужен. Клавиши яркости в этой версии не перехватываются.

**Обновление:** замени приложение в `/Applications`. Если перестали работать клавиши громкости или крутилка, удали LG Sound из «Универсального доступа», заново добавь актуальный `/Applications/LG Sound.app` и включи доступ. Локальная ad-hoc подпись может приводить к потере разрешения после обновления. Нотарификации Apple пока нет.
