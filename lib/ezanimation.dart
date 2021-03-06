library ezanimation;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Defines what happens to an [EzAnimation] when Navigator pushes another screen while animation is running
enum OnNavigate { resetAnimation, pauseAnimation, letItRun, takeToEnd }

/// A class to make animations easier and more accessible to the Flutter audience
/// [Listenable] is extended for easy rebuilds when value changes
class EzAnimation extends Listenable {
  /// Begin value for [Tween] that creates the animation
  var begin;

  /// End value for [Tween] that creates the animation
  var end;

  /// Duration to pass to the [AnimationController]
  final Duration duration;

  /// Curve for when the animation goes ahead
  final Curve curve;

  /// Curve when the animation goes back
  final Curve reverseCurve;

  /// A handle to the tree to listen for navigation
  final BuildContext context;

  /// What to do when the current page is navigated away from
  final OnNavigate onNavigate;

  final TickerProvider vsync;

  /// Custom Ticker Provider for not using the default TickerProvider
  _CustomProvider _tickerProvider;

  /// Tween to create an animation from the given values
  Tween _tween;

  /// Tween Sequence to create an animation from the given values
  TweenSequence _tweenSequence;

  /// AnimationController to control the resultant animations
  /// Making a custom implementation of how tickers function internally was unnecessary
  AnimationController _controller;

  /// The animation that the user ultimately needs
  Animation _resultAnimation;

  /// Stores a list of all listeners that listen to the animation
  List<Function> _listeners = [];

  EzAnimation(
    this.begin,
    this.end,
    this.duration, {
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.context,
    this.onNavigate = OnNavigate.resetAnimation,
    this.vsync,
  }) {
    _tickerProvider = _CustomProvider();
    _tween = Tween(begin: begin, end: end);
    _controller = AnimationController(
        vsync: vsync == null ? _tickerProvider : vsync, duration: duration);
    _resultAnimation = _tween.animate(CurvedAnimation(
        parent: _controller, curve: curve, reverseCurve: reverseCurve));

    /// If a context is given, we listen to navigation changes
    /// If vsync is provided, this is automatically done by the ticker on the page
    if (context != null && vsync == null) {
      /// Listen for page changes, mute ticker when current context is no longer visible
      _resultAnimation.addListener(_animationObserver);

      /// Adds internal listener
      _listeners.add(_animationObserver);
    }
  }

  /// Creates an [Animation] from the given sequence.
  EzAnimation.sequence(
    List<SequenceItem> sequence,
    this.duration, {
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.context,
    this.onNavigate = OnNavigate.resetAnimation,
    this.vsync,
  }) {
    _tickerProvider = _CustomProvider();
    _tweenSequence = TweenSequence(sequence
        .map((e) => TweenSequenceItem(
            tween: Tween(begin: e.begin, end: e.end), weight: e.weight))
        .toList());
    _controller = AnimationController(
        vsync: vsync == null ? _tickerProvider : vsync, duration: duration);
    _resultAnimation = _tweenSequence.animate(CurvedAnimation(
        parent: _controller, curve: curve, reverseCurve: reverseCurve));

    /// If a context is given, we listen to navigation changes
    /// If vsync is provided, this is automatically done by the ticker on the page
    if (context != null && vsync == null) {
      /// Listen for page changes, mute ticker when current context is no longer visible
      _resultAnimation.addListener(_animationObserver);

      /// Adds internal listener
      _listeners.add(_animationObserver);
    }
  }

  /// Uses the given [Tween] to create a sequence
  /// This is helpful to use things like [ColorTween]
  EzAnimation.tween(
    Tween tween,
    this.duration, {
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.context,
    this.onNavigate = OnNavigate.resetAnimation,
    this.vsync,
  }) {
    _tickerProvider = _CustomProvider();
    _tween = tween;
    _controller = AnimationController(
        vsync: vsync == null ? _tickerProvider : vsync, duration: duration);
    _resultAnimation = _tween.animate(CurvedAnimation(
        parent: _controller, curve: curve, reverseCurve: reverseCurve));

    /// If a context is given, we listen to navigation changes
    /// If vsync is provided, this is automatically done by the ticker on the page
    if (context != null && vsync == null) {
      /// Listen for page changes, mute ticker when current context is no longer visible
      _resultAnimation.addListener(_animationObserver);

      /// Adds internal listener
      _listeners.add(_animationObserver);
    }
  }

  /// Creates an [Animation] from the given [TweenSequence]
  ///   /// This is helpful to use things like [ColorTween]
  EzAnimation.tweenSequence(
    TweenSequence sequence,
    this.duration, {
    this.curve = Curves.linear,
    this.reverseCurve = Curves.linear,
    this.context,
    this.onNavigate = OnNavigate.resetAnimation,
    this.vsync,
  }) {
    _tickerProvider = _CustomProvider();
    _tweenSequence = sequence;
    _controller = AnimationController(
        vsync: vsync == null ? _tickerProvider : vsync, duration: duration);
    _resultAnimation = _tweenSequence.animate(CurvedAnimation(
        parent: _controller, curve: curve, reverseCurve: reverseCurve));

    /// If a context is given, we listen to navigation changes
    /// If vsync is provided, this is automatically done by the ticker on the page
    if (context != null && vsync == null) {
      /// Listen for page changes, mute ticker when current context is no longer visible
      _resultAnimation.addListener(_animationObserver);

      /// Adds internal listener
      _listeners.add(_animationObserver);
    }
  }

  /// If current widget is no longer displayed, pause or reset animation depending upon provided value of [OnNavigate]
  void _animationObserver() {
    if (!ModalRoute.of(context).isCurrent) {
      if (onNavigate == OnNavigate.pauseAnimation) {
        _tickerProvider._ticker.muted = true;
      } else if (onNavigate == OnNavigate.resetAnimation) {
        _tickerProvider._ticker.stop();
        _listeners.forEach((element) {
          _resultAnimation.removeListener(element);
        });
        _controller.reset();
        _listeners.forEach((element) {
          _resultAnimation.addListener(element);
        });
      } else if (onNavigate == OnNavigate.letItRun) {
        // Do nothing, let it run
      } else if (onNavigate == OnNavigate.takeToEnd) {
        _tickerProvider._ticker.stop();
        _listeners.forEach((element) {
          _resultAnimation.removeListener(element);
        });
        _controller.value = 1.0;
        _listeners.forEach((element) {
          _resultAnimation.addListener(element);
        });
      }
    }
  }

  /// Gets current value of animation
  get value => _resultAnimation.value;

  /// Gets current progress of animation
  get progress => _controller.value;

  /// Adds a listener to the animation
  @override
  void addListener(listener) {
    _resultAnimation.addListener(listener);
    _listeners.add(listener);
  }

  /// Removes listener from the animation
  @override
  void removeListener(listener) {
    _resultAnimation.removeListener(listener);
    _listeners.remove(listener);
  }

  /// Starts an animation from a value
  void start({double from}) {
    if (vsync != null) {
      _controller.forward(from: from);
      return;
    }

    if (!_tickerProvider._ticker.muted) {
      _controller.forward(from: from);
    } else {
      _tickerProvider._ticker.muted = false;
    }
  }

  /// Repeats animation
  void repeat({double min, double max, bool rev = false, Duration period}) {
    _controller.repeat(min: min, max: max, reverse: rev, period: period);
  }

  /// Ends animation
  void stop() {
    _controller.stop();
  }

  /// Reverses animation
  void reverse({double from}) {
    _controller.reverse(from: from);
  }

  /// Reverses animation
  void reset() {
    _controller.reset();
  }

  /// Adds an animation listener to the result animation
  void addStatusListener(listener) {
    _resultAnimation.addStatusListener(listener);
  }

  /// Removes the animation listener to the result animation
  void removeStatusListener(listener) {
    _resultAnimation.removeStatusListener(listener);
  }

  /// Disposes ticker and controller
  void dispose() {
    _tickerProvider.dispose();
    _controller.dispose();
  }
}

/// Using a Custom [TickerProvider] helps not use a [SingleTickerProviderStateMixin] or [TickerProviderStateMixin]
/// in the app resulting in removing redundant code
class _CustomProvider extends TickerProvider {
  /// Ticker that provides ticks for the controller
  Ticker _ticker;

  @override
  Ticker createTicker(onTick) {
    _ticker = Ticker(onTick);
    return _ticker;
  }

  void dispose() {
    _ticker.dispose();
  }
}

class SequenceItem {
  final begin;
  final end;
  final weight;

  SequenceItem(this.begin, this.end, {this.weight = 1.0});
}
