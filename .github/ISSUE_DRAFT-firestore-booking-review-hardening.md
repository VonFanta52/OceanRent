# Hardening de reservas y resenas en Firestore

## Contexto

La app tiene reglas de Firestore y logica de cliente para reservas, locks de fechas y resenas. Hay varios puntos que pueden bloquear flujos legitimos o permitir actualizaciones demasiado amplias.

## Alcance

- Corregir la validacion de resenas para usar los nombres reales de campos (`user_id`, `booking_id`, `boat_id`).
- Restringir las actualizaciones de cancelacion de reservas hechas por clientes.
- Permitir a clientes crear reservas propias y locks de fechas asociados de forma validada.
- Evitar duplicados de resenas usando el `booking_id` como ID de documento.
- Sustituir el test de ejemplo de Flutter por tests utiles de modelos.

## Criterios de aceptacion

- `flutter analyze` pasa sin errores.
- `flutter test` pasa.
- Un cliente solo puede crear reservas para su propio `user_id`.
- Un cliente solo puede cancelar una reserva propia cambiando campos permitidos.
- Una resena solo puede crearse para una reserva confirmada del mismo usuario y barco.
- No se puede crear mas de una resena para la misma reserva.
