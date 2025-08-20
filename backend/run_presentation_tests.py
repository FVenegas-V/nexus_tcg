"""
Ejecutor Simple de Pruebas con pytest
Para generar evidencia rápida de presentación
"""

import os
import subprocess
from datetime import datetime

# Configurar entorno
os.environ['DJANGO_SETTINGS_MODULE'] = 'nexus_api.settings'
python_path = "C:/Users/Pipe/Proyectos/nexus_tcg/venv/Scripts/python.exe"

def run_test(test_file, report_name, description):
    """Ejecuta una prueba específica y genera reporte"""
    print(f"\n{'='*60}")
    print(f"🧪 {description}")
    print(f"{'='*60}")
    
    cmd = [
        python_path, "-m", "pytest", 
        test_file, 
        "-v", 
        f"--html=test_reports/{report_name}.html", 
        "--self-contained-html",
        "--tb=short"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, env=os.environ)
        print("RESULTADO:")
        print(result.stdout)
        if result.stderr:
            print("WARNINGS:")
            print(result.stderr)
        return result.returncode == 0
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print(f"""
╔════════════════════════════════════════════════════════════════╗
║                  PRUEBAS NEXUS TCG - PYTEST                   ║
║                  {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}                      ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    # Crear directorio de reportes
    os.makedirs("test_reports", exist_ok=True)
    
    tests = [
        ("communities/test_reactions.py", "reactions_test", "Sistema de Reacciones"),
        ("communities/test_posts.py", "posts_test", "Sistema de Posts"), 
        ("communities/test_comments.py", "comments_test", "Sistema de Comentarios")
    ]
    
    results = []
    
    for test_file, report_name, description in tests:
        success = run_test(test_file, report_name, description)
        results.append((description, success))
        print(f"✅ {description}: {'EXITOSO' if success else 'CON ERRORES'}")
    
    print(f"""
╔════════════════════════════════════════════════════════════════╗
║                        RESUMEN FINAL                          ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    for description, success in results:
        status = "✅ EXITOSO" if success else "❌ CON ERRORES"
        print(f"  {description}: {status}")
    
    print(f"""
📁 Reportes generados en: test_reports/
   • reactions_test.html
   • posts_test.html  
   • comments_test.html
""")

if __name__ == "__main__":
    main()
