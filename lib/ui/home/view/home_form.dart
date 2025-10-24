import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triplecyber_challenge/utils/dialogs/show_loading.dart';
import 'package:triplecyber_challenge/utils/reusable_widgets/build_text.dart';

import '../../../bloc/call_bloc/call_bloc.dart';
import '../../call/call_page.dart';

part 'home_screen.dart';

class CreateCallButton extends StatelessWidget {
  const CreateCallButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc,CallState>(
      builder: (BuildContext context, CallState state) {
      final waiting = state is WaitingPeer ? state.roomId : null;
      return Row(
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.video_call_outlined),
          label: const Text('Create Call'),
          onPressed: () {
            context.read<CallBloc>().add(CreateCallRequested());
          },
        ),
        const SizedBox(width: 12),
        if (waiting != null) ...[
          const BuildText(text: 'Room ID:'),
          const SizedBox(width: 8),
          SelectableText(
            waiting,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8,),
          IconButton(onPressed: ()async{
            await Clipboard.setData(ClipboardData(text: waiting));
          }, icon: Icon(Icons.copy))
        ],
      ],
    );
    },);
  }
}

class RightAwayCallButton extends StatelessWidget {
  const RightAwayCallButton({super.key});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
      icon: const Icon(Icons.video_call_outlined),
      label: const BuildText(text: 'Create A Right Away Call'),
      onPressed:
          () => context.read<CallBloc>().add(
        RightAwayCallRequested(),
      ),
    );
}

