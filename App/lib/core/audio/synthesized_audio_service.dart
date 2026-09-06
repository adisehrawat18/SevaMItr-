import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Calibrated Offline Synthesized Audio Service
/// Generates frequency sweeps and psychoacoustic cues directly in memory
/// using pure Dart PCM WAV byte generation with zero network latency (0ms).
class SynthesizedAudioService {
  SynthesizedAudioService._();
  static final SynthesizedAudioService instance = SynthesizedAudioService._();

  AudioPlayer? _player;
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _player = AudioPlayer();
    _isInitialized = true;
  }

  void dispose() {
    _player?.dispose();
    _player = null;
    _isInitialized = false;
  }

  /// Generates a calibrated 16-bit mono 44.1kHz WAV byte buffer
  Uint8List _generateWavSweep({
    required double startFreq,
    required double endFreq,
    double durationSec = 0.16,
    int sampleRate = 44100,
  }) {
    final numSamples = (sampleRate * durationSec).round();
    final dataSize = numSamples * 2; // 16-bit = 2 bytes per sample
    final buffer = ByteData(44 + dataSize);

    // 1. RIFF Header
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // 2. fmt chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Chunk size
    buffer.setUint16(20, 1, Endian.little);  // PCM format
    buffer.setUint16(22, 1, Endian.little);  // Mono
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    buffer.setUint16(32, 2, Endian.little);  // Block align
    buffer.setUint16(34, 16, Endian.little); // Bits per sample

    // 3. data chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    // 4. Synthesize Samples with Anti-Click Smooth Envelope
    final attackSamples = (sampleRate * 0.02).round();
    final decaySamples = (sampleRate * 0.02).round();
    double currentPhase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final progress = i / numSamples;
      // Exponential frequency interpolation
      final currentFreq = startFreq * math.pow(endFreq / startFreq, progress);
      final phaseDelta = (2.0 * math.pi * currentFreq) / sampleRate;
      currentPhase += phaseDelta;

      // Amplitude Envelope (0.0 to 1.0)
      double envelope = 1.0;
      if (i < attackSamples) {
        envelope = i / attackSamples;
      } else if (i > numSamples - decaySamples) {
        envelope = (numSamples - i) / decaySamples;
      }

      final sampleValue = (math.sin(currentPhase) * 28000 * envelope).round().clamp(-32768, 32767);
      buffer.setInt16(44 + i * 2, sampleValue, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  /// Plays an individual upward (440Hz -> 880Hz) or downward (880Hz -> 440Hz) sweep
  Future<void> playSweep(bool isUp, {double durationSec = 0.16}) async {
    try {
      init();
      final wavBytes = _generateWavSweep(
        startFreq: isUp ? 440 : 880,
        endFreq: isUp ? 880 : 440,
        durationSec: durationSec,
      );
      await _player?.stop();
      await _player?.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('Sweep audio playback fallback: $e');
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Plays two sequential sweeps with calibrated Inter-Stimulus Interval (ISI) in milliseconds
  Future<void> playSequentialSweeps(bool firstIsUp, bool secondIsUp, int isiMs) async {
    await playSweep(firstIsUp, durationSec: 0.14);
    await Future.delayed(Duration(milliseconds: math.max(60, isiMs) + 140));
    await playSweep(secondIsUp, durationSec: 0.14);
  }

  /// Plays auditory feedback chime for success
  Future<void> playSuccessChime() async {
    HapticFeedback.mediumImpact();
    try {
      init();
      final wavBytes = _generateWavSweep(
        startFreq: 523.25, // C5
        endFreq: 783.99,   // G5
        durationSec: 0.18,
      );
      await _player?.stop();
      await _player?.play(BytesSource(wavBytes));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Plays auditory feedback for errors or warnings
  Future<void> playGentleError() async {
    HapticFeedback.heavyImpact();
    try {
      init();
      final wavBytes = _generateWavSweep(
        startFreq: 330.0,
        endFreq: 220.0,
        durationSec: 0.22,
      );
      await _player?.stop();
      await _player?.play(BytesSource(wavBytes));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Tactile and audio step tick for movement/actions
  void playStepTick() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }
}
