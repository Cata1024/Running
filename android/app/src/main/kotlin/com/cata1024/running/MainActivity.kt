package com.cata1024.running

import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "play_integrity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestIntegrityToken" -> {
                        val nonce = call.argument<String>("nonce")
                        if (nonce.isNullOrBlank()) {
                            result.error("invalid_argument", "Nonce es requerido", null)
                        } else {
                            requestIntegrityToken(nonce, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestIntegrityToken(nonce: String, result: MethodChannel.Result) {
        val integrityManager = IntegrityManagerFactory.create(applicationContext)
        val request = IntegrityTokenRequest.builder()
            .setNonce(nonce)
            .build()

        integrityManager
            .requestIntegrityToken(request)
            .addOnSuccessListener { response ->
                val token = response.token()
                if (token.isNullOrEmpty()) {
                    result.error("empty_token", "Token de integridad vacío", null)
                } else {
                    result.success(token)
                }
            }
            .addOnFailureListener { error ->
                result.error(
                    "integrity_error",
                    error.message ?: "Error al solicitar token de Play Integrity",
                    null
                )
            }
    }
}