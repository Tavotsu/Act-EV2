# Proyecto Tienda de Perritos

Este repositorio contiene el código fuente y la configuración de infraestructura para el sistema web de gestión de productos. La solución está implementada mediante una arquitectura de tres capas (Frontend, Backend y Base de Datos) y diseñada para su despliegue automatizado en Amazon Web Services (AWS) utilizando Terraform y GitHub Actions.

## Tecnologías y Herramientas

* **Frontend:** HTML, CSS y JavaScript nativo, servido a través de Nginx.
* **Backend:** API REST desarrollada en Node.js con Express.
* **Base de Datos:** MySQL 8, configurada con scripts de inicialización de datos.
* **Contenedores:** Docker y Docker Compose.
* **Infraestructura como Código (IaC):** Terraform.
* **Integración y Despliegue Continuo (CI/CD):** GitHub Actions, Amazon ECR y AWS Systems Manager (SSM).

## Estructura del Repositorio

```text
.
├── .github/workflows/   # Definición de pipelines CI/CD (Frontend, Backend, DB)
├── backend/             # Código fuente de la API y Dockerfile asociado
├── db/                  # Scripts de inicialización SQL y Dockerfile de la base de datos
├── frontend/            # Archivos estáticos, configuración de Nginx y Dockerfile
├── terraform/           # Archivos de configuración de infraestructura en AWS
└── docker-compose.yml   # Archivo de orquestación para entornos de desarrollo local
Configuración del Entorno Local
Para ejecutar el proyecto en un entorno de desarrollo local, se requiere tener instalados Docker y Docker Compose.

Clonar el repositorio en el equipo local.

Posicionarse en el directorio raíz del proyecto.

Ejecutar el siguiente comando para construir y levantar los servicios en segundo plano:

docker-compose up -d --build

Puntos de acceso locales:

Frontend: http://localhost:80

Backend: http://localhost:3001

Arquitectura de Infraestructura en AWS
El aprovisionamiento de la infraestructura mediante Terraform establece el siguiente esquema de red y seguridad:

VPC: Creación de una red virtual aislada (CIDR 10.0.0.0/16).

Subred Pública: Destinada a la instancia EC2 del Frontend, permitiendo acceso desde internet a través de un Internet Gateway.

Subredes Privadas: Destinadas a las instancias del Backend y la Base de Datos, aisladas de conexiones externas directas.

Grupos de Seguridad (Security Groups): Implementación de reglas restrictivas donde la base de datos únicamente acepta conexiones provenientes de la capa de aplicación, y la aplicación únicamente recibe tráfico de la capa web.

Pipelines de Despliegue (CI/CD)
El repositorio cuenta con flujos de trabajo independientes para cada capa. Al registrar cambios en la rama main, se ejecutan las siguientes acciones de forma automatizada:

Construcción: Generación de la nueva imagen Docker correspondiente al servicio modificado.

Registro: Publicación de la imagen en el repositorio de Amazon ECR.

Despliegue: Ejecución remota de comandos en las instancias EC2 objetivo utilizando AWS SSM. Este proceso detiene el contenedor obsoleto, descarga la nueva imagen y reinicia el servicio sin requerir exposición de puertos SSH.
