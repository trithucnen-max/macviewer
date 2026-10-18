package com.basancorp.utralview.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val BgDark = Color(0xFF0D1117)
val SurfaceDark = Color(0xFF161B22)
val SurfaceBorder = Color(0xFF30363D)
val AccentCobalt = Color(0xFF2563EB)
val StatusEmerald = Color(0xFF10B981)
val TextPrimary = Color(0xFFF0F6FC)
val TextSecondary = Color(0xFF8B949E)

private val DarkColorScheme = darkColorScheme(
    primary = AccentCobalt,
    secondary = StatusEmerald,
    background = BgDark,
    surface = SurfaceDark,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = TextPrimary,
    onSurface = TextPrimary
)

@Composable
fun UtralviewTheme(
    darkTheme: Boolean = true,
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        content = content
    )
}
