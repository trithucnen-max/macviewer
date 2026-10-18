package com.basancorp.utralview

object UtralviewJNI {
    init {
        try {
            System.loadLibrary("ultraviewer_ffi")
        } catch (e: UnsatisfiedLinkError) {
            // Fallback gracefully in testing / mock environments
        }
    }

    external fun nativeConnect(partnerId: String, password: String): Long
    external fun nativeDisconnect(handle: Long)
    external fun nativeSendMouseMove(handle: Long, x: Int, y: Int)
    external fun nativeSendMouseClick(handle: Long, button: Int, isDown: Boolean)
    external fun nativeSendKey(handle: Long, keyCode: Int, isDown: Boolean)
    external fun nativeSendText(handle: Long, text: String)
}
