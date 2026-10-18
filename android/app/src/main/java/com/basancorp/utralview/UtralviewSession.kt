package com.basancorp.utralview

import android.graphics.Bitmap
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

sealed class SessionState {
    object Idle : SessionState()
    object Connecting : SessionState()
    object Connected : SessionState()
    data class Error(val message: String) : SessionState()
}

class UtralviewSession : ViewModel() {
    var state by mutableStateOf<SessionState>(SessionState.Idle)
        private set

    var partnerId by mutableStateOf("")
    var password by mutableStateOf("")
    var isControlEnabled by mutableStateOf(true)
    var isTouchpadMode by mutableStateOf(true)
    var remoteScreenBitmap by mutableStateOf<Bitmap?>(null)

    private var sessionHandle: Long = 0

    fun connect(id: String, pwd: String) {
        if (id.isBlank() || pwd.isBlank()) {
            state = SessionState.Error("Vui lòng nhập đầy đủ ID và Mật khẩu.")
            return
        }
        partnerId = id
        password = pwd
        state = SessionState.Connecting

        viewModelScope.launch(Dispatchers.IO) {
            try {
                // Initialize session via JNI or networking bridge
                sessionHandle = UtralviewJNI.nativeConnect(id, pwd)
                state = SessionState.Connected
            } catch (e: Exception) {
                state = SessionState.Error(e.message ?: "Kết nối thất bại. Vui lòng thử lại.")
            }
        }
    }

    fun disconnect() {
        if (sessionHandle != 0L) {
            UtralviewJNI.nativeDisconnect(sessionHandle)
            sessionHandle = 0
        }
        state = SessionState.Idle
        remoteScreenBitmap = null
    }

    fun sendMouseMove(x: Int, y: Int) {
        if (sessionHandle != 0L && isControlEnabled) {
            UtralviewJNI.nativeSendMouseMove(sessionHandle, x, y)
        }
    }

    fun sendMouseClick(button: Int, isDown: Boolean) {
        if (sessionHandle != 0L && isControlEnabled) {
            UtralviewJNI.nativeSendMouseClick(sessionHandle, button, isDown)
        }
    }

    fun sendKey(keyCode: Int, isDown: Boolean) {
        if (sessionHandle != 0L && isControlEnabled) {
            UtralviewJNI.nativeSendKey(sessionHandle, keyCode, isDown)
        }
    }
}
