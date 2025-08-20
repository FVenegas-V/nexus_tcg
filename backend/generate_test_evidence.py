"""
Script de Pruebas Completas con pytest
Nexus TCG - Evidencia para Presentación
Fecha: 19 de Agosto 2025
"""

import subprocess
import sys
import os
from datetime import datetime

# Configurar entorno Django
os.environ['DJANGO_SETTINGS_MODULE'] = 'nexus_api.settings'

def run_pytest_command(cmd, description, output_file=None):
    """Ejecuta un comando pytest y captura el resultado"""
    print(f"\n{'='*80}")
    print(f"🧪 {description}")
    print(f"{'='*80}")
    print(f"Comando: {cmd}")
    print(f"Hora: {datetime.now().strftime('%H:%M:%S')}")
    print("-" * 80)
    
    try:
        # Usar el python del entorno virtual
        python_path = "C:/Users/Pipe/Proyectos/nexus_tcg/venv/Scripts/python.exe"
        full_cmd = f'$env:DJANGO_SETTINGS_MODULE="nexus_api.settings"; {python_path} {cmd}'
        
        result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True, cwd=".")
        
        print("RESULTADO:")
        print(result.stdout)
        if result.stderr:
            print("ERRORES/WARNINGS:")
            print(result.stderr)
        print(f"Código de retorno: {result.returncode}")
        
        # Guardar resultado en archivo si se especifica
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(f"# {description}\n")
                f.write(f"Comando: {cmd}\n")
                f.write(f"Fecha: {datetime.now()}\n\n")
                f.write("## SALIDA:\n")
                f.write(result.stdout)
                if result.stderr:
                    f.write("\n## ERRORES/WARNINGS:\n")
                    f.write(result.stderr)
        
        return result
    except Exception as e:
        print(f"Error ejecutando comando: {e}")
        return None

def main():
    print(f"""
╔══════════════════════════════════════════════════════════════════════════════╗
║                     EVIDENCIA DE PRUEBAS - NEXUS TCG                        ║
║                     Sistema con pytest + Coverage                           ║
║                     Fecha: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
""")

    # Crear directorio de reportes si no existe
    os.makedirs("test_reports", exist_ok=True)
    os.makedirs("test_reports/evidence", exist_ok=True)

    # 1. PRUEBAS UNITARIAS - SISTEMA DE REACCIONES
    run_pytest_command(
        "-m pytest communities/test_reactions.py -v --html=test_reports/1_reactions_report.html --self-contained-html",
        "1. PRUEBAS UNITARIAS - Sistema de Reacciones",
        "test_reports/evidence/1_reactions_output.txt"
    )
    
    # 2. PRUEBAS UNITARIAS - SISTEMA DE POSTS  
    run_pytest_command(
        "-m pytest communities/test_posts.py -v --html=test_reports/2_posts_report.html --self-contained-html",
        "2. PRUEBAS UNITARIAS - Sistema de Posts",
        "test_reports/evidence/2_posts_output.txt"
    )
    
    # 3. PRUEBAS UNITARIAS - SISTEMA DE COMENTARIOS
    run_pytest_command(
        "-m pytest communities/test_comments.py -v --html=test_reports/3_comments_report.html --self-contained-html",
        "3. PRUEBAS UNITARIAS - Sistema de Comentarios", 
        "test_reports/evidence/3_comments_output.txt"
    )
    
    # 4. PRUEBAS COMPLETAS CON COBERTURA
    run_pytest_command(
        "-m pytest communities/ -v --cov=communities --cov-report=html:test_reports/coverage_html --cov-report=term --html=test_reports/4_full_coverage_report.html --self-contained-html",
        "4. PRUEBAS COMPLETAS + COBERTURA DE CÓDIGO",
        "test_reports/evidence/4_coverage_output.txt"
    )
    
    # 5. PRUEBAS DE PERFORMANCE (marcadas como @pytest.mark.slow)
    run_pytest_command(
        "-m pytest -m slow -v --html=test_reports/5_performance_report.html --self-contained-html",
        "5. PRUEBAS DE PERFORMANCE",
        "test_reports/evidence/5_performance_output.txt"
    )
    
    # 6. RESUMEN DE ESTADÍSTICAS
    run_pytest_command(
        "-m pytest communities/ --collect-only -q",
        "6. INVENTARIO DE PRUEBAS DISPONIBLES",
        "test_reports/evidence/6_test_inventory.txt"
    )

    print(f"""
╔══════════════════════════════════════════════════════════════════════════════╗
║                           EVIDENCIA GENERADA                                ║
║                                                                              ║
║  📁 test_reports/                                                            ║
║     ├── 1_reactions_report.html      (Pruebas Sistema Reacciones)           ║
║     ├── 2_posts_report.html          (Pruebas Sistema Posts)                ║
║     ├── 3_comments_report.html       (Pruebas Sistema Comentarios)          ║
║     ├── 4_full_coverage_report.html  (Reporte Completo + Cobertura)         ║
║     ├── 5_performance_report.html    (Pruebas de Performance)               ║
║     ├── coverage_html/               (Reporte HTML de Cobertura)             ║
║     └── evidence/                    (Archivos de texto para evidencia)     ║
║                                                                              ║
║  🎯 TIPOS DE PRUEBAS EJECUTADAS:                                             ║
║     ✅ Pruebas Unitarias (Models, Serializers, Utils)                       ║
║     ✅ Pruebas de APIs (REST Endpoints)                                      ║
║     ✅ Pruebas de Integración (Workflows completos)                         ║
║     ✅ Análisis de Cobertura de Código                                       ║
║     ✅ Validación de Performance                                             ║
║                                                                              ║
║  📊 HERRAMIENTAS UTILIZADAS:                                                 ║
║     • pytest: Framework profesional de testing                              ║
║     • pytest-django: Integración con Django                                 ║
║     • pytest-cov: Análisis de cobertura                                     ║
║     • pytest-html: Reportes HTML profesionales                              ║
║                                                                              ║
║  🚀 READY FOR PRESENTATION!                                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
""")

    print(f"\n📂 Para ver los reportes, abre:")
    print(f"   • test_reports/4_full_coverage_report.html")
    print(f"   • test_reports/coverage_html/index.html")
    print(f"\n📋 Archivos de evidencia en: test_reports/evidence/")

if __name__ == "__main__":
    main()
