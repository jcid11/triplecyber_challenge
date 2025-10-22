import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:triplecyber_challenge/utils/reusable_widgets/build_text.dart';

import '../../../bloc/call_bloc/call_bloc.dart';

part 'call_screen.dart';

class SignalBars extends StatelessWidget {
  const SignalBars({super.key});

  int bars(ConnectionQuality quality) {
    return switch (quality) {
      ConnectionQuality.excellent => 4,
      ConnectionQuality.good => 3,
      ConnectionQuality.fair => 2,
      ConnectionQuality.poor => 1,
      ConnectionQuality.bad => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallState>(
      buildWhen: (p, c) => p is InCall,
      builder: (context, state) {
        final int barNumber = bars(
          state is InCall ? state.quality : ConnectionQuality.good,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: List.generate(4, (i) {
              final on = i < barNumber;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 6,
                  height: 8 + i * 6.0,
                  decoration: BoxDecoration(
                    color: on ? Colors.green : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class MicButton extends StatelessWidget {
  const MicButton({super.key});

  @override
  Widget build(BuildContext context) {
    return  BlocSelector<CallBloc, CallState, bool>(
      selector: (s) => s is InCall ? s.micEnabled : true,
      builder:
          (context, micOn) => FloatingActionButton(
        heroTag: 'center_button',
        shape: CircleBorder(),
        onPressed:
            () => context.read<CallBloc>().add(ToggleMicRequested()),
        child: Icon(micOn ? Icons.mic : Icons.mic_off),
      ),
    );
  }
}

