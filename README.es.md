# Plantilla de scripts de flujo Git y gestión de versiones

Este proyecto proporciona una plantilla reutilizable de scripts en Bash para gestionar flujos de desarrollo Git compatibles con Git Flow, control de versiones semánticas y generación automatizada de changelogs.

## Requisitos
- Git
- Make
- Bash 4+
- Herramientas específicas según el tipo de proyecto (ej: `maven`, `npm`, `composer`)

## Estructura
- `.make/runnable/`: contiene los scripts ejecutables.
- `run.sh`: punto de entrada que carga funciones según el tipo de proyecto definido en `properties.env`.

## Configuración
Edita el archivo `properties.env` con los siguientes valores mínimos:

```env
MAIN_BRANCH=main
DEVELOP_BRANCH=develop
KIND=maven            # o npm, composer, etc.
AUTO_PUSH=false       # true para subir ramas automáticamente
FEATURE_USE_VERSION_PREFIX=true
CHANGELOG_INCLUDE_BODY=true
```

## Comandos Make disponibles

### Crear nueva funcionalidad (feature)
```bash
make start-feature-nombre_de_la_feature
```
Crea una nueva rama `feature/1.2.3-nombre_de_la_feature` desde `develop`, usando la versión actual como prefijo si está habilitado.

### Finalizar funcionalidad
```bash
make finish-feature-nombre_de_la_feature
```
Fusiona la rama de feature en `develop`, elimina la rama local y remota (si AUTO_PUSH es true).

### Crear release candidate
```bash
make start-rc
```
Detecta el tipo de incremento desde los commits (`feat`, `fix`, etc.), genera la siguiente versión candidata, crea una rama `release/x.y.z-rc.n`, actualiza la versión y genera el changelog.

### Regenerar changelog completo
```bash
make generate-changelog
```
Reconstruye el archivo `CHANGELOG.md` desde cero usando los tags alcanzables desde `main`, agrupando los cambios por versión.

## Personalización
Puedes ampliar los scripts para soportar más tipos de proyecto creando archivos como `.make/kind/maven.sh`, `.make/kind/npm.sh`, etc., y definiendo las funciones `get_version`, `set_version`, etc.

## Licencia
Plantilla de uso interno. Puedes adaptarla a tus propios proyectos libremente.