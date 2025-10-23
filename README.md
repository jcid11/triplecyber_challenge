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

Cada sala (roomId) representa una llamada activa entre dos usuarios.
Dentro se guardan las ofertas (SDP), respuestas y candidatos de red (ICE) necesarios para establecer la conexión P2P.
