part of 'call_form.dart';

class CallScreen extends StatelessWidget {
  final String roomId;
  final RTCVideoRenderer local;
  final RTCVideoRenderer remote;

  const CallScreen({
    super.key,
    required this.roomId,
    required this.local,
    required this.remote,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (BuildContext context, CallState state) {
        if (state is CallEnded) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: MicButton(),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: RTCVideoView(
                  remote,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
            Positioned(top: 44, right: 76, child: SignalBars()),
            Positioned(
              right: 16,
              bottom: 16,
              width: 120,
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black),
                  child: RTCVideoView(
                    local,
                    mirror: true,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
            // BlocBuilder<CallBloc,CallState>(builder: (BuildContext context, CallState state) {
            //   return Positioned(
            //     top: 102,
            //     left: 16,
            //     child: Column(
            //       children: [
            //         if(state is InCall)
            //           Chip(label: BuildText(text: 'connection Quality :${state.quality}'))
            //       ],
            //     ),
            //   );
            // },),
            Positioned(
              top: 48,
              left: 16,
              child: Chip(label: Text('Room: $roomId')),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'top_button',
                backgroundColor: Colors.red.shade600,
                onPressed:
                    () => context.read<CallBloc>().add(HangUpRequested()),
                child: const Icon(Icons.call_end),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
