# Proyecto Final DevOps — API de Tareas (estudiante10)

Despliegue contenedorizado de la API de tareas en Flask junto con PostgreSQL para el perfil estudiante10 en el servidor 178.128.14.98 (puerto publicado 8010:5000), con analisis DevSecOps (seguridad.sh) y monitoreo en monitoreo.log.

## Arquitectura y aislamiento
- Proyecto Compose: name: estudiante10
- Contenedores: est10_db (PostgreSQL con volumen persistente, sin publicar puertos 54XX) y est10_api (puerto 8010:5000)
- Archivos excluidos de Git: .env, reportes/, monitoreo.log

## Comandos Linux en orden
1. ssh estudiante10@178.128.14.98
2. cd ~/estudiante10 && mkdir -p devops-final
3. git clone [https://github.com/JGomez-git21/devops-final.git](https://github.com/JGomez-git21/devops-final.git) && cd devops-final
4. cp .env.example .env && nano .env
5. docker ps -a && docker compose up -d --build
6. docker compose ls && docker volume ls | grep estudiante10
7. chmod +x seguridad.sh && ./seguridad.sh
8. curl [http://178.128.14.98:8010/health](http://178.128.14.98:8010/health)
9. ./seguridad.sh monitorear && tail -n 30 monitoreo.log
10. git log --oneline --graph

## Enlace final
[http://178.128.14.98:8010/health](http://178.128.14.98:8010/health)
