import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:triplecyber_challenge/ui/home/home_page.dart';

import 'bloc/call_bloc/call_bloc.dart';
import 'data/signaling_repository.dart';
import 'data/webrtc_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    final signaling = SignalingRepository();
    final webrtc = WebRtcRepository();


    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: signaling),
        RepositoryProvider.value(value: webrtc),
      ],
      child: BlocProvider(
        create: (_) => CallBloc(signaling: signaling, webrtc: webrtc),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TripleCyber challenge',
          theme: ThemeData(colorSchemeSeed: Colors.indigo),
          home: const HomePage(),
        ),
      ),
    );
  }
}
