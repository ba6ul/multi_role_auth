// Minimal example of wiring up `multi_role_auth`.
//
// It shows the three things a host app is responsible for:
//   1. Initializing Supabase.
//   2. Constructing the use cases -> repository -> data source chain and the
//      AuthBloc / AppUserCubit (done here by hand; a real app would use a DI
//      container such as get_it).
//   3. Owning the UI: this file provides its own login screen and reacts to
//      AuthState. The package intentionally ships no widgets.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_role_auth/multi_role_auth.dart';
// Hide Supabase's own AuthState so it doesn't clash with the package's.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://YOUR-PROJECT.supabase.co',
    publishableKey: 'YOUR-PUBLISHABLE-KEY',
  );

  runApp(MyApp(client: Supabase.instance.client));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.client});

  final SupabaseClient client;

  @override
  Widget build(BuildContext context) {
    // Build the dependency chain: data source -> repository -> use cases.
    final dataSource = AuthRemoteDataSourceImpl(client);
    final repository = AuthRepositoryImpl(dataSource);

    final appUserCubit = AppUserCubit();
    final authBloc = AuthBloc(
      userSignUp: UserSignUp(repository),
      userLogin: UserLogin(repository),
      signInWithGoogle: SignInWithGoogle(repository),
      currentUser: CurrentUser(repository),
      userSignOut: UserSignOut(repository),
      deleteAccount: DeleteAccount(repository),
      appUserCubit: appUserCubit,
      // Optional: clear any local app data on logout/deletion.
      onLogout: () async {
        /* clear caches, secure storage, etc. */
      },
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: appUserCubit),
        // Restore any existing session as soon as the bloc is created.
        BlocProvider.value(value: authBloc..add(AuthIsUserLoggedIn())),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }
}

/// A login screen owned entirely by the host app — the package has no UI.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthBloc>().add(
      AuthLogin(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('multi_role_auth example')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AuthSuccess) {
            final user = state.user;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Signed in as ${user.email}'),
                  Text('Role: ${user.role.displayName}'),
                  TextButton(
                    onPressed: () => context.read<AuthBloc>().add(AuthLogout()),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _login, child: const Text('Log in')),
              ],
            ),
          );
        },
      ),
    );
  }
}
