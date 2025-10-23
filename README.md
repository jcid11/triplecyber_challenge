# triplecyber_challenge

## Objetivo del proyecto

Implementar un flujo completo de videollamada entre dos usuarios, demostrando dominio de:

- 🧱 Arquitectura limpia y separación por capas (UI / Bloc / Repositorios)
- 🔄 Manejo de estado con **Bloc**
- 🎥 Comunicación en tiempo real con **WebRTC**
- ☁️ Integración con **Firebase Firestore** para señalización
- 🧹 Manejo correcto de recursos, permisos y teardown de conexión

## ⚙️ 1. Instrucciones de configuración e instalación

Asegúrate de tener instalado en tu equipo:

- Flutter SDK 3.29.0
- Cuenta de Firebase
- Un dispositivo físico o dos emuladores Android (recomendado al menos un dispositivo real)
- Conexión a Internet

## 🔸 2. Clonar el repositorio

git clone https://github.com/jcid11/triplecyber_challenge.git

## 3. Configuración de Firebase

Este proyecto utiliza Firebase Firestore para el intercambio de señalización (ofertas, respuestas e ICE candidates).

### Estructura esperada en firebase

```text
rooms/
 └── {roomId}/
      ├── offer
      ├── answer
      ├── callerCandidates/
      └── calleeCandidates/
```

Cada sala (roomId) representa una llamada activa entre dos usuarios.
Dentro se guardan las ofertas (SDP), respuestas y candidatos de red (ICE) necesarios para establecer la conexión P2P.

## 🔸 4. Permisos requeridos (Android)

Verifica que estos permisos estén definidos en android/app/src/main/AndroidManifest.xml:

```text
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```
## 5. Flujo de la aplicación

- Usuario A (Caller) crea la sala → se genera un offer (SDP) en Firestore.
- Usuario B (Callee) ingresa el ID de la sala → obtiene el offer y genera un answer.
- Ambos intercambian ICE candidates en Firestore para encontrar la mejor ruta de conexión.
- Una vez que ambos tienen offer, answer y candidates, se establece una conexión WebRTC P2P directa.
- Audio y video fluyen entre dispositivos sin pasar por Firebase.
- Cuando uno de los usuarios finaliza la llamada:
- Se cierra la conexión (RTCPeerConnection)
- Se eliminan las referencias en Firestore
- Se limpian los recursos locales (renderers, streams, subscriptions)
