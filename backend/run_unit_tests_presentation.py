#!/usr/bin/env python
"""
Script para ejecutar pruebas unitarias con formato similar a pytest
para capturas de presentación.
"""
import subprocess
import sys
from datetime import datetime

def main():
    print("=" * 80)
    print("🧪 NEXUS TCG - PRUEBAS UNITARIAS COMPLETAS")
    print("=" * 80)
    print(f"Fecha: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print(f"Framework: Django TestCase + pytest-style output")
    print("=" * 80)
    print()
    
    # Ejecutar pruebas con Django test runner
    print("🔄 Ejecutando todas las pruebas unitarias...")
    print()
    
    try:
        result = subprocess.run([
            'python', 'manage.py', 'test', 'communities', '--verbosity=2'
        ], capture_output=False, text=True)
        
        print()
        print("=" * 80)
        if result.returncode == 0:
            print("✅ TODAS LAS PRUEBAS COMPLETADAS EXITOSAMENTE")
        else:
            print("⚠️ ALGUNAS PRUEBAS NECESITAN ATENCION")
        print("=" * 80)
        
    except Exception as e:
        print(f"❌ Error ejecutando pruebas: {e}")

if __name__ == "__main__":
    main()
