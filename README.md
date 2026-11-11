# Gym

App de iOS sencilla y minimalista para apuntar tus entrenos.

## Qué hace

- **Calendario**: tocas un día y eliges la rutina (si la rutina tiene día asignado, te sale como "Te toca hoy").
- **Rutinas**: creas o editas tus rutinas (Lunes · Pecho, Martes · Espalda…), con máquina, series y reps de cada ejercicio. La app viene con las rutinas de tu nota precargadas.
- **Ejercicio a ejercicio**: en cada ejercicio apuntas tus series (peso en kg + reps). Arriba ves **lo que hiciste la última vez** y un consejo para mejorar (p. ej. "Completaste todas las reps. Sube a 42.5 kg").
- **Marcar como hecho**: como en tu nota, cada ejercicio tiene su círculo para marcarlo.
- **Racha** 🔥: días seguidos entrenando, más cuántos llevas esta semana, este mes y tu mejor racha. Puedes ajustar cuántos días de descanso se permiten sin perder la racha (por defecto 2, así el fin de semana no la rompe). Toca la tarjeta de la racha para cambiarlo.
- Todo se guarda en el iPhone con **SwiftData** (base de datos local, sin cuentas ni internet).

## Cómo abrirla y ponerla en tu iPhone

Necesitas un Mac con **Xcode 16 o más nuevo** (gratis en la App Store). La app pide iOS 17 o superior.

1. Clona el repo y abre `GymLog.xcodeproj` en Xcode.
2. Selecciona el proyecto **GymLog** → target **GymLog** → pestaña **Signing & Capabilities**:
   - En **Team** elige tu Apple ID (con una cuenta gratuita vale).
   - Si da error de identificador, cambia **Bundle Identifier** por uno tuyo, p. ej. `com.tunombre.gym`.
3. Conecta el iPhone por cable, elígelo arriba como destino y pulsa ▶︎ (Run).
4. La primera vez, en el iPhone ve a *Ajustes → General → VPN y gestión de dispositivos* y confía en tu certificado de desarrollador. Si te lo pide, activa también el *Modo desarrollador*.

> Con una cuenta gratuita de Apple la app caduca a los 7 días y hay que volver a pulsar Run desde Xcode (tus datos no se pierden). Con la cuenta de desarrollador de pago dura 1 año, o puedes usar TestFlight.

## Estructura

| Archivo | Qué hay |
|---|---|
| `GymLog/Models.swift` | Modelos de la base de datos: `Routine`, `RoutineExercise`, `Workout`, `ExerciseLog`, `SetLog` |
| `GymLog/Logic.swift` | Cálculo de la racha y consejos de progresión |
| `GymLog/SeedData.swift` | Rutinas iniciales (las de tu nota) |
| `GymLog/HomeView.swift` | Pantalla principal: racha + calendario |
| `GymLog/DayView.swift` | Elegir rutina para un día |
| `GymLog/WorkoutView.swift` | Lista de ejercicios del entreno |
| `GymLog/ExerciseLogView.swift` | Series de un ejercicio + "última vez" |
| `GymLog/RoutinesView.swift` | Crear y editar rutinas |
| `GymLog/ExerciseFormView.swift` | Formulario de ejercicio |
