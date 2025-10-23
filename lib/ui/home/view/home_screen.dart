part of 'home_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _joinCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BuildText(text: 'TriplerCyber Challenge'),
        centerTitle: true,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CallBloc, CallState>(
            listenWhen: (prev, curr) => prev is! InCall && curr is InCall,
            listener: (context, state) {
              final s = state as InCall;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => CallPage(
                        roomId: s.roomId,
                        local: s.local,
                        remote: s.remote,
                      ),
                ),
              );
            },
          ),
          // 2) Always handle loading / done / error
          BlocListener<CallBloc, CallState>(
            listener: (context, state) {
              if (state is LoadingCallLive) {
                showLoadingDialog(context);
              } else if (state is LoadingDoneCallLive) {
                Navigator.pop(context);
              } else if (state is CallError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: BuildText(text: state.message),
                  ),
                );
              } else if (state is CallDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: BuildText(
                      text: 'Room has been deleted successfully',
                    ),
                  ),
                );
              } else if (state is RemoteRoomDeleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: BuildText(
                      text: 'The Session Has Been Closed By The Owner.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BuildText(
                text: 'Create or Join a Room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const RightAwayCallButton(),
              const SizedBox(height: 16),
              const CreateCallButton(),
              const SizedBox(height: 24),
              TextField(
                controller: _joinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Enter Room ID',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const BuildText(text: 'Join'),
                onPressed: () {
                  final id = _joinCtrl.text.trim();
                  if (id.isNotEmpty) {
                    context.read<CallBloc>().add(JoinCallRequested(id));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
