"""
Management command para ejecutar tests adversariales simples
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from users.models import UserRating, AntiAbuseConfig
from users.anti_gaming import AntiGamingDetector

User = get_user_model()

class Command(BaseCommand):
    help = 'Ejecuta tests adversariales simples del sistema anti-gaming'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🧪 TEST SIMPLE DEL SISTEMA ANTI-GAMING'))
        self.stdout.write('=' * 50)
        
        # 1. Verificar configuración
        try:
            config = AntiAbuseConfig.objects.get(key='gaming_detection')
            self.stdout.write(f"✅ Configuración encontrada: {config.value}")
        except AntiAbuseConfig.DoesNotExist:
            self.stdout.write("❌ Configuración no encontrada")
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
            
            self.stdout.write(f"✅ Usuarios creados: 1 atacante + {len(victims)} víctimas")
            
        except Exception as e:
            self.stdout.write(f"❌ Error creando usuarios: {e}")
            return
        
        # 3. Simular ataque de sesgo de 5 estrellas
        self.stdout.write("\n🎯 SIMULANDO ATAQUE DE SESGO DE 5 ESTRELLAS")
        self.stdout.write("-" * 40)
        
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
                    self.stdout.write(f"   🚩 Flag detectado: {flag['type']} (severidad: {flag['severity']})")
                    self.stdout.write(f"      Mensaje: {flag['message']}")
            else:
                self.stdout.write(f"   ✅ Valoración {i+1}: Sin flags")
        
        self.stdout.write(f"\n📊 RESULTADOS:")
        self.stdout.write(f"   Valoraciones creadas: {len(victims)}")
        self.stdout.write(f"   Flags detectados: {flags_detectados}")
        
        # 4. Verificar que el sistema detecta el patrón
        if flags_detectados > 0:
            self.stdout.write("✅ SISTEMA FUNCIONANDO: Detectó patrones sospechosos")
            
            # Verificar tipos de flags
            final_rating = UserRating.objects.filter(rater=attacker).last()
            final_flags = detector.analyze_rating(final_rating)
            
            flag_types = [f['type'] for f in final_flags]
            self.stdout.write(f"\n🔍 TIPOS DE DETECCIÓN:")
            for flag_type in set(flag_types):
                self.stdout.write(f"   • {flag_type}")
            
        else:
            self.stdout.write("⚠️ POSIBLE PROBLEMA: No se detectaron patrones sospechosos")
            self.stdout.write("   Esto podría indicar que los umbrales están muy altos")
        
        # 5. Test de usuario legítimo
        self.stdout.write("\n🎯 PROBANDO USUARIO LEGÍTIMO")
        self.stdout.write("-" * 30)
        
        legit_user = User.objects.create_user(
            username='test_adv_legit',
            email='legit@test.com',
            password='test123'
        )
        
        # Usuario legítimo da valoraciones variadas
        ratings_legit = [4, 5, 3, 4, 5]
        falsos_positivos = 0
        
        for i, rating_value in enumerate(ratings_legit):
            rating = UserRating.objects.create(
                rater=legit_user,
                rated_user=victims[i],
                rating=rating_value,
                interaction_type='trade',
                comment=f'Trade #{i+1} - rating {rating_value}'
            )
            
            flags = detector.analyze_rating(rating)
            if flags:
                falsos_positivos += 1
                self.stdout.write(f"   ⚠️ Falso positivo en valoración {i+1}")
        
        if falsos_positivos == 0:
            self.stdout.write("✅ Sin falsos positivos en usuario legítimo")
        else:
            self.stdout.write(f"⚠️ {falsos_positivos} falsos positivos detectados")
        
        # 6. Limpiar datos de prueba
        User.objects.filter(username__startswith='test_adv_').delete()
        self.stdout.write("\n🧹 Datos de prueba limpiados")
        
        self.stdout.write(self.style.SUCCESS("\n🎉 TEST COMPLETADO"))
