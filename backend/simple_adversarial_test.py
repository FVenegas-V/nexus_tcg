"""
Test simple para verificar el sistema anti-gaming
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import UserRating, AntiAbuseConfig
from users.anti_gaming import AntiGamingDetector

User = get_user_model()

def run_simple_test():
    """Ejecuta un test simple del sistema anti-gaming"""
    
    print("🧪 TEST SIMPLE DEL SISTEMA ANTI-GAMING")
    print("=" * 50)
    
    # 1. Verificar configuración
    try:
        config = AntiAbuseConfig.objects.get(key='gaming_detection')
        print(f"✅ Configuración encontrada: {config.value}")
    except AntiAbuseConfig.DoesNotExist:
        print("❌ Configuración no encontrada")
        return
    
    # 2. Crear usuarios de prueba
    try:
        # Limpiar usuarios de prueba anteriores
        User.objects.filter(username__startswith='test_adv_').delete()
        
        attacker = User.objects.create_user(
            username='test_adv_attacker',
            email='attacker@test.com',
            password='test123'
        )
        
        victims = []
        for i in range(5):
            victim = User.objects.create_user(
                username=f'test_adv_victim_{i}',
                email=f'victim{i}@test.com',
                password='test123'
            )
            victims.append(victim)
        
        print(f"✅ Usuarios creados: 1 atacante + {len(victims)} víctimas")
        
    except Exception as e:
        print(f"❌ Error creando usuarios: {e}")
        return
    
    # 3. Simular ataque de sesgo de 5 estrellas
    print("\n🎯 SIMULANDO ATAQUE DE SESGO DE 5 ESTRELLAS")
    print("-" * 40)
    
    detector = AntiGamingDetector()
    flags_detectados = 0
    
    for i, victim in enumerate(victims):
        # Crear valoración de 5 estrellas
        rating = UserRating.objects.create(
            rater=attacker,
            rated_user=victim,
            rating=5,
            interaction_type='trade',
            comment=f'Perfect trader #{i+1}!'
        )
        
        # Analizar con detector
        flags = detector.analyze_rating(rating)
        
        if flags:
            flags_detectados += 1
            for flag in flags:
                print(f"   🚩 Flag detectado: {flag['type']} (severidad: {flag['severity']})")
                print(f"      Mensaje: {flag['message']}")
        else:
            print(f"   ✅ Valoración {i+1}: Sin flags")
    
    print(f"\n📊 RESULTADOS:")
    print(f"   Valoraciones creadas: {len(victims)}")
    print(f"   Flags detectados: {flags_detectados}")
    
    # 4. Verificar que el sistema detecta el patrón
    if flags_detectados > 0:
        print("✅ SISTEMA FUNCIONANDO: Detectó patrones sospechosos")
        
        # Verificar tipos de flags
        final_rating = UserRating.objects.filter(rater=attacker).last()
        final_flags = detector.analyze_rating(final_rating)
        
        flag_types = [f['type'] for f in final_flags]
        print(f"\n🔍 TIPOS DE DETECCIÓN:")
        for flag_type in set(flag_types):
            print(f"   • {flag_type}")
        
    else:
        print("⚠️ POSIBLE PROBLEMA: No se detectaron patrones sospechosos")
        print("   Esto podría indicar que los umbrales están muy altos")
    
    # 5. Limpiar datos de prueba
    User.objects.filter(username__startswith='test_adv_').delete()
    print("\n🧹 Datos de prueba limpiados")
    
    print("\n🎉 TEST COMPLETADO")

if __name__ == '__main__':
    run_simple_test()
