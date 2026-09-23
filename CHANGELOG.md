## [2026-09-23] - Tiempo de escucha correcto y canciones en el dispositivo solo con suscripcion

### Corregido
- **Tiempo de escucha (casete).** Se mide por pista y solo mientras suena
  (reproduciendo y listo). Una pista que avanza sola cierra y guarda su
  ventana: antes solo pausa/salto/stop guardaban, y un album escuchado de
  corrido contaba solo su ultima pista. Una pista repetida ya no arrastra cada
  minuto desde que sono por primera vez. Una ventana abierta como invitado
  nunca se guarda, cada ventana tiene su propio id de documento, y la primera
  sesion de cada arranque ya no se descarta.
- **La cache de canciones completas es solo para suscriptores.**
  `LockCachingAudioSource` descarga la cancion entera y no se detiene al
  saltarla. Sin suscripcion se transmite por rangos (`AudioCachePolicy`), y el
  interruptor de cache solo aparece con suscripcion.
- **La cache tenia tamano ilimitado.** `AudioCacheStore` la mantiene bajo
  500 MB borrando primero lo que lleva mas tiempo sin escucharse, y nunca toca
  una descarga en curso. Nueva opcion "Canciones guardadas en el dispositivo"
  con su tamano y boton para borrarlas.
- **Al arrancar se cargaban dos canciones.** La ultima cola se carga directo
  en la posicion guardada en vez de cargar la primera y luego buscar.
- Etiquetas Me gusta/Ya no me gusta de la notificacion y "N/D" traducidas con
  `AudioPlayerTranslationConstants`.

### Pruebas
- `casete_listen_clock_test` (7), `audio_cache_policy_test` (7),
  `audio_cache_store_test` (6), validadas con mutacion. 361 pruebas.

## [2026-07-25] - Dependencias Externas
- Actualizacion de dependencias externas a sus versiones mas recientes y compatibles.


## [2.0.0-unreleased] - 2026-07-21
- Fix permanent lockup in stop(), resolve duplicate EqualizerController/Service naming conflicts by renaming to AudioPlayerEqualizerController, resolve RangeError in updateMediaItem, fix dismissible keys collision in queue widget, and hook setVolume callback in artwork slider.
# Changelog — neom_audio_player

## [2.1.2] - 2026-07-16
- Update miniplayer, bottom player, queue panel, and Winamp-style floating widgets.
- Fix audio handler mapping.

## Unreleased - System updates
- Actualizaciones de estabilidad y compatibilidad.

## 2026-03-14
- Add `isActive` implementation to `MiniPlayerController`
- Fix car mode player layout and controls
- Fix jam session widget responsive layout
- Fix listening stats card layout
- Fix web now playing full view
