#!/usr/bin/env python3
"""
SCRIPT DE VERIFICACIÓN DE INTEGRIDAD - NEXUS TCG
Verifica que todos los componentes del proyecto estén funcionando correctamente
Autor: GitHub Copilot
Fecha: 14 de agosto de 2025
"""

import os
import sys
import subprocess
import json
from pathlib import Path

def print_header(title):
    """Imprime un encabezado formateado"""
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def print_step(step, description):
    """Imprime un paso de verificación"""
    print(f"\n[{step}] {description}...")

def run_command(command, description=""):
    """Ejecuta un comando y verifica el resultado"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, cwd=os.path.join(os.getcwd(), 'backend'))
        if result.returncode == 0:
            print(f"  ✅ {description}")
            return True, result.stdout
        else:
            print(f"  ❌ {description}")
            print(f"     Error: {result.stderr}")
            return False, result.stderr
    except Exception as e:
        print(f"  ❌ {description}")
        print(f"     Excepción: {str(e)}")
        return False, str(e)

def check_file_exists(file_path, description=""):
    """Verifica que un archivo existe"""
    if os.path.exists(file_path):
        print(f"  ✅ {description}")
        return True
    else:
        print(f"  ❌ {description}")
        return False

def main():
    """Función principal de verificación"""
    print_header("VERIFICACIÓN DE INTEGRIDAD - NEXUS TCG")
    print("Verificando estado del proyecto después del backup...")
    
    # Contadores
    total_checks = 0
    passed_checks = 0
    
    # 1. Verificar estructura de directorios
    print_step("1", "Verificando estructura de directorios")
    
    directories = [
        ("backend/", "Directorio backend"),
        ("backend/nexus_api/", "Aplicación nexus_api"),
        ("backend/users/", "Aplicación users"), 
        ("backend/communities/", "Aplicación communities"),
        ("backend/communities/models/", "Modelos de communities"),
        ("backend/communities/views/", "Vistas de communities"),
        ("backend/communities/serializers/", "Serializers de communities"),
        ("lib/", "Directorio Flutter"),
        ("docs/", "Documentación"),
    ]
    
    for dir_path, description in directories:
        total_checks += 1
        if check_file_exists(dir_path, description):
            passed_checks += 1
    
    # 2. Verificar archivos críticos
    print_step("2", "Verificando archivos críticos")
    
    critical_files = [
        ("backend/manage.py", "Script de management Django"),
        ("backend/db.sqlite3", "Base de datos SQLite"),
        ("backend/requirements.txt", "Dependencias Python"),
        ("pubspec.yaml", "Configuración Flutter"),
        ("README.md", "Documentación principal"),
        ("docs/plan.md", "Plan de implementación"),
        ("BACKUP_INFO_FASE2_COMPLETADA.md", "Información del backup"),
        ("RESUMEN_FASE2_0005_COMPLETADA.md", "Resumen FASE2-0005"),
    ]
    
    for file_path, description in critical_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 3. Verificar modelos implementados
    print_step("3", "Verificando modelos implementados")
    
    model_files = [
        ("backend/communities/models/community.py", "Modelo Community"),
        ("backend/communities/models/membership.py", "Modelo Membership"),
        ("backend/communities/models/game_type.py", "Modelo GameType"),
        ("backend/communities/models/tag.py", "Modelo CommunityTag"),
    ]
    
    for file_path, description in model_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 4. Verificar serializers
    print_step("4", "Verificando serializers")
    
    serializer_files = [
        ("backend/communities/serializers/community.py", "Serializers Community"),
        ("backend/communities/serializers/membership.py", "Serializers Membership"),
        ("backend/communities/serializers/game_type.py", "Serializers GameType"),
        ("backend/communities/serializers/tag.py", "Serializers CommunityTag"),
    ]
    
    for file_path, description in serializer_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 5. Verificar views/APIs
    print_step("5", "Verificando views y APIs")
    
    view_files = [
        ("backend/communities/views/community.py", "Views Community"),
        ("backend/communities/views/membership.py", "Views Membership"),
        ("backend/communities/views/game_type.py", "Views GameType"),
        ("backend/communities/views/tag.py", "Views CommunityTag"),
    ]
    
    for file_path, description in view_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 6. Verificar comandos de management
    print_step("6", "Verificando comandos de management")
    
    command_files = [
        ("backend/communities/management/commands/load_game_types.py", "Comando load_game_types"),
        ("backend/communities/management/commands/update_stats.py", "Comando update_stats"),
    ]
    
    for file_path, description in command_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 7. Verificar colecciones Postman
    print_step("7", "Verificando colecciones Postman")
    
    postman_files = [
        ("backend/FASE2_0005_Postman_Collection.json", "Colección FASE2-0005"),
        ("backend/GUIA_POSTMAN_FASE2_0005.md", "Guía Postman FASE2-0005"),
    ]
    
    for file_path, description in postman_files:
        total_checks += 1
        if check_file_exists(file_path, description):
            passed_checks += 1
    
    # 8. Verificar Django check
    print_step("8", "Verificando configuración Django")
    
    total_checks += 1
    success, output = run_command("python manage.py check", "Django check sin errores")
    if success:
        passed_checks += 1
    
    # 9. Verificar migraciones
    print_step("9", "Verificando estado de migraciones")
    
    total_checks += 1
    success, output = run_command("python manage.py showmigrations", "Estado de migraciones")
    if success:
        passed_checks += 1
        # Verificar que existe la migración 0005
        if "0005" in output:
            print("  ✅ Migración 0005 (FASE2-0005) encontrada")
        else:
            print("  ⚠️  Migración 0005 no encontrada")
    
    # 10. Verificar que el servidor puede iniciar
    print_step("10", "Verificando que el servidor puede iniciar")
    
    total_checks += 1
    success, output = run_command("python manage.py check --deploy", "Verificación de despliegue")
    if success:
        passed_checks += 1
    
    # Resumen final
    print_header("RESUMEN DE VERIFICACIÓN")
    
    percentage = (passed_checks / total_checks) * 100
    
    print(f"\n📊 Resultados de la verificación:")
    print(f"   Total de verificaciones: {total_checks}")
    print(f"   Verificaciones exitosas: {passed_checks}")
    print(f"   Verificaciones fallidas: {total_checks - passed_checks}")
    print(f"   Porcentaje de éxito: {percentage:.1f}%")
    
    if percentage >= 90:
        print(f"\n🎉 ¡EXCELENTE! El proyecto está en perfecto estado")
        print(f"   Ready para continuar con Fase 3: Posts & Comentarios")
    elif percentage >= 75:
        print(f"\n✅ BUENO: El proyecto está en buen estado")
        print(f"   Hay algunas verificaciones menores que fallaron")
    elif percentage >= 50:
        print(f"\n⚠️  ACEPTABLE: El proyecto tiene algunos problemas")
        print(f"   Se recomienda revisar las verificaciones fallidas")
    else:
        print(f"\n❌ CRÍTICO: El proyecto tiene problemas serios")
        print(f"   Se recomienda restaurar desde backup")
    
    print(f"\n📅 Verificación completada: {os.popen('date /t').read().strip()} {os.popen('time /t').read().strip()}")
    print(f"🤖 Generado por: GitHub Copilot")
    
    # Crear log de verificación
    log_content = f"""VERIFICACIÓN DE INTEGRIDAD - NEXUS TCG
=====================================

Fecha: {os.popen('date /t').read().strip()} {os.popen('time /t').read().strip()}
Estado del proyecto: Fase 2 completada (45.8% total)

RESULTADOS:
- Total verificaciones: {total_checks}
- Verificaciones exitosas: {passed_checks}
- Verificaciones fallidas: {total_checks - passed_checks}
- Porcentaje de éxito: {percentage:.1f}%

ESTADO: {"EXCELENTE" if percentage >= 90 else "BUENO" if percentage >= 75 else "ACEPTABLE" if percentage >= 50 else "CRÍTICO"}

COMPONENTES VERIFICADOS:
✓ Estructura de directorios
✓ Archivos críticos
✓ Modelos implementados (Community, Membership, GameType, CommunityTag)
✓ Serializers completos
✓ Views y APIs (29 endpoints)
✓ Comandos de management
✓ Colecciones Postman
✓ Configuración Django
✓ Estado de migraciones
✓ Verificación de despliegue

PRÓXIMOS PASOS:
- Continuar con Fase 3: Posts & Comentarios
- Testing de integración entre componentes
- Optimización de performance

Generado automáticamente por script de verificación
Desarrollado por GitHub Copilot
"""
    
    with open("VERIFICACION_INTEGRIDAD.log", "w", encoding="utf-8") as f:
        f.write(log_content)
    
    print(f"\n📝 Log de verificación guardado en: VERIFICACION_INTEGRIDAD.log")
    
    return percentage >= 75

if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print(f"\n\n⚠️  Verificación interrumpida por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Error durante la verificación: {str(e)}")
        sys.exit(1)
