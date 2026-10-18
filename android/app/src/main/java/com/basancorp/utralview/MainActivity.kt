package com.basancorp.utralview

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.basancorp.utralview.ui.BgDark
import com.basancorp.utralview.ui.ConnectScreen
import com.basancorp.utralview.ui.RemoteScreenView
import com.basancorp.utralview.ui.UtralviewTheme

class MainActivity : ComponentActivity() {
    private val session: UtralviewSession by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            UtralviewTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = BgDark
                ) {
                    when (session.state) {
                        is SessionState.Connected -> {
                            RemoteScreenView(session = session)
                        }
                        else -> {
                            ConnectScreen(session = session)
                        }
                    }
                }
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        session.disconnect()
    }
}
