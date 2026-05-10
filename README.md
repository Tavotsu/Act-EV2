# Proyecto DevOps: Despachos y Ventas - Innovatech Chile

Este repositorio contiene la implementacion tecnica de la Evaluacion Parcial N 2 para la asignatura de Introduccion a Herramientas DevOps. En este proyecto se aplica contenedorizacion avanzada, orquestacion, infraestructura como codigo (IaC) y automatizacion CI/CD utilizando practicas y herramientas estandar de la industria (Docker, GitHub Actions, AWS ECR, EC2, Terraform).

---

## Arquitectura del Sistema (3-Tier) y Justificacion Tecnica

La infraestructura en AWS fue provisionada definiendo una arquitectura de tres capas (3-Tier). Esta decision fue tomada basandose en los siguientes requisitos no funcionales:

- **Seguridad**: Se establecio una separacion estricta de subredes. La Base de Datos (Capa de Datos) y los microservicios (Capa de Aplicacion) se ubican en subredes privadas sin acceso directo a internet. Solo el Frontend (Capa Web) posee una IP publica, actuando como un escudo (Reverse Proxy) que aisla los sistemas criticos de posibles ataques directos externos.
- **Rendimiento y Escalabilidad**: Al separar el Frontend, el Backend y la Base de Datos en distintas maquinas EC2, se asegura que los picos de trafico web no afecten el rendimiento de la ejecucion de la logica de negocios o consultas SQL. Ademas, esta modularidad permite escalar vertical u horizontalmente cada capa de manera independiente segun su propia demanda de recursos.
- **Mantenibilidad**: La division en 3 capas facilita la actualizacion independiente de cada servicio sin causar caidas generalizadas (downtime).

---

## Contenedorizacion de Microservicios

El sistema consta de 3 microservicios, cada uno con su propio Dockerfile optimizado siguiendo las mejores practicas:

### 1. Frontend (React/Vite)
- **Multi-stage build**: Se utiliza Node en la primera etapa (build) para compilar los assets estaticos, desechando despues el entorno de desarrollo. Esto reduce drasticamente el tamano de la imagen final y minimiza la superficie de ataque.
- **Usuario no root**: Se utiliza la imagen base `nginxinc/nginx-unprivileged:alpine`, la cual ejecuta el servidor web con privilegios limitados.
- **Reverse Proxy**: Nginx esta configurado con plantillas dinamicas para inyectar por variable de entorno la IP privada del Backend, enrutando el trafico de la API de forma segura.

### 2. Backends (Ventas y Despachos - Spring Boot)
- **Multi-stage build**: Se utiliza Maven para compilar el codigo (`mvn clean package`) y un JRE ultra ligero (`eclipse-temurin:17-jre-alpine`) exclusivamente para la ejecucion del `.jar`.
- **Optimizacion de capas**: El codigo fuente se copia despues de descargar las dependencias del `pom.xml`, permitiendo aprovechar la cache de Docker en caso de que solo haya cambios en el codigo, acelerando considerablemente el proceso de build.
- **Usuario no root**: Se creo un grupo y usuario explicito (`spring:spring`) para ejecutar el proceso `.jar`, cumpliendo con el principio de minimo privilegio.

---

## Orquestacion Local (docker-compose.yml)

Para el entorno de desarrollo y pruebas en maquinas locales, se provee un archivo `docker-compose.yml`:
- **Servicios definidos**: `frontend`, `backend-ventas`, `backend-despachos`, y `db`.
- **Redes internas**: Todo convive en una red tipo bridge (`app_network`). Los backends no exponen puertos al host local, simulando el comportamiento de las subredes privadas de AWS.
- **Persistencia de datos**: Se configura el volumen nombrado `db_data` asociado al directorio interno de MySQL, garantizando que la informacion y los esquemas persistian incluso si el contenedor es destruido.

---

## Pipeline CI/CD (GitHub Actions) e Impacto en el Negocio

La entrega continua esta automatizada estructurando la solucion en multiples workflows independientes. Cada vez que se hace un push a la rama **deploy**, se despliegan de forma selectiva solo los componentes que detectan modificaciones en sus archivos fuente.

**Flujo del Pipeline Automatizado**:
1. **Configuracion y Login**: El Action asume las credenciales de la cuenta AWS e inicia sesion de forma segura en **Amazon ECR**.
2. **Build y Push**: Compila localmente las imagenes Docker y las registra en los repositorios privados de AWS.
3. **Despliegue automatizado seguro**: A traves de **AWS Systems Manager (SSM)**, GitHub Actions envia los comandos de despliegue (`docker pull` y `docker run`) hacia las instancias EC2. Esto evita el uso de llaves SSH, cerrando por completo el puerto 22 a conexiones externas.
4. **Gestion de Secrets**: Contrasenas y direcciones IP internas de la VPC jamas se escriben en el codigo; son inyectadas on-the-fly desde los secretos nativos del repositorio de GitHub.

### Importancia para Innovatech Chile
Esta automatizacion es **critica** para la continuidad operativa de la empresa. Elimina la intervencion humana en las puestas a produccion, reduciendo el margen de error, estandarizando los procesos de entrega y asegurando un ciclo de vida del software agil. Con este pipeline, cualquier correccion de fallos o nueva caracteristica llega al usuario final en cuestion de minutos y con absoluta trazabilidad, sentando las bases para el crecimiento futuro del entorno productivo empresarial.
