// ignore_for_file: file_names, sort_child_properties_last, use_super_parameters

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 动画类型枚举
enum AnimationType {
  fade,           // 淡入淡出
  scale,          // 缩放
  slide,          // 滑动
  rotate,         // 旋转
  bounce,         // 弹跳
  pulse,          // 脉冲
  shake,          // 摇晃
  flip,           // 翻转
  staggered,      // 交错动画
  custom          // 自定义动画
}

/// 动画方向枚举
enum AnimationDirection {
  topToBottom,    // 从上到下
  bottomToTop,    // 从下到上
  leftToRight,    // 从左到右
  rightToLeft     // 从右到左
}

/// 动画组件工厂
/// 提供多种类型的动画效果，方便在应用中复用
class AnimationComponent {
  /// 创建动画组件
  /// 
  /// [key] - Widget键，用于触发重建
  /// [type] - 动画类型
  /// [child] - 需要添加动画的子组件
  /// [duration] - 动画持续时间
  /// [delay] - 动画延迟时间
  /// [curve] - 动画曲线
  /// [repeat] - 是否重复动画
  /// [direction] - 动画方向（适用于slide等方向性动画）
  /// [customAnimation] - 自定义动画构建方法（仅在custom类型中使用）
  /// [onComplete] - 动画完成回调
  static Widget create({
    Key? key,
    required AnimationType type,
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeInOut,
    bool repeat = false,
    AnimationDirection direction = AnimationDirection.topToBottom,
    Widget Function(BuildContext, Widget, Animation<double>)? customAnimation,
    VoidCallback? onComplete,
  }) {
    // 根据动画类型创建对应的动画
    switch (type) {
      case AnimationType.fade:
        return _FadeAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.scale:
        return _ScaleAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.slide:
        return _SlideAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          direction: direction,
          onComplete: onComplete,
        );
      case AnimationType.rotate:
        return _RotateAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.bounce:
        return _BounceAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.pulse:
        return _PulseAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.shake:
        return _ShakeAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.flip:
        return _FlipAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.staggered:
        return _StaggeredAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          onComplete: onComplete,
        );
      case AnimationType.custom:
        return _CustomAnimation(
          key: key,
          child: child,
          duration: duration,
          delay: delay,
          curve: curve,
          repeat: repeat,
          customBuilder: customAnimation,
          onComplete: onComplete,
        );
    }
  }
}

/// 淡入淡出动画
class _FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _FadeAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<_FadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// 缩放动画
class _ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _ScaleAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<_ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// 滑动动画
class _SlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final AnimationDirection direction;
  final VoidCallback? onComplete;

  const _SlideAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    required this.direction,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<_SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 根据方向设置起始偏移量
    final Offset beginOffset = _getBeginOffsetByDirection(widget.direction);
    _animation = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  Offset _getBeginOffsetByDirection(AnimationDirection direction) {
    switch (direction) {
      case AnimationDirection.topToBottom:
        return const Offset(0.0, -1.0);
      case AnimationDirection.bottomToTop:
        return const Offset(0.0, 1.0);
      case AnimationDirection.leftToRight:
        return const Offset(-1.0, 0.0);
      case AnimationDirection.rightToLeft:
        return const Offset(1.0, 0.0);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _animation,
      child: widget.child,
    );
  }
}

/// 旋转动画
class _RotateAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _RotateAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<_RotateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
    );
  }
}

/// 弹跳动画
class _BounceAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _BounceAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<_BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20.0),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40.0),
    ]).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
    );
  }
}

/// 脉冲动画
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _PulseAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
    );
  }
}

/// 摇晃动画
class _ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _ShakeAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<_ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final sineValue = math.sin((_animation.value * 6) * math.pi);
        return Transform.translate(
          offset: Offset(sineValue * 10, 0),
          child: child,
        );
      },
    );
  }
}

/// 翻转动画
class _FlipAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _FlipAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_FlipAnimation> createState() => _FlipAnimationState();
}

class _FlipAnimationState extends State<_FlipAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final value = _animation.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(value * math.pi),
          child: child,
        );
      },
    );
  }
}

/// 交错动画
class _StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final VoidCallback? onComplete;

  const _StaggeredAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<_StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 淡入动画 (0.0 - 0.4)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // 滑动动画 (0.2 - 0.7)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    // 缩放动画 (0.5 - 1.0)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// 自定义动画
class _CustomAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool repeat;
  final Widget Function(BuildContext, Widget, Animation<double>)? customBuilder;
  final VoidCallback? onComplete;

  const _CustomAnimation({
    Key? key,
    required this.child,
    required this.duration,
    required this.delay,
    required this.curve,
    required this.repeat,
    this.customBuilder,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_CustomAnimation> createState() => _CustomAnimationState();
}

class _CustomAnimationState extends State<_CustomAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.delay == Duration.zero) {
      _startAnimation();
    } else {
      Future.delayed(widget.delay, _startAnimation);
    }
  }

  void _startAnimation() {
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward().then((_) {
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customBuilder != null) {
      return widget.customBuilder!(context, widget.child, _animation);
    } else {
      // 如果没有提供自定义构建器，返回默认动画
      return AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: child,
          );
        },
      );
    }
  }
} 