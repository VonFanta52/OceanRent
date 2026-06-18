# OceanRent - Gestión de Alquiler de Barcos

OceanRent es una aplicación desarrollada en **Flutter** para la gestión de alquiler de barcos.  
El proyecto permite gestionar reservas, usuarios, barcos, comunicación entre cliente y administrador, reseñas y otros elementos relacionados con el proceso de alquiler.

Este proyecto ha sido desarrollado como parte de mi formación y experiencia práctica en desarrollo de aplicaciones multiplataforma.

---

## Descripción del proyecto

La aplicación está pensada para digitalizar y facilitar la gestión de una empresa de alquiler de embarcaciones, ofreciendo una experiencia sencilla tanto para el cliente como para el administrador.

El usuario puede consultar barcos disponibles, realizar reservas, revisar información relacionada con sus alquileres y comunicarse mediante un sistema de chat.  
Por otro lado, el administrador puede gestionar reservas, usuarios, barcos y atender las conversaciones relacionadas con cada alquiler.

---

## Funcionalidades principales

- Registro e inicio de sesión de usuarios.
- Gestión de perfil de usuario.
- Visualización de barcos disponibles.
- Gestión de reservas de embarcaciones.
- Sistema de chat entre cliente y administrador.
- Asociación de conversaciones a reservas concretas.
- Gestión de reseñas.
- Gestión de licencias y documentación.
- Gestión de fianzas.
- Panel de administración para controlar reservas y usuarios.
- Finalización de conversaciones en el chat.
- Interfaz adaptada a dispositivos móviles.

---

## Tecnologías utilizadas

- **Flutter**
- **Dart**
- **Riverpod** para la gestión de estado
- **Git y GitHub** para control de versiones
- Arquitectura organizada por capas
- Separación entre interfaz, lógica de negocio, servicios y providers

---

## Estructura general del proyecto

```bash
lib/
├── main.dart
├── models/
├── screens/
├── widgets/
├── providers/
├── services/
├── routes/
└── utils/
