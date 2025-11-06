import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/registration_data.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Implementación del repositorio de autenticación usando Firebase
class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  static Future<void>? _googleInitialization;
  static const String _googleServerClientId =
      '28475506464-fak9o969p6igi6mp1l8et45ru6usrm1p.apps.googleusercontent.com';

  AuthRepository({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  Future<void> _ensureGoogleInitialized() {
    final existing = _googleInitialization;
    if (existing != null) {
      return existing;
    }
    final initialization = GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialization = initialization;
    return initialization;
  }

  Future<GoogleSignInAccount?> _authenticateWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      return await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email'],
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'User',
        photoUrl: firebaseUser.photoURL,
        isEmailVerified: firebaseUser.emailVerified,
        providers: firebaseUser.providerData
            .map((info) => info.providerId)
            .toList(),
      );
    });
  }

  @override
  AppUser? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      providers: firebaseUser.providerData
          .map((info) => info.providerId)
          .toList(),
    );
  }

  @override
  Future<Either<AuthFailure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        return Left(AuthFailure.serverError());
      }

      final user = AppUser(
        id: credential.user!.uid,
        email: credential.user!.email ?? email,
        displayName: credential.user!.displayName ?? email.split('@')[0],
        photoUrl: credential.user!.photoURL,
        isEmailVerified: credential.user!.emailVerified,
        providers: credential.user!.providerData
            .map((info) => info.providerId)
            .toList(),
      );

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        return Left(AuthFailure.serverError());
      }

      // Enviar email de verificación
      await credential.user!.sendEmailVerification();

      final user = AppUser(
        id: credential.user!.uid,
        email: credential.user!.email ?? email,
        displayName: credential.user!.displayName ?? email.split('@')[0],
        photoUrl: credential.user!.photoURL,
        isEmailVerified: false,
        providers: credential.user!.providerData
            .map((info) => info.providerId)
            .toList(),
      );

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, AppUser>> registerWithCompleteData(
    RegistrationData data,
  ) async {
    try {
      // Validar datos antes de proceder
      if (!data.isValid) {
        return Left(AuthFailure.invalidData());
      }

      UserCredential? credential;
      
      // Autenticar según el método elegido
      switch (data.authMethod) {
        case AuthMethod.emailPassword:
          if (data.email == null || data.password == null) {
            return Left(AuthFailure.invalidData());
          }
          credential = await _auth.createUserWithEmailAndPassword(
            email: data.email!,
            password: data.password!,
          );
          
          // Enviar email de verificación
          if (credential.user != null) {
            await credential.user!.sendEmailVerification();
          }
          break;
          
        case AuthMethod.google:
          if (kIsWeb) {
            final googleProvider = GoogleAuthProvider()
              ..addScope('email')
              ..setCustomParameters({'prompt': 'select_account'});
            credential = await _auth.signInWithPopup(googleProvider);
          } else {
            final GoogleSignInAccount? googleUser = await _authenticateWithGoogle();
            if (googleUser == null) {
              return Left(AuthFailure.cancelledByUser());
            }
            final GoogleSignInAuthentication googleAuth = googleUser.authentication;
            final authCredential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
            );
            credential = await _auth.signInWithCredential(authCredential);
          }
          break;
          
        case AuthMethod.apple:
        case AuthMethod.facebook:
          return Left(AuthFailure.notImplemented());
      }

      if (credential.user == null) {
        return Left(AuthFailure.serverError());
      }

      final firebaseUser = credential.user!;
      
      // Crear AppUser para retornar
      final appUser = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? data.email ?? '',
        displayName: data.displayName,
        photoUrl: firebaseUser.photoURL,
        isEmailVerified: firebaseUser.emailVerified,
        providers: firebaseUser.providerData
            .map((info) => info.providerId)
            .toList(),
      );

      // Nota: El perfil completo se crea en FirebaseAuthService.registerWithCompleteData
      // que es llamado desde el provider/use case
      
      return Right(appUser);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      debugPrint('Error in registerWithCompleteData: $e');
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, AppUser>> signInWithGoogle() async {
    try {
      UserCredential? credential;
      
      if (kIsWeb) {
        // Web authentication
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _authenticateWithGoogle();

        if (googleUser == null) {
          return Left(AuthFailure.cancelledByUser());
        }

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final authCredential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(authCredential);
      }

      if (credential.user == null) {
        return Left(AuthFailure.serverError());
      }

      final user = AppUser(
        id: credential.user!.uid,
        email: credential.user!.email ?? '',
        displayName: credential.user!.displayName ?? 'User',
        photoUrl: credential.user!.photoURL,
        isEmailVerified: credential.user!.emailVerified,
        providers: credential.user!.providerData
            .map((info) => info.providerId)
            .toList(),
      );

      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        () async {
          try {
            await _ensureGoogleInitialized();
            await GoogleSignIn.instance.signOut();
          } catch (_) {
            // Ignore sign-out failures, user already signed out from Firebase.
          }
        }(),
      ]);
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> verifyEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(AuthFailure.noUserFound());
      }
      
      await user.sendEmailVerification();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(AuthFailure.noUserFound());
      }

      await user.updateProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );
      
      await user.reload();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(AuthFailure.noUserFound());
      }

      await user.delete();
      try {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Ignore sign-out failures during account deletion.
      }
      
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(AuthFailure.requiresRecentLogin());
      }
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> linkEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(AuthFailure.noUserFound());
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.linkWithCredential(credential);
      await user.reload();
      
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(_handleAuthException(e));
    } catch (e) {
      return Left(AuthFailure.serverError());
    }
  }

  AuthFailure _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthFailure.userNotFound();
      case 'wrong-password':
        return AuthFailure.wrongPassword();
      case 'invalid-email':
        return AuthFailure.invalidEmail();
      case 'email-already-in-use':
        return AuthFailure.emailAlreadyInUse();
      case 'weak-password':
        return AuthFailure.weakPassword();
      case 'operation-not-allowed':
        return AuthFailure.operationNotAllowed();
      case 'user-disabled':
        return AuthFailure.userDisabled();
      case 'too-many-requests':
        return AuthFailure.tooManyRequests();
      case 'requires-recent-login':
        return AuthFailure.requiresRecentLogin();
      case 'network-request-failed':
        return AuthFailure.networkError();
      case 'invalid-credential':
        return AuthFailure.invalidCredential();
      default:
        debugPrint('Unhandled auth error: ${e.code} - ${e.message}');
        return AuthFailure.serverError();
    }
  }
}

// Riverpod provider
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository();
});
