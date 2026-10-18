package com.basancorp.utralview.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.basancorp.utralview.UtralviewSession

@Composable
fun RemoteScreenView(
    session: UtralviewSession,
    modifier: Modifier = Modifier
) {
    var cursorPosition by remember { mutableStateOf(Offset(200f, 200f)) }
    var isKeyboardOpen by remember { mutableStateOf(false) }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        // Top Toolbar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(SurfaceDark)
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(10.dp)
                        .background(StatusEmerald, shape = androidx.compose.foundation.shape.CircleShape)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "ID: ${session.partnerId}",
                    color = TextPrimary,
                    fontSize = 14.sp
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TextButton(onClick = { isKeyboardOpen = !isKeyboardOpen }) {
                    Text(if (isKeyboardOpen) "Ẩn phím" else "Bàn phím", color = AccentCobalt)
                }
                Button(
                    onClick = { session.disconnect() },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFEF4444)),
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                    modifier = Modifier.height(32.dp)
                ) {
                    Text("Ngắt kết nối", fontSize = 12.sp)
                }
            }
        }

        // Remote Canvas
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .pointerInput(Unit) {
                    detectTapGestures(
                        onTap = {
                            cursorPosition = it
                            session.sendMouseMove(it.x.toInt(), it.y.toInt())
                            session.sendMouseClick(button = 1, isDown = true)
                            session.sendMouseClick(button = 1, isDown = false)
                        },
                        onDoubleTap = {
                            cursorPosition = it
                            session.sendMouseMove(it.x.toInt(), it.y.toInt())
                            session.sendMouseClick(button = 1, isDown = true)
                            session.sendMouseClick(button = 1, isDown = false)
                            session.sendMouseClick(button = 1, isDown = true)
                            session.sendMouseClick(button = 1, isDown = false)
                        },
                        onLongPress = {
                            cursorPosition = it
                            session.sendMouseMove(it.x.toInt(), it.y.toInt())
                            session.sendMouseClick(button = 2, isDown = true)
                            session.sendMouseClick(button = 2, isDown = false)
                        }
                    )
                }
                .pointerInput(Unit) {
                    detectDragGestures { change, dragAmount ->
                        change.consume()
                        cursorPosition += dragAmount
                        session.sendMouseMove(cursorPosition.x.toInt(), cursorPosition.y.toInt())
                    }
                }
        ) {
            val bitmap = session.remoteScreenBitmap
            Canvas(modifier = Modifier.fillMaxSize()) {
                if (bitmap != null) {
                    drawImage(bitmap.asImageBitmap())
                }
                // Draw remote cursor indicator
                drawCircle(
                    color = Color.White,
                    radius = 8f,
                    center = cursorPosition
                )
                drawCircle(
                    color = Color(0xFF2563EB),
                    radius = 5f,
                    center = cursorPosition
                )
            }
        }

        // On-screen special keys toolbar
        if (isKeyboardOpen) {
            KeyboardToolbar(
                onKeyPress = { key ->
                    // Map special keys
                }
            )
        }
    }
}
