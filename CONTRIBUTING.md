# Cómo contribuir a PSPS Academy

## Ramas

| Rama | Uso |
| --- | --- |
| `main` | Línea estable. Solo recibe merges revisados desde `develop` (o correcciones urgentes). |
| `develop` | Integración del Sprint 3. Base de todo trabajo nuevo. |
| `feature/<id>-<tema>` | Funcionalidades (p. ej. `feature/CU-11-...`). |
| `refactor/<tema>` | Reorganización técnica sin cambio de comportamiento. |
| `fix/<id>-<tema>` | Correcciones de defectos. |
| `test/<tema>` | Pruebas. |
| `docs/<tema>` | Documentación. |

Crea tu rama desde `develop` actualizado y abre un Pull Request hacia `develop`.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `ci:`, `build:`. Mensajes cortos y en imperativo; commits pequeños y con un solo propósito.

```text
feat(cu11): add ...
fix(cu09): keep ñ when normalizing queries
test: preserve progress and rewards behavior
```

No uses `git push --force` sobre ramas compartidas.

## Antes de abrir un PR

```bash
flutter pub get
dart format <archivos que modificaste>
flutter analyze        # sin incidencias
flutter test           # todas aprobadas
```

El workflow de GitHub Actions (`.github/workflows/flutter-ci.yml`) repite análisis y pruebas.

## Reglas del proyecto

- **No cambies** el nombre del paquete `psps`, el `applicationId` `mx.edu.uaz.psps`, la clave `psps.progress.v1` ni los IDs del catálogo sin un plan de migración de datos y pruebas: los usuarios perderían su avance.
- Respeta las capas de [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): `core` no importa `app` ni `features`.
- Las consultas no escriben estado; las recompensas se otorgan una sola vez (G-01).
- No elimines ni debilites pruebas para obtener resultados verdes; si cambia un comportamiento aprobado, actualiza la prueba y [docs/USE_CASES.md](docs/USE_CASES.md) en el mismo PR.
- No subas APK, claves de firma ni archivos `local.properties`/`key.properties`.
- Actualiza `CHANGELOG.md` en la sección *Sin publicar*.
