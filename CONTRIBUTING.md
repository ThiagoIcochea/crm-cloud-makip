# Cómo trabajar en este repositorio

## Flujo

1. Toma una tarea del backlog (`docs/backlog.md`) o crea un *issue*.
2. Crea una rama: `feat/<tema>`, `fix/<tema>`, `infra/<tema>` o `docs/<tema>`.
3. Commits pequeños y descriptivos en español.
4. Abre un Pull Request hacia `main` con la plantilla; otro integrante lo revisa.
5. El CI debe pasar (Terraform, Gitleaks, tests de API, validación de la landing).
6. Los despliegues se lanzan desde **Actions → Deploy**.

## Reglas

- Nunca subir secretos, `.env`, `terraform.tfvars` ni llaves JSON (Gitleaks lo bloquea).
- No modificar en consola recursos administrados por Terraform; si ocurre por un incidente, documentarlo y reconciliar el estado.
- Solo datos ficticios o anonimizados en pruebas, capturas y seeds.
- Configurar antes que programar en Odoo; cualquier módulo en `app/addons/` requiere un ADR.
- Toda salida generada con IA se revisa y prueba antes del merge.

## Roles sugeridos

| Rol | Carpetas |
|---|---|
| Arquitectura / IaC | `infra/`, `.github/workflows/` |
| CRM / procesos | `app/`, `docs/pipeline-estados.md` |
| Frontend / integración | `web/`, `api/` |
| Data / QA / observabilidad | `analytics/`, `docs/medicion/`, `scripts/` |
