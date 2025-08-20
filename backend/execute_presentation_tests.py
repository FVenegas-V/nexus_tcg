#!/usr/bin/env python3
"""
Script para ejecutar pruebas de presentación de Nexus TCG
Genera reportes limpios para capturas de pantalla
"""
import subprocess
import sys
from datetime import datetime

def run_command(command, description):
    """Ejecuta un comando y retorna el resultado"""
    print(f"\n{'='*60}")
    print(f"PRUEBA: {description}")
    print(f"{'='*60}")
    print(f"Comando: {command}")
    print(f"Hora: {datetime.now().strftime('%H:%M:%S')}")
    print("-" * 60)
    
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True,
            encoding='utf-8',
            errors='ignore'  # Ignorar errores de codificación
        )
        
        if result.stdout:
            print("SALIDA:")
            print(result.stdout)
        
        if result.stderr:
            print("ADVERTENCIAS/ERRORES:")
            print(result.stderr)
            
        print(f"\nCodigo de retorno: {result.returncode}")
        return result.returncode == 0
        
    except Exception as e:
        print(f"ERROR ejecutando comando: {e}")
        return False

def main():
    """Función principal"""
    print("NEXUS TCG - PRUEBAS PARA PRESENTACION")
    print("="*60)
    print(f"Fecha y hora: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print("="*60)
    
    # Lista de pruebas a ejecutar
    tests = [
        ("python -m pytest communities/test_reactions.py -v", "Sistema de Reacciones"),
        ("python -m pytest communities/test_posts.py::PostModelTest -v", "Modelos de Posts"),
        ("python -m pytest communities/test_comments.py::CommentModelTest -v", "Modelos de Comentarios"),
        ("python -m pytest users/tests.py -v", "Sistema de Autenticacion"),
        ("python manage.py check", "Validacion de Sistema"),
    ]
    
    successful_tests = 0
    total_tests = len(tests)
    
    for command, description in tests:
        success = run_command(command, description)
        if success:
            successful_tests += 1
    
    # Resumen final
    print(f"\n{'='*60}")
    print("RESUMEN FINAL")
    print(f"{'='*60}")
    print(f"Pruebas exitosas: {successful_tests}/{total_tests}")
    print(f"Porcentaje de exito: {(successful_tests/total_tests)*100:.1f}%")
    
    if successful_tests == total_tests:
        print("TODAS LAS PRUEBAS PASARON!")
    else:
        print(f"Algunas pruebas requieren atencion.")
    
    print(f"\nReporte generado: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print("="*60)

if __name__ == "__main__":
    main()
