# Preparación del Sprint 3

Estado de partida: `0.2.0+5`, CU-01 a CU-10 implementados y probados (ver [MIGRATION_REPORT.md](MIGRATION_REPORT.md)). Trabajo en `develop`.

## 1. Verificaciones pendientes de la migración (prioridad alta)

- [ ] Ejecutar `tool/verify_sprint2_android.ps1` con cada destino de `integration_test/` en un dispositivo Android (sin red) y guardar las evidencias.
- [ ] Probar la actualización de una instalación previa (APK de Sprint 2) por el APK de este repositorio **sin desinstalar**; confirmar que se conservan respuestas, actividades, puntos, logros y tema.
- [ ] Reiniciar el sistema Android y comprobar que el tema y el progreso persisten.
- [ ] Repetir en dispositivo H-01 y D-S1-03, cuyas evidencias previas en APK código 4 fallaron (ver auditoría).
- [ ] Verificar la primera ejecución del workflow de CI en GitHub.

## 2. Decisiones de producto abiertas

- **RP-01:** ¿un catálogo, módulo o tema vacío es error de publicación o estado válido? Hoy se admite (`DS101-04`, `CP05-12`).
- **L-10 heredado:** un estado v3 que contenga el logro retirado `L-10` hace fallar la carga (riesgo R-06). Decidir política de conciliación antes de publicar a usuarios con datos antiguos.
- Recuperar el documento primario de casos de uso del Sprint 2 y MR-09 para cerrar contratos de CU-07…CU-10.

## 3. Plataformas

### iOS
- Requiere macOS + Xcode + CocoaPods + equipo de firma.
- Pasos: `flutter build ios --no-codesign`, revisar `ios/Runner/Info.plist` (nombre, versión), ícono, `shared_preferences_foundation`, pruebas `integration_test` en simulador.
- Código Dart: no usa APIs específicas de Android; `tool/*.ps1` sí son exclusivos de Android/Windows.

### HarmonyOS NEXT
- El SDK oficial de Flutter no tiene destino HarmonyOS NEXT. Evaluar el SDK Flutter de la comunidad OpenHarmony (y su soporte de `shared_preferences`) o un port alternativo antes de comprometer alcance.
- Lo específico de Android que habrá que reemplazar: `android/` (Gradle, `MainActivity.kt`, manifiestos, íconos), scripts `tool/*.ps1`/`.bat`, `applicationId`.
- Lo portable: todo `lib/`, salvo el *plugin* de persistencia, que debe tener implementación en la plataforma destino.

## 4. Deuda técnica sugerida (sin cambio funcional)

- Dividir `lib/app/app.dart` (≈1 200 líneas, *library* con `part`) en pantallas por funcionalidad con API pública mínima; requiere pruebas de navegación previas.
- Extraer widgets compartidos (`StatusBadge`, `ScreenFrame`) a `lib/shared/` cuando se divida la *library*.
- Unificar o documentar las dos validaciones de catálogo (`catalog_validation.dart` y `catalog_identity_validation.dart`).
- Configurar firma *release* propia (hoy usa la clave *debug*).
- Actualizar dependencias (`flutter pub outdated` muestra 9 paquetes con versiones más nuevas) en una rama dedicada.
- Normalizar finales de línea con `.gitattributes`.
- Aplicar `dart format` a los 7 archivos heredados sin formato (`lib/core/content/catalog_validation.dart`, 5 pruebas `test/cu09_*`/`test/fix_*`, `integration_test/cu06_logros_offline_test.dart`) y activar la verificación de formato en CI.

## 5. Nuevos casos de uso

CU-11 y CU-12: crear `feature/CU-11-...` desde `develop`, añadir la funcionalidad en `lib/features/<nombre>/`, registrar reglas en [USE_CASES.md](USE_CASES.md) y pruebas en `test/`. Ver «Cómo añadir un caso de uso» en [ARCHITECTURE.md](ARCHITECTURE.md).
