"""
Script final de testing adversarial para verificar implementación
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from users.models import UserRating, AntiAbuseConfig, RatingFlag
from users.anti_gaming import AntiGamingDetector
from django.utils import timezone
from datetime import timedelta

User = get_user_model()

class Command(BaseCommand):
    help = 'Ejecuta batería completa de tests adversariales'

    def add_arguments(self, parser):
        parser.add_argument(
            '--quick',
            action='store_true',
            help='Ejecutar solo tests rápidos',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🧪 BATERÍA DE TESTS ADVERSARIALES'))
        self.stdout.write('=' * 60)
        
        quick_mode = options.get('quick', False)
        
        if quick_mode:
            self.stdout.write("⚡ Modo rápido activado")
        
        # Limpiar datos anteriores
        self.cleanup_test_data()
        
        # Ejecutar tests
        results = {
            'tests_total': 0,
            'tests_passed': 0,
            'tests_failed': 0
        }
        
        # Test 1: Verificación básica del sistema
        self.test_basic_system(results)
        
        # Test 2: Detección de sesgo 5 estrellas
        self.test_five_star_bias(results)
        
        # Test 3: Protección usuarios legítimos
        self.test_legitimate_users(results)
        
        if not quick_mode:
            # Test 4: Círculos de valoración mutua
            self.test_mutual_circles(results)
            
            # Test 5: Spam de cuentas nuevas
            self.test_new_account_spam(results)
        
        # Mostrar resumen final
        self.show_final_results(results)
        
        # Limpiar
        self.cleanup_test_data()
    
    def test_basic_system(self, results):
        """Test básico del sistema"""
        self.stdout.write("\n🔧 TEST 1: VERIFICACIÓN BÁSICA DEL SISTEMA")
        self.stdout.write("-" * 45)
        
        try:
            # Verificar configuración
            config = AntiAbuseConfig.objects.get(key='gaming_detection')
            self.stdout.write("   ✅ Configuración anti-gaming encontrada")
            
            # Verificar detector
            detector = AntiGamingDetector()
            self.stdout.write("   ✅ AntiGamingDetector inicializado")
            
            # Verificar modelos
            flag_count = RatingFlag.objects.count()
            self.stdout.write(f"   ✅ Modelo RatingFlag funcional ({flag_count} flags)")
            
            results['tests_passed'] += 1
            self.stdout.write("   🎉 TEST 1 PASADO")
            
        except Exception as e:
            results['tests_failed'] += 1
            self.stdout.write(f"   ❌ TEST 1 FALLIDO: {e}")
        
        results['tests_total'] += 1
    
    def test_five_star_bias(self, results):
        """Test de detección de sesgo de 5 estrellas"""
        self.stdout.write("\n⭐ TEST 2: DETECCIÓN SESGO 5 ESTRELLAS")
        self.stdout.write("-" * 40)
        
        try:
            # Crear usuarios
            attacker = User.objects.create_user(
                username='test_bias_attacker',
                email='bias@test.com',
                password='test123'
            )
            
            victims = []
            for i in range(12):  # Suficientes para superar umbral de 10 valoraciones
                victim = User.objects.create_user(
                    username=f'test_bias_victim_{i}',
                    email=f'biasvictim{i}@test.com',
                    password='test123'
                )
                victims.append(victim)
            
            # Atacante da solo 5 estrellas
            detector = AntiGamingDetector()
            flags_detectados = 0
            
            for i, victim in enumerate(victims):
                rating = UserRating.objects.create(
                    rater=attacker,
                    rated_user=victim,
                    rating=5,
                    interaction_type='trade'
                )
                
                flags = detector.analyze_rating(rating)
                bias_flags = [f for f in flags if f['type'] == 'five_star_bias']
                if bias_flags:
                    flags_detectados += 1
                    if i == len(victims) - 1:  # Solo mostrar en la última
                        self.stdout.write(f"   🚩 Sesgo detectado en valoración #{i+1}")
            
            if flags_detectados > 0:
                self.stdout.write(f"   ✅ Sesgo de 5 estrellas detectado correctamente")
                results['tests_passed'] += 1
            else:
                self.stdout.write(f"   ❌ No se detectó sesgo (puede estar bien si umbrales son altos)")
                results['tests_failed'] += 1
            
        except Exception as e:
            results['tests_failed'] += 1
            self.stdout.write(f"   ❌ TEST 2 FALLIDO: {e}")
        
        results['tests_total'] += 1
    
    def test_legitimate_users(self, results):
        """Test de protección a usuarios legítimos"""
        self.stdout.write("\n👤 TEST 3: PROTECCIÓN USUARIOS LEGÍTIMOS")
        self.stdout.write("-" * 40)
        
        try:
            # Crear usuario legítimo
            legit_user = User.objects.create_user(
                username='test_legit_user',
                email='legit@test.com',
                password='test123'
            )
            
            # Crear víctimas
            victims = []
            for i in range(5):
                victim = User.objects.create_user(
                    username=f'test_legit_victim_{i}',
                    email=f'legitvictim{i}@test.com',
                    password='test123'
                )
                victims.append(victim)
            
            # Usuario legítimo da valoraciones variadas
            legitimate_ratings = [4, 5, 3, 4, 5]
            detector = AntiGamingDetector()
            falsos_positivos = 0
            
            for i, rating_value in enumerate(legitimate_ratings):
                rating = UserRating.objects.create(
                    rater=legit_user,
                    rated_user=victims[i],
                    rating=rating_value,
                    interaction_type='trade'
                )
                
                flags = detector.analyze_rating(rating)
                if flags:
                    falsos_positivos += 1
            
            if falsos_positivos == 0:
                self.stdout.write("   ✅ Sin falsos positivos en usuario legítimo")
                results['tests_passed'] += 1
            else:
                self.stdout.write(f"   ⚠️ {falsos_positivos} falsos positivos detectados")
                results['tests_failed'] += 1
            
        except Exception as e:
            results['tests_failed'] += 1
            self.stdout.write(f"   ❌ TEST 3 FALLIDO: {e}")
        
        results['tests_total'] += 1
    
    def test_mutual_circles(self, results):
        """Test de círculos de valoración mutua"""
        self.stdout.write("\n🔄 TEST 4: CÍRCULOS DE VALORACIÓN MUTUA")
        self.stdout.write("-" * 40)
        
        try:
            # Crear usuarios para círculo
            circle_users = []
            for i in range(4):
                user = User.objects.create_user(
                    username=f'test_circle_{i}',
                    email=f'circle{i}@test.com',
                    password='test123'
                )
                circle_users.append(user)
            
            # Crear círculo: A->B->C->D->A
            detector = AntiGamingDetector()
            mutual_flags = 0
            
            for i in range(len(circle_users)):
                rater = circle_users[i]
                rated = circle_users[(i + 1) % len(circle_users)]
                
                # Crear múltiples valoraciones para superar umbral
                for j in range(4):  # 4 valoraciones mutuas
                    rating = UserRating.objects.create(
                        rater=rater,
                        rated_user=rated,
                        rating=5,
                        interaction_type='trade'
                    )
                    
                    flags = detector.analyze_rating(rating)
                    mutual_circle_flags = [f for f in flags if f['type'] == 'mutual_rating_circle']
                    if mutual_circle_flags:
                        mutual_flags += 1
                        break  # Una detección por par es suficiente
            
            if mutual_flags > 0:
                self.stdout.write(f"   ✅ Círculo mutuo detectado")
                results['tests_passed'] += 1
            else:
                self.stdout.write(f"   ❌ No se detectó círculo mutuo")
                results['tests_failed'] += 1
            
        except Exception as e:
            results['tests_failed'] += 1
            self.stdout.write(f"   ❌ TEST 4 FALLIDO: {e}")
        
        results['tests_total'] += 1
    
    def test_new_account_spam(self, results):
        """Test de spam de cuentas nuevas"""
        self.stdout.write("\n📧 TEST 5: SPAM DE CUENTAS NUEVAS")
        self.stdout.write("-" * 35)
        
        try:
            # Crear cuenta nueva (hace pocas horas)
            new_spammer = User.objects.create_user(
                username='test_new_spammer',
                email='newspam@test.com',
                password='test123'
            )
            # Simular cuenta recién creada
            new_spammer.date_joined = timezone.now() - timedelta(hours=2)
            new_spammer.save()
            
            # Crear víctimas
            victims = []
            for i in range(7):  # Más del límite de 5
                victim = User.objects.create_user(
                    username=f'test_spam_victim_{i}',
                    email=f'spamvictim{i}@test.com',
                    password='test123'
                )
                victims.append(victim)
            
            # Spam masivo
            detector = AntiGamingDetector()
            spam_flags = 0
            
            for i, victim in enumerate(victims):
                rating = UserRating.objects.create(
                    rater=new_spammer,
                    rated_user=victim,
                    rating=4,
                    interaction_type='trade'
                )
                
                flags = detector.analyze_rating(rating)
                spam_detected = any(f['type'] == 'new_account_spam' for f in flags)
                if spam_detected:
                    spam_flags += 1
                    if i >= 5:  # Debería detectar después del límite
                        self.stdout.write(f"   🚩 Spam detectado en valoración #{i+1}")
            
            if spam_flags > 0:
                self.stdout.write(f"   ✅ Spam de cuenta nueva detectado")
                results['tests_passed'] += 1
            else:
                self.stdout.write(f"   ❌ No se detectó spam de cuenta nueva")
                results['tests_failed'] += 1
            
        except Exception as e:
            results['tests_failed'] += 1
            self.stdout.write(f"   ❌ TEST 5 FALLIDO: {e}")
        
        results['tests_total'] += 1
    
    def show_final_results(self, results):
        """Muestra resultados finales"""
        self.stdout.write("\n" + "=" * 60)
        self.stdout.write("📊 RESUMEN FINAL DE TESTS")
        self.stdout.write("=" * 60)
        
        total = results['tests_total']
        passed = results['tests_passed']
        failed = results['tests_failed']
        
        self.stdout.write(f"Total de tests: {total}")
        self.stdout.write(f"Tests pasados: {passed}")
        self.stdout.write(f"Tests fallidos: {failed}")
        
        if failed == 0:
            self.stdout.write(self.style.SUCCESS("\n🎉 TODOS LOS TESTS PASARON"))
            self.stdout.write("✅ Sistema anti-gaming funcionando correctamente")
        elif passed > failed:
            self.stdout.write(self.style.WARNING(f"\n⚠️ ALGUNOS TESTS FALLARON ({failed}/{total})"))
            self.stdout.write("El sistema funciona pero puede necesitar ajustes")
        else:
            self.stdout.write(self.style.ERROR(f"\n❌ MÚLTIPLES TESTS FALLARON ({failed}/{total})"))
            self.stdout.write("Se requiere revisión del sistema")
        
        # Estadísticas adicionales
        total_flags = RatingFlag.objects.count()
        self.stdout.write(f"\n📈 Flags totales en sistema: {total_flags}")
    
    def cleanup_test_data(self):
        """Limpia datos de prueba"""
        # Eliminar usuarios de test
        User.objects.filter(username__startswith='test_').delete()
        self.stdout.write("🧹 Datos de prueba limpiados")
