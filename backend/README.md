# Backend local de consulta de DNI

Servicio intermediario de TiendasMass. Flutter le consulta el DNI y este proceso llama a API Perú. El token no entra en la aplicación.

Este servidor escucha solo en `127.0.0.1`. No está preparado para publicarse en Internet: antes harían falta HTTPS, autenticación del cliente, App Check o un control equivalente, y una protección de abuso persistente. No usa túneles ni Firebase Cloud Functions.

MassBot atiende `POST /api/chat` con su propia clave. No reutiliza el token ni el contrato de la consulta de DNI. El modo predeterminado es simulado.

## Entorno comprobado

- Node.js 24.19.0
- npm 11.17.0
- Puerto inicial: `3000` en `127.0.0.1`
- No se instalan dependencias. El servidor usa solo módulos nativos de Node.js.

## Configurar

En PowerShell, desde la carpeta del proyecto:

```powershell
cd D:\Proyectos\Tienda-Mas-main\backend
Copy-Item .env.example .env
```

`.env` queda fuera de Git. El archivo de ejemplo no contiene secretos. No compartas el token real por el chat.

Variables:

| Variable | Uso |
|---|---|
| `DNI_MODE` | `mock` o `live`. Si se omite, el modo es `mock`. |
| `PORT` | Puerto local. El valor inicial es `3000`. |
| `HOST` | Solo se acepta `127.0.0.1`. |
| `APISPERU_TOKEN` | Token del proveedor. Vacío en modo simulado. |
| `CHAT_MODE` | `mock` o `live`. Si se omite, MassBot queda en `mock`. No cambia `DNI_MODE`. |
| `GEMINI_API_KEY` | Clave de Gemini. Vacía en modo simulado. No es el token de API Perú. |
| `GEMINI_MODEL` | Modelo de Gemini. El inicial es `gemini-3.5-flash-lite`. |
| `FIREBASE_PROJECT_ID` | Proyecto de Firestore para la lectura comercial en modo live. |
| `FIREBASE_WEB_API_KEY` | Clave web que ya usa la aplicación. No otorga permisos de administrador. |

## MassBot

`POST /api/chat` atiende al asistente. En `CHAT_MODE=mock` usa un catálogo ficticio, no llama a Gemini y marca `simulado: true`. En `live` interpreta la pregunta con Gemini y lee `productos_mass`, `tiendas_mass` y `cupones_mass`. Si falta la clave o Firestore rechaza la lectura, responde un error y no inventa precios.

La clave de Gemini se envía solo desde este proceso, en el encabezado `x-goog-api-key`. No la pongas en Flutter ni en este ejemplo.

Para ensayar sin servicios externos:

```powershell
cd D:\Proyectos\Tienda-Mas-main\backend
$env:CHAT_MODE='mock'
node src/server.js
```

El modo real se activa después, cuando el propietario escriba la clave en `.env` y cambie `CHAT_MODE=live`. No hace falta un plan de pago para preparar el código. No actives facturación de Gemini desde este repositorio.


## Iniciar

```powershell
cd D:\Proyectos\Tienda-Mas-main\backend
node src/server.js
```

La consola muestra la dirección y el modo. En modo `mock` no se contacta a API Perú.

## Detener

En la misma ventana de PowerShell, presiona `Ctrl+C`.

## Comprobar el estado

Con el servidor iniciado, en otra ventana:

```powershell
Invoke-RestMethod http://127.0.0.1:3000/api/health
```

La respuesta esperada es `ok = True`. No incluye el modo, el token ni datos personales.

## Ejecutar las pruebas

No inicies el servidor antes: las pruebas usan puertos efímeros y no consultan DNI reales.

```powershell
cd D:\Proyectos\Tienda-Mas-main\backend
node --test
```

También puedes usar `npm test`. No hace falta `npm install`.

## Conectar el emulador Android

El servidor sigue limitado a la computadora. El emulador llega a esa dirección mediante `10.0.2.2`, que Android reserva para el `127.0.0.1` del equipo anfitrión. No abre el puerto a la red local.

La aplicación solo permite HTTP hacia `10.0.2.2`, `127.0.0.1` y `localhost` en compilaciones de depuración. La compilación de publicación no incluye ese permiso.

En una terminal, con el backend ya iniciado:

```powershell
cd D:\Proyectos\Tienda-Mas-main
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Si `10.0.2.2` no respondiera, se puede crear un puente sin cambiar el servidor:

```powershell
adb reverse tcp:3000 tcp:3000
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

`API_BASE_URL` es solo la dirección del intermediario. No es un secreto y no debe contener el token.

## Datos simulados

El modo predeterminado responde con nombres ficticios y marca `simulado: true`. La pantalla lo indica antes de usar el nombre. El DNI `00000000` responde que no existe, para probar ese caso. Cualquier otro DNI de ocho dígitos devuelve una persona ficticia. Esos datos no provienen de API Perú.

## Activar el modo real más adelante

1. Detén el servidor.
2. Edita `backend/.env` en tu computadora.
3. Cambia `DNI_MODE=live`.
4. Escribe el token en `APISPERU_TOKEN`.
5. Guarda el archivo y vuelve a ejecutar `node src/server.js`.

Si el modo es `live` y el token está vacío, la consulta responde que no está configurada. No inventa un resultado simulado. No envíes ese token por el chat de Cursor.

El proveedor documentado es `GET https://dniruc.apisperu.com/api/v1/dni/{numero}?token={TOKEN}`. El número viaja como texto de ocho dígitos para conservar los ceros iniciales.
