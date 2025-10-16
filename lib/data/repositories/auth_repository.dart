import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Implementación del repositorio de autenticación usando Firebase
class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  
  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

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
        // Mobile authentication
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          // El usuario canceló el login
          return Left(AuthFailure.cancelledByUser());
        }

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;

        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
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
        _googleSignIn.signOut(),
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
      await _googleSignIn.signOut();
      
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
