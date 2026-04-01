#tallermecanico

Aplicación Flutter para la gestión de servicios del Taller Mecánico de Agropecuaria El Avión.
Incluye escaneo de choferes y unidades, generación de folios, registro de servicios, almacenamiento local con SQLite e impresión de tickets mediante BlueThermalPrinter.

#Getting Started

Este proyecto está diseñado para ejecutarse en dispositivos de campo (como el Honeywell EDA5), permitiendo registrar servicios mecánicos incluso sin conexión a internet.

#Características principales

-Escaneo de códigos de chofer y económico con Honeywell Scanner.
-Generación automática de folios HHR y control de servicios.
-Impresión de tickets con BlueThermalPrinter.
-Pantallas optimizadas para lectura rápida, uso rudo y accesibilidad.

#Estructura del proyecto

-/models → Modelos de datos (Chofer, Económico, Folios, etc.)
-/services → Servicios de API REST y lógica de sincronización
-/interfaces → Pantallas principales (Servicio, Registro, Folios, etc.)
-/utils → Funciones de apoyo, helpers, formatos, etc.

#Recursos útiles
Lab: Write your first Flutter app
Cookbook: Useful Flutter samples
Para más información sobre Flutter, revisa la documentación oficial, que ofrece tutoriales, ejemplos, guías y toda la referencia del API.
