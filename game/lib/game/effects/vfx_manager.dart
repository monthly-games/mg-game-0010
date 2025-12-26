import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// VFX Manager for Dungeon Shop Simulator (MG-0010)
/// Shop Management + Idle 게임 전용 이펙트 관리자
class VfxManager extends Component with HasGameRef {
  VfxManager();
  final Random _random = Random();

  // Shop/Crafting Effects
  void showItemCraft(Vector2 position, {bool isRare = false}) {
    final color = isRare ? Colors.purple : Colors.amber;
    gameRef.add(_createBurstEffect(position: position, color: color, count: isRare ? 25 : 15, speed: 80, lifespan: 0.6));
    gameRef.add(_createSparkleEffect(position: position, color: Colors.white, count: 10));
  }

  void showSaleComplete(Vector2 position, int goldAmount) {
    gameRef.add(_createCoinEffect(position: position, count: (goldAmount / 30).clamp(5, 20).toInt()));
    showNumberPopup(position, '+$goldAmount', color: Colors.amber);
  }

  void showCustomerHappy(Vector2 position) {
    gameRef.add(_createRisingEffect(position: position, color: Colors.pink, count: 5, speed: 40));
  }

  void showShopUpgrade(Vector2 position) {
    gameRef.add(_createExplosionEffect(position: position, color: Colors.amber, count: 35, radius: 70));
    gameRef.add(_UpgradeText(position: position));
  }

  void showInventoryAdd(Vector2 position) {
    gameRef.add(_createSparkleEffect(position: position, color: Colors.lightBlue, count: 8));
  }

  void showNumberPopup(Vector2 position, String text, {Color color = Colors.white}) {
    gameRef.add(_NumberPopup(position: position, text: text, color: color));
  }

  // Private generators (reusable)
  ParticleSystemComponent _createBurstEffect({required Vector2 position, required Color color, required int count, required double speed, required double lifespan}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: lifespan, generator: (i) {
      final angle = (i / count) * 2 * pi;
      final velocity = Vector2(cos(angle), sin(angle)) * (speed * (0.5 + _random.nextDouble() * 0.5));
      return AcceleratedParticle(position: position.clone(), speed: velocity, acceleration: Vector2(0, 150), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.zero, 4 * (1.0 - particle.progress * 0.5), Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createExplosionEffect({required Vector2 position, required Color color, required int count, required double radius}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.7, generator: (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = radius * (0.4 + _random.nextDouble() * 0.6);
      return AcceleratedParticle(position: position.clone(), speed: Vector2(cos(angle), sin(angle)) * speed, acceleration: Vector2(0, 100), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.zero, 5 * (1.0 - particle.progress * 0.3), Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createSparkleEffect({required Vector2 position, required Color color, required int count}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.5, generator: (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 50 + _random.nextDouble() * 40;
      return AcceleratedParticle(position: position.clone(), speed: Vector2(cos(angle), sin(angle)) * speed, acceleration: Vector2(0, 40), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        final size = 3 * (1.0 - particle.progress * 0.5);
        final path = Path();
        for (int j = 0; j < 4; j++) {
          final a = (j * pi / 2);
          if (j == 0) path.moveTo(cos(a) * size, sin(a) * size);
          else path.lineTo(cos(a) * size, sin(a) * size);
        }
        path.close();
        canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createRisingEffect({required Vector2 position, required Color color, required int count, required double speed}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.8, generator: (i) {
      final spreadX = (_random.nextDouble() - 0.5) * 30;
      return AcceleratedParticle(position: position.clone() + Vector2(spreadX, 0), speed: Vector2(0, -speed), acceleration: Vector2(0, -20), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress).clamp(0.0, 1.0);
        canvas.drawCircle(Offset.zero, 3, Paint()..color = color.withOpacity(opacity));
      }));
    }));
  }

  ParticleSystemComponent _createCoinEffect({required Vector2 position, required int count}) {
    return ParticleSystemComponent(particle: Particle.generate(count: count, lifespan: 0.7, generator: (i) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi / 4;
      final speed = 130 + _random.nextDouble() * 80;
      return AcceleratedParticle(position: position.clone(), speed: Vector2(cos(angle), sin(angle)) * speed, acceleration: Vector2(0, 350), child: ComputedParticle(renderer: (canvas, particle) {
        final opacity = (1.0 - particle.progress * 0.2).clamp(0.0, 1.0);
        canvas.save();
        canvas.rotate(particle.progress * 3 * pi);
        canvas.drawOval(const Rect.fromLTWH(-3, -2, 6, 4), Paint()..color = Colors.amber.withOpacity(opacity));
        canvas.restore();
      }));
    }));
  }
}

class _UpgradeText extends TextComponent {
  _UpgradeText({required Vector2 position}) : super(text: 'UPGRADE!', position: position + Vector2(0, -40), anchor: Anchor.center, textRenderer: TextPaint(style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber, shadows: [Shadow(color: Colors.orange, blurRadius: 10)])));
  @override Future<void> onLoad() async { await super.onLoad(); scale = Vector2.all(0.5); add(ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.3, curve: Curves.elasticOut))); add(MoveByEffect(Vector2(0, -20), EffectController(duration: 1.0, curve: Curves.easeOut))); add(OpacityEffect.fadeOut(EffectController(duration: 1.0, startDelay: 0.5))); add(RemoveEffect(delay: 1.5)); }
}

class _NumberPopup extends TextComponent {
  _NumberPopup({required Vector2 position, required String text, required Color color}) : super(text: text, position: position, anchor: Anchor.center, textRenderer: TextPaint(style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color, shadows: const [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))])));
  @override Future<void> onLoad() async { await super.onLoad(); add(MoveByEffect(Vector2(0, -25), EffectController(duration: 0.6, curve: Curves.easeOut))); add(OpacityEffect.fadeOut(EffectController(duration: 0.6, startDelay: 0.2))); add(RemoveEffect(delay: 0.8)); }
}
