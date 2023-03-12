import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/component/sprite_component.dart';
// import 'package:samsara/effect/fade_effect.dart';
// import 'package:flame/effects.dart';
import 'package:samsara/component/fading_text.dart';

class PlayGround extends GameComponent with HandlesGesture {
  PlayGround({
    required double width,
    required double height,
  }) : super(size: Vector2(width, height)) {
    onTapDown = (int buttons, Vector2 position) {
      // final c = SpriteComponent2(spriteId: 'pepe.png', anchor: Anchor.center);
      // c.position = details.globalPosition.toVector2();
      // c.add(FadeEffect(target: c, controller: EffectController(duration: 1.0)));
      // add(c);

      final c2 = FadingText(
        'hit!',
        movingUpOffset: 50,
        duration: 0.8,
        fadeOutAfterDuration: 0.3,
        textPaint: DefaultTextPaint.danger.copyWith(
          (textStyle) => textStyle.copyWith(fontSize: 16),
        ),
      );
      c2.position = position;
      add(c2);
    };
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
