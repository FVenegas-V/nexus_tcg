"""
Testing Adversarial - Suite completo de pruebas anti-gaming
"""
import unittest
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta
from unittest.mock import patch

from users.models import UserRating, RatingFlag, AntiAbuseConfig
from users.anti_gaming import AntiGamingDetector
from users.rate_limiting import RateLimitChecker
from users.validators import InteractionValidator

User = get_user_model()


class AdversarialTestCase(TestCase):
    """Base class para tests adversariales"""
    
    def setUp(self):
        """Setup común para todos los tests"""
        # Crear configuración de testing
        self.config = {
            'enabled': True,
            'mutual_rating_threshold': 3,
            'five_star_bias_threshold': 0.92,
            'rating_burst_threshold': 15,
            'same_ip_threshold': 8,
            'new_account_days': 7,
            'new_account_limit': 5
        }
        
        AntiAbuseConfig.objects.update_or_create(
            key='gaming_detection',
            defaults={'value': self.config}
        )
        
        # Crear usuarios base para testing
        self.create_test_users()
        
        # Inicializar detectores
        self.detector = AntiGamingDetector()
        self.rate_limiter = RateLimitChecker()
        self.validator = InteractionValidator()
    
    def create_test_users(self):
        """Crea usuarios para diferentes tipos de tests"""
        # Usuario legítimo normal
        self.legitimate_user = User.objects.create_user(
            username='legitimate_trader',
            email='legit@example.com',
            password='testpass123'
        )
        
        # Usuario atacante potencial
        self.attacker = User.objects.create_user(
            username='potential_attacker',
            email='attacker@example.com',
            password='testpass123'
        )
        
        # Usuarios víctimas para ataques
        self.victims = []
        for i in range(10):
            victim = User.objects.create_user(
                username=f'victim_{i}',
                email=f'victim{i}@example.com',
                password='testpass123'
            )
            self.victims.append(victim)
        
        # Cuentas nuevas para spam testing
        self.new_accounts = []
        for i in range(5):
            new_account = User.objects.create_user(
                username=f'new_spammer_{i}',
                email=f'newspam{i}@example.com',
                password='testpass123'
            )
            # Simular cuenta nueva (creada hace pocas horas)
            new_account.date_joined = timezone.now() - timedelta(hours=i+1)
            new_account.save()
            self.new_accounts.append(new_account)


class TestFiveStarBiasAttack(AdversarialTestCase):
    """Tests para ataques de sesgo de 5 estrellas"""
    
    def test_massive_five_star_attack(self):
        """Simula un usuario que solo da 5 estrellas para inflar reputación"""
        print("\n🎯 TEST: Ataque de sesgo 5 estrellas masivo")
        
        # El atacante da solo 5 estrellas a múltiples usuarios
        ratings_created = 0
        flags_detected = 0
        
        for victim in self.victims:
            rating = UserRating.objects.create(
                rater=self.attacker,
                rated_user=victim,
                rating=5,
                interaction_type='trade',
                comment='Perfect trader!'
            )
            ratings_created += 1
            
            # Verificar si se detectó el patrón
            flags = self.detector.analyze_rating(rating)
            if any(f['type'] == 'five_star_bias' for f in flags):
                flags_detected += 1
                print(f"   🚩 Flag detectado en valoración #{ratings_created}")
        
        # Verificaciones
        self.assertGreater(flags_detected, 0, "Debería detectar sesgo de 5 estrellas")
        self.assertGreater(ratings_created, 5, "Debería haber creado suficientes valoraciones")
        
        print(f"   ✅ Resultado: {flags_detected}/{ratings_created} flags detectados")
    
    def test_gradual_bias_buildup(self):
        """Simula un atacante que gradualmente aumenta el sesgo"""
        print("\n🎯 TEST: Construcción gradual de sesgo")
        
        # Primero da valoraciones mixtas para parecer legítimo
        mixed_ratings = [4, 5, 3, 5, 4, 5]
        
        for i, rating_value in enumerate(mixed_ratings):
            UserRating.objects.create(
                rater=self.attacker,
                rated_user=self.victims[i],
                rating=rating_value,
                interaction_type='trade'
            )
        
        # Luego cambia a solo 5 estrellas
        five_star_ratings = 0
        for i in range(6, 10):
            rating = UserRating.objects.create(
                rater=self.attacker,
                rated_user=self.victims[i],
                rating=5,
                interaction_type='trade'
            )
            
            flags = self.detector.analyze_rating(rating)
            if any(f['type'] == 'five_star_bias' for f in flags):
                five_star_ratings += 1
        
        # Debería detectar el patrón cuando el sesgo se vuelve obvio
        self.assertGreater(five_star_ratings, 0, "Debería detectar el sesgo gradual")
        print(f"   ✅ Sesgo detectado en {five_star_ratings}/4 valoraciones finales")


class TestMutualRatingCircles(AdversarialTestCase):
    """Tests para círculos de valoración mutua"""
    
    def test_simple_mutual_circle(self):
        """Simula círculo simple de valoración mutua"""
        print("\n🎯 TEST: Círculo de valoración mutua simple")
        
        # Crear círculo A <-> B <-> C <-> A
        users_circle = [self.attacker, self.victims[0], self.victims[1]]
        
        # Cada usuario valora al siguiente en el círculo
        mutual_flags = 0
        for i in range(len(users_circle)):
            rater = users_circle[i]
            rated = users_circle[(i + 1) % len(users_circle)]
            
            rating = UserRating.objects.create(
                rater=rater,
                rated_user=rated,
                rating=5,
                interaction_type='trade'
            )
            
            flags = self.detector.analyze_rating(rating)
            if any(f['type'] == 'mutual_rating_circle' for f in flags):
                mutual_flags += 1
                print(f"   🚩 Círculo detectado: {rater.username} -> {rated.username}")
        
        self.assertGreater(mutual_flags, 0, "Debería detectar círculo mutuo")
        print(f"   ✅ Círculo detectado en {mutual_flags}/3 valoraciones")
    
    def test_complex_rating_network(self):
        """Simula red compleja de valoraciones mutuas"""
        print("\n🎯 TEST: Red compleja de valoraciones mutuas")
        
        # Crear red donde todos se valoran entre sí
        network_users = [self.attacker] + self.victims[:4]  # 5 usuarios
        
        network_flags = 0
        total_ratings = 0
        
        for rater in network_users:
            for rated in network_users:
                if rater != rated:  # No auto-valoración
                    rating = UserRating.objects.create(
                        rater=rater,
                        rated_user=rated,
                        rating=5,
                        interaction_type='trade'
                    )
                    total_ratings += 1
                    
                    flags = self.detector.analyze_rating(rating)
                    if any(f['type'] == 'mutual_rating_circle' for f in flags):
                        network_flags += 1
        
        # En una red de 5 usuarios, debería detectar múltiples círculos
        self.assertGreater(network_flags, 5, "Debería detectar múltiples círculos en la red")
        print(f"   ✅ Red detectada: {network_flags}/{total_ratings} valoraciones flagged")


class TestNewAccountSpam(AdversarialTestCase):
    """Tests para spam de cuentas nuevas"""
    
    def test_new_account_rating_spam(self):
        """Simula spam masivo de cuentas nuevas"""
        print("\n🎯 TEST: Spam de cuentas nuevas")
        
        spam_flags = 0
        
        for spammer in self.new_accounts:
            # Cada cuenta nueva hace muchas valoraciones rápidamente
            for i, victim in enumerate(self.victims[:6]):  # 6 valoraciones > límite de 5
                rating = UserRating.objects.create(
                    rater=spammer,
                    rated_user=victim,
                    rating=4,
                    interaction_type='trade'
                )
                
                flags = self.detector.analyze_rating(rating)
                if any(f['type'] == 'new_account_spam' for f in flags):
                    spam_flags += 1
                    print(f"   🚩 Spam detectado: {spammer.username} valoración #{i+1}")
        
        self.assertGreater(spam_flags, 0, "Debería detectar spam de cuentas nuevas")
        print(f"   ✅ Spam detectado en {spam_flags} valoraciones")
    
    def test_coordinated_new_account_attack(self):
        """Simula ataque coordinado de múltiples cuentas nuevas"""
        print("\n🎯 TEST: Ataque coordinado de cuentas nuevas")
        
        # Todas las cuentas nuevas atacan al mismo usuario víctima
        target_victim = self.victims[0]
        coordinated_flags = 0
        
        for spammer in self.new_accounts:
            rating = UserRating.objects.create(
                rater=spammer,
                rated_user=target_victim,
                rating=1,  # Valoraciones negativas coordinadas
                interaction_type='trade',
                comment='Bad trader!'
            )
            
            flags = self.detector.analyze_rating(rating)
            if flags:  # Cualquier tipo de flag
                coordinated_flags += 1
        
        self.assertGreater(coordinated_flags, 0, "Debería detectar ataque coordinado")
        print(f"   ✅ Ataque coordinado detectado en {coordinated_flags}/{len(self.new_accounts)} cuentas")


class TestRateLimitingBypass(AdversarialTestCase):
    """Tests para intentos de bypass del rate limiting"""
    
    def test_rapid_fire_ratings(self):
        """Simula intento de bypass con valoraciones rápidas"""
        print("\n🎯 TEST: Bypass de rate limiting - valoraciones rápidas")
        
        blocked_attempts = 0
        successful_ratings = 0
        
        # Intentar crear 20 valoraciones en poco tiempo
        for i in range(20):
            try:
                # Verificar rate limit antes de crear
                can_rate = self.rate_limiter.can_user_rate(
                    self.attacker, 
                    self.victims[i % len(self.victims)]
                )
                
                if not can_rate:
                    blocked_attempts += 1
                    print(f"   🛡️ Intento #{i+1} bloqueado por rate limit")
                else:
                    UserRating.objects.create(
                        rater=self.attacker,
                        rated_user=self.victims[i % len(self.victims)],
                        rating=5,
                        interaction_type='trade'
                    )
                    successful_ratings += 1
                    
            except Exception as e:
                blocked_attempts += 1
                print(f"   🛡️ Intento #{i+1} falló: {str(e)[:50]}")
        
        # Debería bloquear la mayoría de intentos
        self.assertGreater(blocked_attempts, successful_ratings, 
                          "Rate limiting debería bloquear intentos excesivos")
        print(f"   ✅ Rate limiting efectivo: {blocked_attempts} bloqueados, {successful_ratings} exitosos")
    
    def test_same_user_cooldown_bypass(self):
        """Simula intento de valorar al mismo usuario múltiples veces"""
        print("\n🎯 TEST: Bypass de cooldown mismo usuario")
        
        target_victim = self.victims[0]
        
        # Primera valoración debería ser exitosa
        first_rating = UserRating.objects.create(
            rater=self.attacker,
            rated_user=target_victim,
            rating=5,
            interaction_type='trade'
        )
        self.assertTrue(first_rating.id, "Primera valoración debería ser exitosa")
        
        # Segunda valoración al mismo usuario debería fallar
        can_rate_again = self.rate_limiter.can_user_rate(self.attacker, target_victim)
        self.assertFalse(can_rate_again, "No debería poder valorar al mismo usuario inmediatamente")
        
        print("   ✅ Cooldown mismo usuario funcionando correctamente")


class TestPerformanceUnderLoad(AdversarialTestCase):
    """Tests de performance bajo carga"""
    
    def test_detection_performance(self):
        """Mide performance del sistema de detección"""
        print("\n🎯 TEST: Performance bajo carga")
        
        import time
        
        start_time = time.time()
        
        # Crear muchas valoraciones y medir tiempo de detección
        for i in range(50):
            rating = UserRating.objects.create(
                rater=self.victims[i % len(self.victims)],
                rated_user=self.victims[(i + 1) % len(self.victims)],
                rating=(i % 5) + 1,  # Ratings 1-5
                interaction_type='trade'
            )
            
            # Ejecutar detección
            flags = self.detector.analyze_rating(rating)
        
        end_time = time.time()
        total_time = end_time - start_time
        avg_time_per_rating = total_time / 50
        
        # Performance debería ser razonable (< 100ms por valoración)
        self.assertLess(avg_time_per_rating, 0.1, 
                       "Detección debería ser rápida (< 100ms por valoración)")
        
        print(f"   ✅ Performance: {avg_time_per_rating*1000:.2f}ms promedio por valoración")
        print(f"   📊 Total: {total_time:.2f}s para 50 valoraciones")


class TestEdgeCases(AdversarialTestCase):
    """Tests para casos límite y edge cases"""
    
    def test_deleted_user_ratings(self):
        """Testa comportamiento con usuarios eliminados"""
        print("\n🎯 TEST: Edge case - usuarios eliminados")
        
        # Crear valoración normal
        rating = UserRating.objects.create(
            rater=self.attacker,
            rated_user=self.victims[0],
            rating=5,
            interaction_type='trade'
        )
        
        # Simular eliminación de usuario (soft delete)
        self.victims[0].is_active = False
        self.victims[0].save()
        
        # Detección no debería fallar
        try:
            flags = self.detector.analyze_rating(rating)
            test_passed = True
        except Exception as e:
            test_passed = False
            print(f"   ❌ Error con usuario eliminado: {e}")
        
        self.assertTrue(test_passed, "Detección debería manejar usuarios eliminados")
        print("   ✅ Manejo de usuarios eliminados correcto")
    
    def test_extreme_rating_values(self):
        """Testa comportamiento con valores extremos"""
        print("\n🎯 TEST: Edge case - valores extremos")
        
        edge_cases_passed = 0
        
        # Test casos límite
        test_cases = [
            {'rating': 1, 'name': 'Mínimo'},
            {'rating': 5, 'name': 'Máximo'},
        ]
        
        for case in test_cases:
            try:
                rating = UserRating.objects.create(
                    rater=self.attacker,
                    rated_user=self.victims[0],
                    rating=case['rating'],
                    interaction_type='trade'
                )
                
                flags = self.detector.analyze_rating(rating)
                edge_cases_passed += 1
                print(f"   ✅ {case['name']} ({case['rating']}): OK")
                
            except Exception as e:
                print(f"   ❌ {case['name']} ({case['rating']}): {e}")
        
        self.assertEqual(edge_cases_passed, len(test_cases), 
                        "Todos los casos límite deberían pasar")


class TestLegitimateUserProtection(AdversarialTestCase):
    """Tests para asegurar que usuarios legítimos no sean flagged incorrectamente"""
    
    def test_normal_trading_behavior(self):
        """Simula comportamiento normal de trading"""
        print("\n🎯 TEST: Protección usuarios legítimos")
        
        # Simular comportamiento legítimo variado
        legitimate_ratings = [
            {'victim': 0, 'rating': 5, 'comment': 'Great trade!'},
            {'victim': 1, 'rating': 4, 'comment': 'Good communication'},
            {'victim': 2, 'rating': 3, 'comment': 'OK trade'},
            {'victim': 3, 'rating': 5, 'comment': 'Fast shipping'},
            {'victim': 4, 'rating': 4, 'comment': 'Cards in good condition'},
        ]
        
        false_positives = 0
        
        for i, rating_data in enumerate(legitimate_ratings):
            # Simular tiempo entre valoraciones
            rating = UserRating.objects.create(
                rater=self.legitimate_user,
                rated_user=self.victims[rating_data['victim']],
                rating=rating_data['rating'],
                interaction_type='trade',
                comment=rating_data['comment']
            )
            
            flags = self.detector.analyze_rating(rating)
            if flags:
                false_positives += 1
                print(f"   ⚠️ Falso positivo en valoración #{i+1}: {flags[0]['type']}")
        
        # No debería haber falsos positivos en comportamiento legítimo
        self.assertEqual(false_positives, 0, 
                        "Usuarios legítimos no deberían ser flagged")
        print(f"   ✅ Sin falsos positivos: {len(legitimate_ratings)} valoraciones legítimas")


if __name__ == '__main__':
    unittest.main()
